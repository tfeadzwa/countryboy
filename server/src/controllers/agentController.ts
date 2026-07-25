import { AuthenticatedRequest } from '../middleware/auth';
import { Request, Response } from 'express';
import * as agentService from '../services/agentService';
import { formatPrismaError } from '../utils/prismaErrors';
import { resolveDeviceForLogin, resolveDeviceFromToken } from '../utils/resolveDevice';
import { agentLoginLogger } from '../utils/logger';
import {
  endAgentDeviceSession,
  startAgentDeviceSession,
  listAgentSessions,
  recordAgentHeartbeat,
} from '../services/agentSessionService';
import { buildPaginatedResult, parsePagination, wantsPagination } from '../utils/pagination';


export const list = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const depotId = req.depotId;
    const query = req.query as { page?: string; limit?: string };

    if (wantsPagination(query)) {
      const { page, limit, skip } = parsePagination(query);
      const [agents, total] = await Promise.all([
        agentService.listAgents(depotId, { skip, limit }),
        agentService.countAgents(depotId),
      ]);
      return res.json(buildPaginatedResult(agents, total, page, limit));
    }

    const agents = await agentService.listAgents(depotId);
    res.json(agents);
  } catch (err) {
    res.status(500).json({ error: 'Unable to list agents', details: err });
  }
};

export const create = async (req: AuthenticatedRequest, res: Response) => {
  const depotId = req.depotId as string;
  const { full_name, username, agent_code, pin, status } = req.body;

  if (!depotId) {
    return res.status(400).json({
      error: 'Cannot register agent: depot context is missing for this user.'
    });
  }

  try {
    const agent = await agentService.createAgent(depotId, { 
      full_name, 
      username, 
      agent_code,
      pin,
      status
    }, req.user?.id);
    res.status(201).json(agent);
  } catch (err) {
    const friendly = formatPrismaError(err, { full_name, username, agent_code });
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(400).json({ error: 'Could not create agent', details: err });
  }
};

export const update = async (req: AuthenticatedRequest, res: Response) => {
  const depotId = req.depotId as string;
  const agentId = req.params.id;
  const data = req.body;

  try {
    const updated = await agentService.updateAgent(agentId, depotId, data, req.user?.id);
    res.json(updated);
  } catch (err) {
    const friendly = formatPrismaError(err, data as Record<string, any>);
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(400).json({ error: 'Could not update agent', details: err });
  }
};

export const remove = async (req: AuthenticatedRequest, res: Response) => {
  const depotId = req.depotId as string;
  const agentId = req.params.id;

  if (!depotId) {
    return res.status(400).json({
      error: 'Depot context required. Please specify depot via x-depot-id header or select a depot.',
    });
  }

  try {
    await agentService.deleteAgent(agentId, depotId);
    res.json({ message: 'Agent deleted successfully' });
  } catch (err) {
    if (err instanceof Error) {
      if (err.message === 'Agent not found in this depot') {
        return res.status(404).json({ error: err.message });
      }
      if (err.message.includes('Cannot delete')) {
        return res.status(409).json({ error: err.message });
      }
    }
    const friendly = formatPrismaError(err);
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(400).json({ error: 'Could not delete agent', details: err });
  }
};

/**
 * Reset agent PIN - generates and returns new PIN (one-time view)
 * Requires DEPOT_ADMIN or SUPER_ADMIN role
 */
export const resetPin = async (req: AuthenticatedRequest, res: Response) => {
  const depotId = req.depotId as string;
  const agentId = req.params.id;

  if (!depotId) {
    return res.status(400).json({
      error: 'Depot context required. Please specify depot via x-depot-id header or select a depot.'
    });
  }

  try {
    const agent = await agentService.resetAgentPin(agentId, depotId, req.user?.id);
    res.json(agent);
  } catch (err) {
    if (err instanceof Error && err.message === 'Agent not found in this depot') {
      return res.status(404).json({ error: err.message });
    }
    res.status(400).json({ error: 'Could not reset PIN', details: err });
  }
};

export const getOne = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const agentId = req.params.id;
    const agent = await agentService.getAgent(agentId);
    if (!agent) return res.status(404).json({ error: 'Agent not found' });
    res.json(agent);
  } catch (err) {
    res.status(500).json({ error: 'Error fetching agent', details: err });
  }
};

/**
 * Agent logout (mobile app)
 * JWT is stateless — actual token clearing happens on the device.
 * This endpoint exists so the mobile app gets a clean 200 instead of 404.
 */
export const logout = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const deviceToken = req.headers['x-device-token'] as string | undefined;
    if (req.agentId && deviceToken) {
      const device = await resolveDeviceFromToken(deviceToken);
      if (device && device.depot_id === req.depotId) {
        await endAgentDeviceSession({
          deviceId: device.id,
          agentId: req.agentId,
          endReason: 'logout',
        });
      }
    }
    res.json({ message: 'Logged out successfully' });
  } catch (err) {
    res.status(500).json({ error: 'Logout failed', details: err });
  }
};

/**
 * Presence heartbeat from the mobile app while a conductor is signed in online.
 * Refreshes device last_seen so admin can show Online vs Offline.
 */
export const heartbeat = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const deviceToken = req.headers['x-device-token'] as string | undefined;
    if (!req.agentId) {
      return res.status(401).json({ error: 'Agent authentication required' });
    }
    if (!deviceToken?.trim()) {
      return res.status(400).json({ error: 'Device token required' });
    }

    const device = await resolveDeviceFromToken(deviceToken);
    if (!device) {
      return res.status(401).json({
        error: 'Device is unpaired or token is invalid. Pair this device again.',
      });
    }
    if (req.depotId && device.depot_id !== req.depotId) {
      return res.status(403).json({ error: 'Device not allowed for this depot' });
    }

    const result = await recordAgentHeartbeat({
      deviceId: device.id,
      agentId: req.agentId,
      printerName: req.body?.printer_name,
      printerMac: req.body?.printer_mac,
      printerSerial: req.body?.printer_serial,
    });

    if (!result.ok) {
      return res.status(409).json({
        error: 'No active conductor session on this device',
        reason: result.reason,
      });
    }

    res.json({
      ok: true,
      last_seen: result.last_seen,
      session_id: result.session_id,
    });
  } catch (err) {
    res.status(500).json({ error: 'Heartbeat failed', details: err });
  }
};

/**
 * Agent login for mobile app
 * Requires: merchant_code + (username OR agent_code) + PIN
 */
export const login = async (req: Request, res: Response) => {
  try {
    const { merchant_code, username, agent_code, pin, app_version, device_id } =
      req.body;

    if (!merchant_code || !pin) {
      return res.status(400).json({ 
        error: 'merchant_code and pin are required' 
      });
    }

    if (!username && !agent_code) {
      return res.status(400).json({ 
        error: 'Either username or agent_code is required' 
      });
    }

    const deviceToken = req.headers['x-device-token'] as string | undefined;

    const result = await agentService.loginAgent({
      merchant_code,
      username,
      agent_code,
      pin
    });

    const device = await resolveDeviceForLogin({
      token: deviceToken,
      deviceId: device_id,
    });
    const agentDepotId = result.agent.depot_id as string | undefined;

    if (!device) {
      agentLoginLogger.warn('agent login session skipped', {
        reason: 'device_not_resolved',
        agentId: result.agent.id,
        agentCode: result.agent.agent_code,
        merchantCode: merchant_code,
        hasDeviceToken: Boolean(deviceToken?.trim()),
        hasDeviceId: Boolean(device_id?.trim()),
      });
      return res.json(result);
    }

    if (!agentDepotId || device.depot_id !== agentDepotId) {
      agentLoginLogger.warn('agent login session skipped', {
        reason: 'depot_mismatch',
        agentId: result.agent.id,
        agentCode: result.agent.agent_code,
        agentDepotId,
        deviceDepotId: device.depot_id,
        deviceId: device.id,
      });
      return res.json(result);
    }

    const session = await startAgentDeviceSession({
      deviceId: device.id,
      agentId: result.agent.id,
      depotId: agentDepotId,
      loginType: 'online',
      appVersion: app_version,
    });

    agentLoginLogger.info('agent login session started', {
      agentId: result.agent.id,
      agentCode: result.agent.agent_code,
      deviceId: device.id,
      sessionId: session.id,
      resolvedVia: deviceToken?.trim() ? 'token' : 'device_id',
    });

    return res.json({ ...result, session });
  } catch (err: any) {
    if (err.message === 'Invalid merchant code') {
      return res.status(404).json({ error: 'Invalid merchant code' });
    }
    if (err.message === 'Invalid agent credentials') {
      return res.status(404).json({ error: 'Agent not found' });
    }
    if (err.message === 'Invalid PIN') {
      return res.status(401).json({ error: 'Invalid PIN' });
    }
    res.status(500).json({ error: 'Login failed', details: err });
  }
};

/**
 * Start a new trip for the authenticated agent (Mobile App)
 * 
 * This endpoint allows conductors to start trips from their mobile devices.
 * The agent ID is extracted from the JWT token, ensuring agents can only
 * start trips for themselves.
 * 
 * @route POST /api/agents/trips/start
 * @access Private (Authenticated agents only)
 * @body {
 *   fleet_id: string,        // Bus/vehicle ID (required)
 *   origin: string,          // Conductor-entered origin (required)
 *   destination: string,     // Conductor-entered destination (required)
 *   route_id?: string,       // Legacy optional route catalog id
 *   device_id?: string,      // Device ID (optional, extracted from token if available)
 *   started_offline?: boolean // Whether trip started without internet (default: false)
 * }
 * @returns {
 *   trip: {
 *     id, origin, destination, status, agent, fleet, route?
 *   }
 * }
 */
export const startTrip = async (req: AuthenticatedRequest, res: Response) => {
  try {
    // Extract agent ID from JWT token (authenticated user)
    const agentId = req.agentId;
    
    if (!agentId) {
      return res.status(401).json({ 
        error: 'Agent authentication required. Please login with agent credentials.' 
      });
    }

    // Extract trip details from request body
    const { id, fleet_id, origin, destination, route_id, device_id, started_offline, driver_id } =
      req.body;

    // Validate required fields
    if (!fleet_id) {
      return res.status(400).json({ error: 'fleet_id is required' });
    }
    if (!origin || !String(origin).trim()) {
      return res.status(400).json({ error: 'origin is required' });
    }
    if (!destination || !String(destination).trim()) {
      return res.status(400).json({ error: 'destination is required' });
    }
    if (!driver_id) {
      return res.status(400).json({ error: 'driver_id is required' });
    }

    // Start the trip using agent service
    const trip = await agentService.startAgentTrip({
      id,
      agentId,
      fleetId: fleet_id,
      origin: String(origin),
      destination: String(destination),
      routeId: route_id,
      driverId: driver_id,
      deviceId: device_id,
      startedOffline: started_offline || false
    });

    res.status(201).json({
      message: 'Trip started successfully',
      trip: {
        ...trip,
        // Older mobile clients expect nested route origin/destination.
        route: trip.route ?? {
          id: null,
          origin: trip.origin,
          destination: trip.destination,
        },
      },
    });

  } catch (err: any) {
    // Handle specific error cases
    if (err.message === 'Agent has an active trip') {
      return res.status(409).json({ 
        error: 'You already have an active trip. Please end it before starting a new one.' 
      });
    }
    if (err.message === 'Agent not found' || err.message === 'Agent is not active') {
      return res.status(403).json({ error: err.message });
    }
    if (err.message === 'Fleet not found' || err.message === 'Route not found' || err.message === 'Driver not found') {
      return res.status(404).json({ error: err.message });
    }
    if (
      typeof err.message === 'string' &&
      (err.message.includes('does not belong') ||
        err.message === 'Driver is not active')
    ) {
      return res.status(400).json({ error: err.message });
    }
    if (
      typeof err.message === 'string' &&
      (err.message.includes('Origin') || err.message.includes('Destination'))
    ) {
      return res.status(400).json({ error: err.message });
    }
    
    res.status(500).json({ 
      error: 'Failed to start trip', 
      details: err.message 
    });
  }
};

/**
 * End the authenticated agent's active trip (Mobile App)
 * 
 * This endpoint allows conductors to end their current trip from mobile devices.
 * Only the agent who started the trip can end it. The system will:
 * - Set trip status to "COMPLETED"
 * - Calculate total tickets issued and revenue
 * - Record end timestamp
 * 
 * @route POST /api/agents/trips/:id/end
 * @access Private (Authenticated agents only - must own the trip)
 * @param id - Trip ID to end
 * @returns {
 *   id: string,
 *   ended_at: DateTime,
 *   status: "COMPLETED",
 *   total_tickets: number,
 *   total_revenue: number
 * }
 */
export const endTrip = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const agentId = req.agentId;
    const tripId = req.params.id;

    if (!agentId) {
      return res.status(401).json({ 
        error: 'Agent authentication required' 
      });
    }

    // Conductors start trips; cashiers end them from the admin console.
    return res.status(403).json({
      error:
        'Conductors cannot end trips. Ask the depot cashier to close this trip from the admin console.',
      trip_id: tripId,
    });

  } catch (err: any) {
    res.status(500).json({ 
      error: 'Failed to end trip', 
      details: err.message 
    });
  }
};

/**
 * Get the authenticated agent's currently active trip (Mobile App)
 * 
 * Returns the agent's current active trip, or null if no active trip.
 * This is used by the mobile app to:
 * - Check if agent can start a new trip
 * - Display current trip details
 * - Link tickets to the active trip
 * 
 * @route GET /api/agents/trips/active
 * @route GET /api/agents/trips/current (alias)
 * @access Private (Authenticated agents only)
 * @returns {
 *   trip: {
 *     id: string,
 *     started_at: DateTime,
 *     status: "ACTIVE",
 *     agent: {...},
 *     fleet: {...},
 *     route: {...},
 *     tickets_count: number,   // Number of tickets issued so far
 *     total_revenue: number    // Total revenue so far
 *   } | null
 * }
 */
export const getActiveTrip = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const agentId = req.agentId;

    if (!agentId) {
      return res.status(401).json({ 
        error: 'Agent authentication required' 
      });
    }

    // Get agent's active trip (returns null if no active trip)
    const activeTrip = await agentService.getAgentActiveTrip(agentId);

    res.json({
      trip: activeTrip
    });

  } catch (err: any) {
    res.status(500).json({ 
      error: 'Failed to get active trip', 
      details: err.message 
    });
  }
};

/**
 * Create a new fleet vehicle (Mobile App)
 * 
 * Allows agents to add new fleet vehicles on-the-fly when they're not
 * yet in the system. The vehicle will be scoped to the agent's depot.
 * 
 * @route POST /api/agents/fleets
 * @access Private (Authenticated agents only)
 * @body {
 *   number: string  // Fleet/vehicle registration number
 * }
 * @returns Fleet object with id, number, depot details
 */
export const createFleet = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const depotId = req.depotId;
    const { number } = req.body;

    if (!depotId) {
      return res.status(400).json({ 
        error: 'Depot context missing' 
      });
    }

    if (!number) {
      return res.status(400).json({ 
        error: 'Fleet number is required' 
      });
    }

    // Import fleet service dynamically to avoid circular dependencies
    const fleetService = await import('../services/fleetService');
    const fleet = await fleetService.createFleet(depotId, { number });

    res.status(201).json(fleet);
  } catch (err: any) {
    const friendly = formatPrismaError(err, { number: req.body.number });
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(400).json({ 
      error: 'Failed to create fleet vehicle', 
      details: err.message 
    });
  }
};

/**
 * Create a new route (Mobile App)
 * 
 * Allows agents to add new routes on-the-fly when they're not yet in
 * the system. The route will be scoped to the agent's depot.
 * 
 * @route POST /api/agents/routes
 * @access Private (Authenticated agents only)
 * @body {
 *   origin: string,       // Starting location
 *   destination: string   // Ending location
 * }
 * @returns Route object with id, origin, destination, depot details
 */
export const createRoute = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const depotId = req.depotId;
    const { origin, destination } = req.body;

    if (!depotId) {
      return res.status(400).json({ 
        error: 'Depot context missing' 
      });
    }

    if (!origin || !destination) {
      return res.status(400).json({ 
        error: 'Origin and destination are required' 
      });
    }

    // Import route service dynamically to avoid circular dependencies
    const routeService = await import('../services/routeService');
    const route = await routeService.createRoute(depotId, { origin, destination });

    res.status(201).json(route);
  } catch (err: any) {
    const friendly = formatPrismaError(err, { origin: req.body.origin, destination: req.body.destination });
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(400).json({ 
      error: 'Failed to create route', 
      details: err.message 
    });
  }
};

export const getSessions = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const agentId = req.params.id;
    const limit = Math.min(Number(req.query.limit) || 20, 100);
    const agent = await agentService.getAgent(agentId);
    if (!agent) {
      return res.status(404).json({ error: 'Agent not found' });
    }
    if (req.depotId && agent.depot_id !== req.depotId) {
      return res.status(403).json({ error: 'Agent not in your depot' });
    }
    const sessions = await listAgentSessions(agentId, limit);
    res.json({ agent_id: agentId, sessions });
  } catch (err) {
    res.status(500).json({ error: 'Unable to list agent sessions', details: err });
  }
};

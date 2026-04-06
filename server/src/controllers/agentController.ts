import { AuthenticatedRequest } from '../middleware/auth';
import { Request, Response } from 'express';
import * as agentService from '../services/agentService';
import { formatPrismaError } from '../utils/prismaErrors';


export const list = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const depotId = req.depotId;
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
 * Agent login for mobile app
 * Requires: merchant_code + (username OR agent_code) + PIN
 */
export const login = async (req: Request, res: Response) => {
  try {
    const { merchant_code, username, agent_code, pin } = req.body;

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

    const result = await agentService.loginAgent({
      merchant_code,
      username,
      agent_code,
      pin
    });

    res.json(result);
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
 *   route_id: string,        // Route ID (required)
 *   device_id?: string,      // Device ID (optional, extracted from token if available)
 *   started_offline?: boolean // Whether trip started without internet (default: false)
 * }
 * @returns {
 *   id: string,              // Trip ID
 *   started_at: DateTime,    // When trip started
 *   status: "ACTIVE",
 *   agent: {...},            // Agent details
 *   fleet: {...},            // Vehicle details
 *   route: {...}             // Route details
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
    const { fleet_id, route_id, device_id, started_offline } = req.body;

    // Validate required fields
    if (!fleet_id) {
      return res.status(400).json({ error: 'fleet_id is required' });
    }
    if (!route_id) {
      return res.status(400).json({ error: 'route_id is required' });
    }

    // Start the trip using agent service
    const trip = await agentService.startAgentTrip({
      agentId,
      fleetId: fleet_id,
      routeId: route_id,
      deviceId: device_id,
      startedOffline: started_offline || false
    });

    res.status(201).json({
      message: 'Trip started successfully',
      trip
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
    if (err.message === 'Fleet not found' || err.message === 'Route not found') {
      return res.status(404).json({ error: err.message });
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

    // End the trip (service will verify agent owns this trip)
    const result = await agentService.endAgentTrip(agentId, tripId);

    res.json({
      message: 'Trip ended successfully',
      trip: result
    });

  } catch (err: any) {
    if (err.message === 'Trip not found') {
      return res.status(404).json({ error: 'Trip not found' });
    }
    if (err.message === 'Trip does not belong to this agent') {
      return res.status(403).json({ 
        error: 'You can only end your own trips' 
      });
    }
    if (err.message === 'Trip is already completed') {
      return res.status(400).json({ error: 'Trip is already completed' });
    }

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

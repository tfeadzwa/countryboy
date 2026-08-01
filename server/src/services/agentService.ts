import prisma from '../utils/prisma';
import { Prisma } from '@prisma/client';
import bcrypt from '../lib/bcrypt';
import jwt from 'jsonwebtoken';
import { touchDeviceActivity } from './agentSessionService';
import { ensureRoute } from './routeService';
import { isDeviceOnline } from '../constants/presence';
import {
  parseRequiredMileage,
  parseRequiredWaybillNo,
} from '../utils/tripMileage';

export const listAgents = async (
  depotId?: string,
  pagination?: { skip: number; limit: number }
) => {
  const where: Prisma.tblAgentsWhereInput = {};
  if (depotId) where.depot_id = depotId;

  // Load full depot set first so presence/trip ranking can be applied before pagination.
  const agents = await prisma.tblAgents.findMany({
    where,
    include: {
      depot: {
        select: {
          merchant_code: true,
          name: true,
        },
      },
    },
    orderBy: [{ full_name: 'asc' }],
  });

  if (agents.length === 0) return [];

  const agentIds = agents.map((a) => a.id);

  const [openSessions, activeTrips] = await Promise.all([
    prisma.tblAgentDeviceSessions.findMany({
      where: { agent_id: { in: agentIds }, ended_at: null },
      orderBy: { started_at: 'desc' },
      include: {
        device: {
          select: {
            id: true,
            serial_number: true,
            last_seen: true,
            paired: true,
          },
        },
      },
    }),
    prisma.tblTrips.findMany({
      where: { agent_id: { in: agentIds }, status: 'ACTIVE' },
      include: {
        fleet: { select: { id: true, number: true, registration_number: true } },
        driver: { select: { id: true, full_name: true } },
        route: { select: { id: true, origin: true, destination: true } },
      },
    }),
  ]);

  const sessionByAgent = new Map<string, (typeof openSessions)[number]>();
  for (const session of openSessions) {
    if (!sessionByAgent.has(session.agent_id)) {
      sessionByAgent.set(session.agent_id, session);
    }
  }

  const tripByAgent = new Map<string, (typeof activeTrips)[number]>();
  for (const trip of activeTrips) {
    tripByAgent.set(trip.agent_id, trip);
  }

  const enriched = agents.map((agent) => {
    const session = sessionByAgent.get(agent.id);
    const trip = tripByAgent.get(agent.id);
    const online = isDeviceOnline({
      paired: Boolean(session?.device?.paired),
      lastSeen: session?.device?.last_seen ?? null,
      hasOpenSession: Boolean(session),
    });

    return {
      ...agent,
      merchant_code: agent.depot.merchant_code,
      depot_name: agent.depot.name,
      is_online: online,
      conductor_status: session ? (online ? 'online' : 'offline') : null,
      last_seen: session?.device?.last_seen
        ? session.device.last_seen.toISOString()
        : null,
      active_session: session
        ? {
            id: session.id,
            device_id: session.device_id,
            device_serial: session.device?.serial_number ?? null,
            started_at: session.started_at.toISOString(),
            login_type: session.login_type,
          }
        : null,
      active_trip: trip
        ? {
            id: trip.id,
            origin: trip.origin,
            destination: trip.destination,
            fleet_id: trip.fleet_id,
            fleet_number: trip.fleet?.number ?? null,
            driver_id: trip.driver_id,
            driver_name: trip.driver?.full_name ?? null,
            route_id: trip.route_id,
            route_origin: trip.route?.origin ?? null,
            route_destination: trip.route?.destination ?? null,
            started_at: trip.started_at.toISOString(),
            started_offline: trip.started_offline,
          }
        : null,
    };
  });

  enriched.sort((a, b) => {
    const rank = (agent: (typeof enriched)[number]) => {
      const onTrip = Boolean(agent.active_trip);
      const online = agent.conductor_status === 'online' || agent.is_online;
      const offline = agent.conductor_status === 'offline' || Boolean(agent.active_session);
      if (onTrip && online) return 0;
      if (onTrip) return 1;
      if (online) return 2;
      if (offline) return 3;
      return 4;
    };

    const rankDiff = rank(a) - rank(b);
    if (rankDiff !== 0) return rankDiff;

    const aTrip = a.active_trip?.started_at ? Date.parse(a.active_trip.started_at) : 0;
    const bTrip = b.active_trip?.started_at ? Date.parse(b.active_trip.started_at) : 0;
    if (aTrip !== bTrip) return bTrip - aTrip;

    const aSeen = a.last_seen ? Date.parse(a.last_seen) : 0;
    const bSeen = b.last_seen ? Date.parse(b.last_seen) : 0;
    if (aSeen !== bSeen) return bSeen - aSeen;

    return a.full_name.localeCompare(b.full_name);
  });

  if (pagination) {
    return enriched.slice(pagination.skip, pagination.skip + pagination.limit);
  }

  return enriched;
};

export const countAgents = async (depotId?: string): Promise<number> => {
  const where: Prisma.tblAgentsWhereInput = {};
  if (depotId) where.depot_id = depotId;
  return prisma.tblAgents.count({ where });
};

export const deleteAgent = async (agentId: string, depotId: string): Promise<void> => {
  const agent = await prisma.tblAgents.findFirst({
    where: { id: agentId, depot_id: depotId },
  });

  if (!agent) {
    throw new Error('Agent not found in this depot');
  }

  const [tripCount, ticketCount] = await Promise.all([
    prisma.tblTrips.count({ where: { agent_id: agentId } }),
    prisma.tblTickets.count({ where: { agent_id: agentId } }),
  ]);

  if (tripCount > 0 || ticketCount > 0) {
    throw new Error(
      'Cannot delete an agent with trip or ticket history. Set status to Terminated instead.'
    );
  }

  await prisma.$transaction([
    prisma.tblDevices.updateMany({
      where: { last_agent_id: agentId },
      data: { last_agent_id: null },
    }),
    prisma.tblAgentDeviceSessions.deleteMany({ where: { agent_id: agentId } }),
    prisma.tblAgents.delete({ where: { id: agentId } }),
  ]);
};

export const createAgent = async (depotId: string, data: { 
  full_name: string; 
  username?: string; 
  agent_code?: string; // Made optional
  pin?: string;
  status?: string;
}, createdBy?: string) => {
  // Auto-generate credentials if not provided
  let agentCode = data.agent_code;
  let username = data.username;
  let pin = data.pin;

  // Generate agent_code if not provided
  if (!agentCode) {
    const result = await prisma.$queryRaw<Array<{ generate_agent_code: string }>>`
      SELECT generate_agent_code(${data.full_name}, ${depotId}) as generate_agent_code
    `;
    agentCode = result[0].generate_agent_code;
  }

  // Generate username if not provided
  if (!username) {
    const result = await prisma.$queryRaw<Array<{ generate_username: string }>>`
      SELECT generate_username(${data.full_name}, ${depotId}) as generate_username
    `;
    username = result[0].generate_username;
  }

  // Generate PIN if not provided
  if (!pin) {
    const result = await prisma.$queryRaw<Array<{ generate_pin: string }>>`
      SELECT generate_pin(${depotId}) as generate_pin
    `;
    pin = result[0].generate_pin;
  }

  // Hash the PIN before storing
  const hashedPin = await bcrypt.hash(pin, 10);

  // Get depot merchant_code for response
  const depot = await prisma.tblDepots.findUnique({
    where: { id: depotId },
    select: { merchant_code: true, name: true }
  });

  // Create agent with generated/provided credentials
  const agent = await prisma.tblAgents.create({
    data: { 
      full_name: data.full_name,
      username,
      agent_code: agentCode,
      pin: hashedPin, // Store hashed PIN
      depot_id: depotId,
      status: data.status || 'ACTIVE',
      created_by: createdBy
    }
  });

  // Return agent with un-hashed PIN for admin to share (only on creation)
  return {
    ...agent,
    pin, // Return plain-text PIN for display to admin
    merchant_code: depot?.merchant_code,
    depot_name: depot?.name
  };
};

export const updateAgent = async (agentId: string, depotId: string, data: Partial<{ full_name: string; status: string; agent_code: string; depot_id: string; }>, updatedBy?: string) => {
  // Get current agent data
  const existingAgent = await prisma.tblAgents.findUnique({
    where: { id: agentId },
    include: {
      depot: {
        select: {
          merchant_code: true,
          name: true
        }
      }
    }
  });

  if (!existingAgent) {
    throw new Error('Agent not found');
  }

  // Check if agent has username, generate if missing
  let username = existingAgent.username;
  if (!username && data.full_name) {
    // Generate username based on new full_name or existing one
    const nameForUsername = data.full_name || existingAgent.full_name;
    const targetDepotId = data.depot_id || existingAgent.depot_id;
    const result = await prisma.$queryRaw<Array<{ generate_username: string }>>`
      SELECT generate_username(${nameForUsername}, ${targetDepotId}) as generate_username
    `;
    username = result[0].generate_username;
  }

  // Prepare update data
  const updateData: any = {
    ...data,
    updated_by: updatedBy
  };

  // Add username if it was generated
  if (username && !existingAgent.username) {
    updateData.username = username;
  }

  // Update agent
  const updatedAgent = await prisma.tblAgents.update({
    where: { id: agentId },
    data: updateData
  });

  // Get depot info (either new depot or existing)
  const targetDepotId = data.depot_id || existingAgent.depot_id;
  const depot = await prisma.tblDepots.findUnique({
    where: { id: targetDepotId },
    select: { merchant_code: true, name: true }
  });

  // Return agent with depot info (like creation flow)
  return {
    ...updatedAgent,
    username: username || updatedAgent.username,
    merchant_code: depot?.merchant_code,
    depot_name: depot?.name
  };
};

/**
 * Reset agent PIN - generates new PIN and returns it in plain text (only once)
 * @param agentId - Agent ID
 * @param depotId - Depot ID for context
 * @param updatedBy - User ID who is resetting the PIN
 * @returns Agent info with new plain-text PIN
 */
export const resetAgentPin = async (agentId: string, depotId: string, updatedBy?: string) => {
  // Get agent to verify it exists and belongs to the depot
  const agent = await prisma.tblAgents.findFirst({
    where: { 
      id: agentId,
      depot_id: depotId
    },
    include: {
      depot: {
        select: {
          merchant_code: true,
          name: true,
        }
      }
    }
  });

  if (!agent) {
    throw new Error('Agent not found in this depot');
  }

  // Generate new PIN using PostgreSQL function
  const result = await prisma.$queryRaw<Array<{ generate_pin: string }>>`
    SELECT generate_pin(${depotId}) as generate_pin
  `;
  const newPin = result[0].generate_pin;

  // Hash the new PIN
  const hashedPin = await bcrypt.hash(newPin, 10);

  // Update agent with new hashed PIN
  const updatedAgent = await prisma.tblAgents.update({
    where: { id: agentId },
    data: { pin: hashedPin, updated_by: updatedBy }
  });

  // Return agent with plain-text PIN for admin to share (only this once)
  return {
    ...updatedAgent,
    pin: newPin, // Return plain-text PIN
    merchant_code: agent.depot.merchant_code,
    depot_name: agent.depot.name
  };
};

export const getAgent = async (agentId: string, depotId?: string) => {
  const where: Prisma.tblAgentsWhereUniqueInput = { id: agentId };
  return prisma.tblAgents.findUnique({ where });
};

/**
 * Agent login for mobile app
 * Validates merchant_code (depot) + agent credentials (username or agent_code + PIN)
 * @returns agent info + auth token
 */
export const loginAgent = async (data: {
  merchant_code: string;
  username?: string;
  agent_code?: string;
  pin: string;
}) => {
  const { merchant_code, username, agent_code, pin } = data;

  // Validate merchant code (depot) — mobile sends uppercase, normalize for lookup
  const normalizedMerchantCode = merchant_code.trim().toUpperCase();
  const depot = await prisma.tblDepots.findUnique({
    where: { merchant_code: normalizedMerchantCode },
  });

  if (!depot) {
    throw new Error('Invalid merchant code');
  }

  // Find agent by username OR agent_code
  const where: Prisma.tblAgentsWhereInput = {
    depot_id: depot.id,
    status: 'ACTIVE',
    OR: [
      username ? { username } : {},
      agent_code ? { agent_code } : {}
    ].filter(obj => Object.keys(obj).length > 0)
  };

  const agent = await prisma.tblAgents.findFirst({ where });

  if (!agent) {
    throw new Error('Invalid agent credentials');
  }

  // Validate PIN using bcrypt
  const isValidPin = await bcrypt.compare(pin, agent.pin || '');
  if (!isValidPin) {
    throw new Error('Invalid PIN');
  }

  // Generate JWT tokens
  const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';
  const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'your-refresh-secret';

  // Access token (expires in 1 hour)
  const accessToken = jwt.sign(
    {
      agentId: agent.id,
      depotId: depot.id,
      role: 'AGENT',
      type: 'access'
    },
    JWT_SECRET,
    { expiresIn: '1h' }
  );

  // Refresh token (expires in 7 days)
  const refreshToken = jwt.sign(
    {
      agentId: agent.id,
      type: 'refresh'
    },
    JWT_REFRESH_SECRET,
    { expiresIn: '7d' }
  );

  // Parse full name into first and last name
  const nameParts = agent.full_name.split(' ');
  const firstName = nameParts[0] || '';
  const lastName = nameParts.slice(1).join(' ') || '';

  return {
    access_token: accessToken,
    refresh_token: refreshToken,
    agent: {
      id: agent.id,
      agent_code: agent.agent_code,
      first_name: firstName,
      last_name: lastName,
      role: 'AGENT',
      depot_id: depot.id,
      merchant_code: depot.merchant_code,
      merchant_name: depot.name,
      depot_code: depot.merchant_code,
      depot_name: depot.name
    },
    message: 'Login successful'
  };
};

/**
 * Start a new trip for an agent (Mobile App)
 * 
 * Business Logic:
 * 1. Verify agent exists and is active
 * 2. Check agent doesn't have an existing active trip (only one trip at a time)
 * 3. Validate fleet (bus) exists and belongs to same depot
 * 4. Validate route exists and belongs to same depot
 * 5. Create trip record with ACTIVE status
 * 
 * This ensures:
 * - Conductor can only have one active trip at a time (prevents confusion)
 * - All entities (agent, fleet, route) belong to same depot (data integrity)
 * - Proper audit trail with timestamps and relationships
 * 
 * @param data - Trip start details
 * @returns Created trip with related data (agent, fleet, route)
 */
export const startAgentTrip = async (data: {
  id?: string;
  agentId: string;
  fleetId: string;
  origin: string;
  destination: string;
  routeId?: string | null;
  driverId?: string | null;
  deviceId?: string;
  startedOffline?: boolean;
  startingMileage: number;
  waybillNo: string;
}) => {
  const {
    id,
    agentId,
    fleetId,
    origin,
    destination,
    deviceId,
    startedOffline,
    driverId,
    startingMileage: rawStartingMileage,
    waybillNo: rawWaybillNo,
  } = data;

  const trimmedOrigin = origin.trim();
  const trimmedDestination = destination.trim();
  if (trimmedOrigin.length < 2) {
    throw new Error('Origin must be at least 2 characters');
  }
  if (trimmedDestination.length < 2) {
    throw new Error('Destination must be at least 2 characters');
  }
  if (trimmedOrigin.toLowerCase() === trimmedDestination.toLowerCase()) {
    throw new Error('Origin and destination must be different');
  }

  const startingMileage = parseRequiredMileage(
    rawStartingMileage,
    'Starting mileage',
  );
  const waybillNo = parseRequiredWaybillNo(rawWaybillNo);

  // Step 1: Verify agent exists and is active
  const agent = await prisma.tblAgents.findUnique({
    where: { id: agentId },
    include: { depot: true }
  });

  if (!agent) {
    throw new Error('Agent not found');
  }

  if (agent.status !== 'ACTIVE') {
    throw new Error('Agent is not active');
  }

  const depotId = agent.depot_id;

  // Step 2: Check if agent already has an active trip
  // An agent can only have ONE active trip at a time
  const existingActiveTrip = await prisma.tblTrips.findFirst({
    where: {
      agent_id: agentId,
      status: 'ACTIVE'
    }
  });

  if (existingActiveTrip) {
    // Idempotent retry when the client resubmits the same trip id.
    if (id && existingActiveTrip.id === id) {
      return prisma.tblTrips.findUniqueOrThrow({
        where: { id },
        include: {
          agent: {
            select: { id: true, full_name: true, agent_code: true },
          },
          fleet: { select: { id: true, number: true, registration_number: true } },
          driver: { select: { id: true, full_name: true } },
          route: { select: { id: true, origin: true, destination: true } },
        },
      });
    }
    throw new Error('Agent has an active trip');
  }

  // Step 3: Validate fleet exists, belongs to depot, and is not already on a trip
  const fleet = await prisma.tblFleets.findUnique({
    where: { id: fleetId }
  });

  if (!fleet) {
    throw new Error('Fleet not found');
  }

  if (fleet.depot_id !== depotId) {
    throw new Error('Fleet does not belong to agent\'s depot');
  }

  const fleetActiveTrip = await prisma.tblTrips.findFirst({
    where: { fleet_id: fleetId, status: 'ACTIVE' },
    select: { id: true },
  });
  if (fleetActiveTrip) {
    throw new Error('Fleet is already on an active trip');
  }
  // Heal sticky on_trip left behind by older cashier end paths.
  if (fleet.on_trip) {
    await prisma.tblFleets.update({
      where: { id: fleetId },
      data: { on_trip: false },
    });
  }

  // Step 3b: Validate driver belongs to same depot when provided
  let resolvedDriverId: string | null = null;
  if (driverId) {
    const driver = await prisma.tblDrivers.findUnique({
      where: { id: driverId },
    });
    if (!driver) {
      throw new Error('Driver not found');
    }
    if (driver.depot_id !== depotId) {
      throw new Error('Driver does not belong to agent\'s depot');
    }
    if (driver.status !== 'ACTIVE') {
      throw new Error('Driver is not active');
    }
    const driverActiveTrip = await prisma.tblTrips.findFirst({
      where: { driver_id: driverId, status: 'ACTIVE' },
      select: { id: true },
    });
    if (driverActiveTrip) {
      throw new Error('Driver is already on an active trip');
    }
    if (driver.on_trip) {
      await prisma.tblDrivers.update({
        where: { id: driverId },
        data: { on_trip: false },
      });
    }
    resolvedDriverId = driver.id;
  }

  // Step 4: Upsert main parent corridor from conductor-entered origin/destination
  const parentRoute = await ensureRoute(depotId, trimmedOrigin, trimmedDestination);
  const resolvedRouteId = parentRoute.id;

  // Step 5: Create the trip and mark fleet/driver as on trip
  const trip = await prisma.$transaction(async (tx) => {
    const created = await tx.tblTrips.create({
      data: {
        ...(id ? { id } : {}),
        depot_id: depotId,
        agent_id: agentId,
        fleet_id: fleetId,
        driver_id: resolvedDriverId,
        route_id: resolvedRouteId,
        origin: trimmedOrigin,
        destination: trimmedDestination,
        device_id: deviceId,
        started_at: new Date(),
        status: 'ACTIVE',
        started_offline: startedOffline || false,
        starting_mileage: startingMileage,
        waybill_no: waybillNo,
      },
      include: {
        agent: {
          select: {
            id: true,
            full_name: true,
            agent_code: true
          }
        },
        fleet: {
          select: {
            id: true,
            number: true
          }
        },
        driver: {
          select: {
            id: true,
            full_name: true,
          }
        },
        route: {
          select: {
            id: true,
            origin: true,
            destination: true
          }
        }
      }
    });

    await tx.tblFleets.update({
      where: { id: fleetId },
      data: { on_trip: true },
    });
    if (resolvedDriverId) {
      await tx.tblDrivers.update({
        where: { id: resolvedDriverId },
        data: { on_trip: true },
      });
    }

    return created;
  });

  if (deviceId) {
    await touchDeviceActivity(deviceId, agentId);
  }

  return trip;
};

/**
 * End an agent's trip (Mobile App)
 * 
 * Business Logic:
 * 1. Verify trip exists
 * 2. Verify trip belongs to the requesting agent (security)
 * 3. Verify trip is still active (not already ended)
 * 4. Calculate trip totals (tickets count and revenue)
 * 5. Update trip status to COMPLETED and set ended_at timestamp
 * 
 * This ensures:
 * - Only the agent who started the trip can end it (security)
 * - Trip can only be ended once (data integrity)
 * - Proper financial tracking with totals
 * 
 * @param agentId - ID of agent requesting to end trip
 * @param tripId - ID of trip to end
 * @returns Updated trip with totals
 */
export const endAgentTrip = async (agentId: string, tripId: string) => {
  // Step 1: Get the trip
  const trip = await prisma.tblTrips.findUnique({
    where: { id: tripId },
    include: {
      tickets: true  // Include tickets to calculate totals
    }
  });

  if (!trip) {
    throw new Error('Trip not found');
  }

  // Step 2: Verify trip belongs to this agent
  // Security check: agents can only end their own trips
  if (trip.agent_id !== agentId) {
    throw new Error('Trip does not belong to this agent');
  }

  // Step 3: Verify trip is still active
  if (trip.status !== 'ACTIVE') {
    throw new Error('Trip is already completed');
  }

  // Step 4: Calculate trip totals
  const totalTickets = trip.tickets.length;
  const totalRevenue = trip.tickets.reduce(
    (sum, ticket) => sum + Number(ticket.amount),
    0
  );

  // Step 5: Update trip to completed and free fleet/driver
  const updatedTrip = await prisma.$transaction(async (tx) => {
    const ended = await tx.tblTrips.update({
      where: { id: tripId },
      data: {
        status: 'COMPLETED',
        ended_at: new Date()
      },
      include: {
        agent: {
          select: {
            id: true,
            full_name: true,
            agent_code: true
          }
        },
        fleet: {
          select: {
            id: true,
            number: true
          }
        },
        route: {
          select: {
            id: true,
            origin: true,
            destination: true
          }
        }
      }
    });

    await tx.tblFleets.update({
      where: { id: trip.fleet_id },
      data: { on_trip: false },
    });
    if (trip.driver_id) {
      await tx.tblDrivers.update({
        where: { id: trip.driver_id },
        data: { on_trip: false },
      });
    }

    return ended;
  });

  return {
    ...updatedTrip,
    total_tickets: totalTickets,
    total_revenue: totalRevenue
  };
};

/**
 * Get agent's currently active trip (Mobile App)
 * 
 * Business Logic:
 * 1. Find agent's trip with status = 'ACTIVE'
 * 2. Include related data (fleet, route, tickets)
 * 3. Calculate current totals (tickets and revenue so far)
 * 
 * Returns null if agent has no active trip.
 * 
 * Used by mobile app to:
 * - Check if agent needs to start a trip before issuing tickets
 * - Display current trip details on dashboard
 * - Link new tickets to the active trip
 * 
 * @param agentId - ID of agent
 * @returns Active trip with totals, or null
 */
export const getAgentActiveTrip = async (agentId: string) => {
  // Find agent's active trip
  const activeTrip = await prisma.tblTrips.findFirst({
    where: {
      agent_id: agentId,
      status: 'ACTIVE'
    },
    include: {
      agent: {
        select: {
          id: true,
          full_name: true,
          agent_code: true
        }
      },
      fleet: {
        select: {
          id: true,
          number: true
        }
      },
      driver: {
        select: {
          id: true,
          full_name: true,
        }
      },
      route: {
        select: {
          id: true,
          origin: true,
          destination: true
        }
      },
      tickets: {
        select: {
          id: true,
          amount: true,
          issued_at: true
        }
      }
    }
  });

  // If no active trip, return null
  if (!activeTrip) {
    return null;
  }

  // Calculate current totals
  const ticketsCount = activeTrip.tickets.length;
  const totalRevenue = activeTrip.tickets.reduce(
    (sum, ticket) => sum + Number(ticket.amount),
    0
  );

  // Return trip with calculated totals
  return {
    ...activeTrip,
    tickets_count: ticketsCount,
    total_revenue: totalRevenue,
    // Remove full ticket details to keep response size small
    tickets: undefined
  };
};

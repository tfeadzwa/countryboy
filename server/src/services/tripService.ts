import prisma from '../utils/prisma';
import { Prisma } from '@prisma/client';
import { ensureRoute } from './routeService';
import { isDeviceOnline } from '../constants/presence';

export const startTrip = async (
  depotId: string,
  data: {
    agent_id: string;
    fleet_id: string;
    driver_id?: string;
    origin: string;
    destination: string;
    route_id?: string;
    device_id?: string;
    started_offline?: boolean;
  }
) => {
  const parent = await ensureRoute(depotId, data.origin, data.destination);

  if (data.driver_id) {
    const driver = await prisma.tblDrivers.findUnique({
      where: { id: data.driver_id },
    });
    if (!driver || driver.depot_id !== depotId) {
      throw new Error('Driver not found in this depot');
    }
  }

  return prisma.tblTrips.create({
    data: {
      depot_id: depotId,
      agent_id: data.agent_id,
      fleet_id: data.fleet_id,
      driver_id: data.driver_id ?? null,
      origin: data.origin.trim(),
      destination: data.destination.trim(),
      route_id: parent.id,
      device_id: data.device_id,
      started_at: new Date(),
      status: 'ACTIVE',
      started_offline: data.started_offline || false,
    },
  });
};

export const endTrip = async (tripId: string, depotId?: string) => {
  const trip = await prisma.tblTrips.findUnique({ where: { id: tripId } });
  if (!trip) {
    throw new Error('Trip not found');
  }
  if (depotId && trip.depot_id !== depotId) {
    throw new Error('Trip not found in this depot');
  }
  if (trip.status !== 'ACTIVE') {
    throw new Error('Trip is already ended');
  }

  return prisma.tblTrips.update({
    where: { id: tripId },
    data: { ended_at: new Date(), status: 'ENDED' },
    include: {
      agent: { select: { id: true, full_name: true, agent_code: true } },
      fleet: { select: { id: true, number: true, registration_number: true } },
      driver: { select: { id: true, full_name: true } },
      depot: { select: { id: true, name: true } },
    },
  });
};

export const listActiveTrips = async (depotId?: string) => {
  const where: Prisma.tblTripsWhereInput = { status: 'ACTIVE' };
  if (depotId) where.depot_id = depotId;
  return prisma.tblTrips.findMany({ where });
};

export const getTrip = async (tripId: string, depotId?: string) => {
  const trip = await prisma.tblTrips.findUnique({
    where: { id: tripId },
    include: {
      agent: {
        select: {
          id: true,
          full_name: true,
          agent_code: true,
          username: true,
          status: true,
        },
      },
      driver: {
        select: {
          id: true,
          full_name: true,
          phone: true,
          licence_number: true,
          employee_code: true,
          status: true,
        },
      },
      fleet: {
        select: {
          id: true,
          number: true,
          registration_number: true,
          capacity: true,
          status: true,
        },
      },
      depot: { select: { id: true, name: true, merchant_code: true } },
      device: {
        select: {
          id: true,
          serial_number: true,
          device_name: true,
          device_model: true,
          paired: true,
          last_seen: true,
        },
      },
      route: {
        select: { id: true, origin: true, destination: true },
      },
      tickets: {
        include: {
          voids: true,
        },
        orderBy: { issued_at: 'desc' },
      },
    },
  });

  if (!trip) return null;
  if (depotId && trip.depot_id !== depotId) return null;

  const [agentOpenSession, driverActiveTrip] = await Promise.all([
    prisma.tblAgentDeviceSessions.findFirst({
      where: { agent_id: trip.agent_id, ended_at: null },
      orderBy: { started_at: 'desc' },
      include: {
        device: {
          select: { id: true, paired: true, last_seen: true },
        },
      },
    }),
    trip.driver_id
      ? prisma.tblTrips.findFirst({
          where: {
            driver_id: trip.driver_id,
            status: 'ACTIVE',
          },
          select: { id: true },
        })
      : Promise.resolve(null),
  ]);

  return formatTripDetail(trip, {
    agentOpenSession,
    driverHasActiveTrip: Boolean(driverActiveTrip),
  });
};

type TripDetailRecord = NonNullable<
  Awaited<ReturnType<typeof prisma.tblTrips.findUnique>>
> & {
  agent?: {
    id: string;
    full_name: string;
    agent_code: string;
    username: string | null;
    status: string;
  } | null;
  driver?: {
    id: string;
    full_name: string;
    phone: string | null;
    licence_number: string | null;
    employee_code: string | null;
    status: string;
  } | null;
  fleet?: {
    id: string;
    number: string;
    capacity: number;
    status: string;
  } | null;
  depot?: { id: string; name: string; merchant_code: string } | null;
  device?: {
    id: string;
    serial_number: string;
    device_name: string | null;
    device_model: string | null;
    paired?: boolean;
    last_seen?: Date | null;
  } | null;
  route?: { id: string; origin: string; destination: string } | null;
  tickets: Array<{
    id: string;
    serial_number: number | null;
    ticket_category: string;
    currency: string;
    amount: { toString(): string } | number;
    luggage_amount?: { toString(): string } | number | null;
    departure: string | null;
    destination: string | null;
    passenger_name: string | null;
    passenger_phone: string | null;
    luggage_description: string | null;
    printed?: boolean;
    printed_at?: Date | null;
    printer_name?: string | null;
    printer_mac?: string | null;
    printer_serial?: string | null;
    issued_at: Date;
    voids: Array<{
      id: string;
      reason: string;
      created_at: Date;
      agent_id: string | null;
      device_id: string | null;
      admin_user_id: string | null;
    }>;
  }>;
};

type TripPresenceContext = {
  agentOpenSession?: {
    id: string;
    device?: { id: string; paired: boolean; last_seen: Date | null } | null;
  } | null;
  driverHasActiveTrip?: boolean;
};

export const formatTripDetail = (
  trip: TripDetailRecord,
  presence: TripPresenceContext = {},
) => {
  const mappedTickets = trip.tickets.map((ticket) => {
    const isVoided = ticket.voids.length > 0;
    return {
      id: ticket.id,
      serial_number: ticket.serial_number,
      ticket_category: ticket.ticket_category,
      currency: ticket.currency,
      amount: Number(ticket.amount),
      luggage_amount:
        ticket.luggage_amount != null ? Number(ticket.luggage_amount) : null,
      departure: ticket.departure,
      destination: ticket.destination,
      passenger_name: ticket.passenger_name,
      passenger_phone: ticket.passenger_phone,
      luggage_description: ticket.luggage_description,
      printed: ticket.printed,
      printed_at: ticket.printed_at ? ticket.printed_at.toISOString() : null,
      printer_name: ticket.printer_name ?? null,
      printer_mac: ticket.printer_mac ?? null,
      printer_serial: ticket.printer_serial ?? null,
      issued_at: ticket.issued_at.toISOString(),
      is_voided: isVoided,
      voids: ticket.voids.map((v) => ({
        id: v.id,
        reason: v.reason,
        created_at: v.created_at.toISOString(),
        agent_id: v.agent_id,
        device_id: v.device_id,
        admin_user_id: v.admin_user_id,
      })),
    };
  });

  const validTickets = mappedTickets.filter((t) => !t.is_voided);
  const voidedCount = mappedTickets.length - validTickets.length;
  const totalRevenue = validTickets.reduce((sum, t) => sum + t.amount, 0);
  const revenueByCurrency = validTickets.reduce<Record<string, number>>(
    (acc, t) => {
      acc[t.currency] = (acc[t.currency] ?? 0) + t.amount;
      return acc;
    },
    {},
  );
  const categoryCounts = validTickets.reduce<Record<string, number>>(
    (acc, t) => {
      acc[t.ticket_category] = (acc[t.ticket_category] ?? 0) + 1;
      return acc;
    },
    {},
  );

  const status = trip.status === 'COMPLETED' ? 'ENDED' : trip.status;
  const durationMs = (trip.ended_at ?? new Date()).getTime() - trip.started_at.getTime();

  const sessionDevice = presence.agentOpenSession?.device;
  const conductorOnline = isDeviceOnline({
    paired: Boolean(sessionDevice?.paired),
    lastSeen: sessionDevice?.last_seen ?? null,
    hasOpenSession: Boolean(presence.agentOpenSession),
  });
  const conductor_presence = presence.agentOpenSession
    ? conductorOnline
      ? 'online'
      : 'offline'
    : 'signed_out';

  const driverAccount = trip.driver?.status ?? null;
  const driver_duty_status = !trip.driver
    ? null
    : driverAccount !== 'ACTIVE'
      ? 'off_duty'
      : presence.driverHasActiveTrip || status === 'ACTIVE'
        ? 'on_trip'
        : 'available';

  const devicePaired = Boolean(trip.device?.paired);
  const deviceOnline = isDeviceOnline({
    paired: devicePaired,
    lastSeen: trip.device?.last_seen ?? null,
    // Device presence on a trip: treat recent last_seen as online when paired.
    hasOpenSession: devicePaired,
  });
  const device_presence = !trip.device
    ? null
    : !devicePaired
      ? 'unpaired'
      : deviceOnline
        ? 'online'
        : 'offline';

  return {
    id: trip.id,
    depot_id: trip.depot_id,
    depot_name: trip.depot?.name ?? null,
    depot_merchant_code: trip.depot?.merchant_code ?? null,
    agent_id: trip.agent_id,
    agent_name: trip.agent?.full_name ?? null,
    agent_code: trip.agent?.agent_code ?? null,
    agent_username: trip.agent?.username ?? null,
    agent_status: trip.agent?.status ?? null,
    conductor_presence,
    conductor_is_online: conductorOnline,
    driver_id: trip.driver_id,
    driver_name: trip.driver?.full_name ?? null,
    driver_phone: trip.driver?.phone ?? null,
    driver_licence: trip.driver?.licence_number ?? null,
    driver_employee_code: trip.driver?.employee_code ?? null,
    driver_status: driverAccount,
    driver_duty_status,
    fleet_id: trip.fleet_id,
    fleet_number: trip.fleet?.number ?? null,
    fleet_registration_number: trip.fleet?.registration_number ?? null,
    fleet_capacity: trip.fleet?.capacity ?? null,
    fleet_status: trip.fleet?.status ?? null,
    device_id: trip.device_id,
    device_serial: trip.device?.serial_number ?? null,
    device_name: trip.device?.device_name ?? null,
    device_model: trip.device?.device_model ?? null,
    device_paired: trip.device ? devicePaired : null,
    device_last_seen: trip.device?.last_seen
      ? trip.device.last_seen.toISOString()
      : null,
    device_presence,
    route_id: trip.route_id,
    origin: trip.origin,
    destination: trip.destination,
    route_label: `${trip.origin} → ${trip.destination}`,
    route_origin: trip.route?.origin ?? null,
    route_destination: trip.route?.destination ?? null,
    status,
    started_at: trip.started_at.toISOString(),
    ended_at: trip.ended_at ? trip.ended_at.toISOString() : null,
    started_offline: trip.started_offline,
    duration_ms: durationMs,
    ticket_count: validTickets.length,
    voided_ticket_count: voidedCount,
    total_revenue: totalRevenue,
    revenue_by_currency: revenueByCurrency,
    category_counts: categoryCounts,
    tickets: mappedTickets,
    created_at: trip.created_at.toISOString(),
    updated_at: trip.updated_at.toISOString(),
  };
};

export const getTripTotals = async (tripId: string) => {
  // Get all tickets with void information
  const tickets = await prisma.tblTickets.findMany({
    where: { trip_id: tripId },
    include: { voids: true },
  });
  
  // Filter out voided tickets (tickets with void records)
  const validTickets = tickets.filter((t) => t.voids.length === 0);
  
  let total = 0;
  validTickets.forEach((t) => (total += parseFloat(t.amount.toString())));
  return { ticketCount: validTickets.length, total };
};

export const listTrips = async (depotId?: string, filters?: {
  status?: string;
  agent_id?: string;
  fleet_id?: string;
  date_from?: string;
  date_to?: string;
}) => {
  const where: Prisma.tblTripsWhereInput = {};
  if (depotId) where.depot_id = depotId;
  
  if (filters?.status) {
    if (filters.status === 'ENDED') {
      where.status = { in: ['ENDED', 'COMPLETED'] };
    } else {
      where.status = filters.status;
    }
  }
  if (filters?.agent_id) {
    where.agent_id = filters.agent_id;
  }
  if (filters?.fleet_id) {
    where.fleet_id = filters.fleet_id;
  }
  if (filters?.date_from || filters?.date_to) {
    where.started_at = {};
    if (filters.date_from) {
      where.started_at.gte = new Date(filters.date_from);
    }
    if (filters.date_to) {
      where.started_at.lte = new Date(filters.date_to);
    }
  }

  return prisma.tblTrips.findMany({
    where,
    include: {
      agent: true,
      fleet: true,
      route: true,
      depot: true,
      tickets: {
        include: {
          voids: true,
        },
      },
    },
    orderBy: { started_at: 'desc' },
  });
};

export type CorridorSummary = {
  id: string;
  key: string;
  origin: string;
  destination: string;
  trip_count: number;
  active_trip_count: number;
  ticket_count: number;
  child_route_count: number;
  last_trip_at: string | null;
  fleets: string[];
};

/** Main corridors = parent routes that conductors created when starting trips. */
export const listCorridors = async (depotId?: string): Promise<CorridorSummary[]> => {
  const where: Prisma.tblTripsWhereInput = {
    route_id: { not: null },
  };
  if (depotId) where.depot_id = depotId;

  const trips = await prisma.tblTrips.findMany({
    where,
    select: {
      route_id: true,
      origin: true,
      destination: true,
      started_at: true,
      status: true,
      fleet: { select: { number: true } },
      tickets: {
        select: {
          id: true,
          voids: { select: { id: true } },
        },
      },
      route: {
        select: {
          id: true,
          origin: true,
          destination: true,
          parentLinks: { select: { id: true } },
        },
      },
    },
    orderBy: { started_at: 'desc' },
  });

  const map = new Map<
    string,
    CorridorSummary & { _fleetSet: Set<string> }
  >();

  for (const trip of trips) {
    const routeId = trip.route_id;
    if (!routeId || !trip.route) continue;

    let entry = map.get(routeId);
    if (!entry) {
      entry = {
        id: routeId,
        key: routeId,
        origin: trip.route.origin,
        destination: trip.route.destination,
        trip_count: 0,
        active_trip_count: 0,
        ticket_count: 0,
        child_route_count: trip.route.parentLinks.length,
        last_trip_at: null,
        fleets: [],
        _fleetSet: new Set<string>(),
      };
      map.set(routeId, entry);
    }

    entry.trip_count += 1;
    if (trip.status === 'ACTIVE') entry.active_trip_count += 1;
    entry.ticket_count += trip.tickets.filter((t) => t.voids.length === 0).length;
    if (!entry.last_trip_at || trip.started_at > new Date(entry.last_trip_at)) {
      entry.last_trip_at = trip.started_at.toISOString();
    }
    if (trip.fleet?.number) entry._fleetSet.add(trip.fleet.number);
  }

  return Array.from(map.values())
    .map(({ _fleetSet, ...rest }) => ({
      ...rest,
      fleets: Array.from(_fleetSet).sort(),
    }))
    .sort((a, b) => b.trip_count - a.trip_count);
};

export const getCorridorDetail = async (routeId: string, depotId?: string) => {
  const route = await prisma.tblRoutes.findFirst({
    where: {
      id: routeId,
      ...(depotId ? { depot_id: depotId } : {}),
    },
    include: {
      depot: { select: { id: true, name: true } },
      parentLinks: {
        include: {
          childRoute: {
            select: { id: true, origin: true, destination: true, is_active: true },
          },
        },
        orderBy: { created_at: 'asc' },
      },
      trips: {
        orderBy: { started_at: 'desc' },
        take: 20,
        include: {
          fleet: { select: { number: true } },
          agent: { select: { full_name: true } },
          tickets: {
            select: {
              id: true,
              amount: true,
              currency: true,
              departure: true,
              destination: true,
              ticket_category: true,
              issued_at: true,
              voids: { select: { id: true } },
            },
          },
        },
      },
    },
  });

  if (!route) return null;

  const allTrips = await prisma.tblTrips.findMany({
    where: {
      route_id: routeId,
      ...(depotId ? { depot_id: depotId } : {}),
    },
    select: {
      id: true,
      status: true,
      fleet: { select: { number: true } },
      tickets: {
        select: {
          id: true,
          amount: true,
          currency: true,
          departure: true,
          destination: true,
          voids: { select: { id: true } },
        },
      },
    },
  });

  const fleetSet = new Set<string>();
  let ticketCount = 0;
  let revenueByCurrency: Record<string, number> = {};
  let activeTripCount = 0;
  const segmentStats = new Map<
    string,
    { origin: string; destination: string; ticket_count: number; revenue: number }
  >();

  for (const trip of allTrips) {
    if (trip.status === 'ACTIVE') activeTripCount += 1;
    if (trip.fleet?.number) fleetSet.add(trip.fleet.number);
    for (const ticket of trip.tickets) {
      if (ticket.voids.length > 0) continue;
      ticketCount += 1;
      const amount = Number(ticket.amount);
      revenueByCurrency[ticket.currency] =
        (revenueByCurrency[ticket.currency] ?? 0) + amount;
      const dep = ticket.departure?.trim();
      const dest = ticket.destination?.trim();
      if (dep && dest) {
        const key = `${dep.toLowerCase()}→${dest.toLowerCase()}`;
        const existing = segmentStats.get(key) ?? {
          origin: dep,
          destination: dest,
          ticket_count: 0,
          revenue: 0,
        };
        existing.ticket_count += 1;
        existing.revenue += amount;
        segmentStats.set(key, existing);
      }
    }
  }

  const children = route.parentLinks.map((link) => {
    const child = link.childRoute;
    const key = `${child.origin.toLowerCase()}→${child.destination.toLowerCase()}`;
    const stats = segmentStats.get(key);
    return {
      id: child.id,
      origin: child.origin,
      destination: child.destination,
      label: `${child.origin} → ${child.destination}`,
      is_active: child.is_active,
      ticket_count: stats?.ticket_count ?? 0,
      revenue: stats?.revenue ?? 0,
    };
  }).sort((a, b) => b.ticket_count - a.ticket_count || a.origin.localeCompare(b.origin));

  return {
    id: route.id,
    origin: route.origin,
    destination: route.destination,
    label: `${route.origin} → ${route.destination}`,
    depot: route.depot,
    is_active: route.is_active,
    created_at: route.created_at.toISOString(),
    summary: {
      trip_count: allTrips.length,
      active_trip_count: activeTripCount,
      ticket_count: ticketCount,
      child_route_count: children.length,
      fleets: Array.from(fleetSet).sort(),
      revenue_by_currency: revenueByCurrency,
    },
    child_routes: children,
    recent_trips: route.trips.map((trip) => {
      const validTickets = trip.tickets.filter((t) => t.voids.length === 0);
      return {
        id: trip.id,
        status: trip.status,
        started_at: trip.started_at.toISOString(),
        ended_at: trip.ended_at?.toISOString() ?? null,
        fleet_number: trip.fleet?.number ?? null,
        agent_name: trip.agent?.full_name ?? null,
        ticket_count: validTickets.length,
        segments: Array.from(
          new Set(
            validTickets
              .map((t) =>
                t.departure && t.destination
                  ? `${t.departure} → ${t.destination}`
                  : null,
              )
              .filter(Boolean),
          ),
        ),
      };
    }),
  };
};

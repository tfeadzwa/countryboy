import prisma from '../utils/prisma';
import { Prisma } from '@prisma/client';
import { ensureRoute } from './routeService';

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

export const endTrip = async (tripId: string) => {
  return prisma.tblTrips.update({
    where: { id: tripId },
    data: { ended_at: new Date(), status: 'ENDED' },
  });
};

export const listActiveTrips = async (depotId?: string) => {
  const where: Prisma.tblTripsWhereInput = { status: 'ACTIVE' };
  if (depotId) where.depot_id = depotId;
  return prisma.tblTrips.findMany({ where });
};

export const getTrip = async (tripId: string) => {
  return prisma.tblTrips.findUnique({ where: { id: tripId }, include: { tickets: true } });
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
    where.status = filters.status;
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

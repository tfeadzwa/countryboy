import prisma from '../utils/prisma';
import { Prisma } from '@prisma/client';

export const getOverview = async (depotId?: string) => {
  const where: any = {};
  if (depotId) where.depot_id = depotId;

  // revenue today/week/month, ticket counts, active agents/devices etc.
  const today = new Date();
  const startOfDay = new Date(today.getFullYear(), today.getMonth(), today.getDate());

  const revenueToday = await prisma.tblTickets.aggregate({
    where: { ...where, issued_at: { gte: startOfDay } },
    _sum: { amount: true }
  });

  const ticketCountToday = await prisma.tblTickets.count({ where: { ...where, issued_at: { gte: startOfDay } } });

  const activeTrips = await prisma.tblTrips.count({ where: { ...where, ended_at: null } });
  const activeAgents = await prisma.tblAgents.count({ where: { ...where, status: 'ACTIVE' } });

  return {
    revenueToday: revenueToday._sum.amount || 0,
    ticketCountToday,
    activeTrips,
    activeAgents
  };
};

export const getRevenueTimeseries = async (depotId?: string, from?: Date, to?: Date) => {
  // Multi-currency daily grouping
  const data: any[] = await prisma.$queryRaw`
    SELECT 
      date_trunc('day', issued_at)::date as date,
      currency,
      SUM(amount) as total
    FROM "tblTickets"
    LEFT JOIN "tblTicketVoids" ON "tblTickets".id = "tblTicketVoids".ticket_id
    WHERE (${depotId}::text IS NULL OR depot_id = ${depotId})
    AND issued_at BETWEEN ${from ?? new Date(0)} AND ${to ?? new Date()}
    AND "tblTicketVoids".id IS NULL
    GROUP BY date, currency
    ORDER BY date;
  `;

  // Transform to { date, usd, zwl, zar } format
  const grouped: Record<string, any> = {};
  data.forEach((row) => {
    const dateStr = row.date.toISOString().split('T')[0];
    if (!grouped[dateStr]) {
      grouped[dateStr] = { date: dateStr, usd: 0, zwl: 0, zar: 0 };
    }
    const currency = row.currency.toLowerCase();
    grouped[dateStr][currency] = Number(row.total);
  });

  return Object.values(grouped);
};

export const getRevenueByCurrency = async (depotId?: string, from?: Date, to?: Date) => {
  const where: Prisma.tblTicketsWhereInput = {};
  if (depotId) where.depot_id = depotId;
  if (from || to) {
    where.issued_at = {};
    if (from) where.issued_at.gte = from;
    if (to) where.issued_at.lte = to;
  }

  // Get all tickets with void information
  const tickets = await prisma.tblTickets.findMany({
    where,
    include: { voids: true },
  });

  // Exclude voided tickets and sum by currency
  const validTickets = tickets.filter((t) => t.voids.length === 0);
  const breakdown = { usd: 0, zwl: 0, zar: 0 };

  validTickets.forEach((t) => {
    const currency = t.currency.toLowerCase() as 'usd' | 'zwl' | 'zar';
    breakdown[currency] += Number(t.amount);
  });

  return breakdown;
};

export const getAgentPerformance = async (depotId?: string, from?: Date, to?: Date, limit = 10) => {
  const where: Prisma.tblTicketsWhereInput = {};
  if (depotId) where.depot_id = depotId;
  if (from || to) {
    where.issued_at = {};
    if (from) where.issued_at.gte = from;
    if (to) where.issued_at.lte = to;
  }

  const tickets = await prisma.tblTickets.findMany({
    where,
    include: { 
      agent: true,
      voids: true 
    },
  });

  // Group by agent, exclude voided tickets
  const agentMap: Record<string, { agent_id: string; agent_name: string; revenue: number; ticket_count: number }> = {};

  tickets.forEach((t) => {
    if (t.voids.length > 0) return; // Skip voided tickets
    
    if (!agentMap[t.agent_id]) {
      agentMap[t.agent_id] = {
        agent_id: t.agent_id,
        agent_name: t.agent.full_name,
        revenue: 0,
        ticket_count: 0,
      };
    }
    agentMap[t.agent_id].revenue += Number(t.amount);
    agentMap[t.agent_id].ticket_count += 1;
  });

  return Object.values(agentMap)
    .sort((a, b) => b.revenue - a.revenue)
    .slice(0, limit);
};

export const getFleetUtilization = async (depotId?: string) => {
  const where: Prisma.tblFleetsWhereInput = {};
  if (depotId) where.depot_id = depotId;

  const fleets = await prisma.tblFleets.findMany({ where });

  const statusCounts = {
    total: fleets.length,
    active: fleets.filter((f) => f.status === 'ACTIVE').length,
    maintenance: fleets.filter((f) => f.status === 'MAINTENANCE').length,
    out_of_service: fleets.filter((f) => f.status === 'OUT_OF_SERVICE').length,
    retired: fleets.filter((f) => f.status === 'RETIRED').length,
  };

  // Count fleets currently on active trips
  const activeTripsWhere: Prisma.tblTripsWhereInput = { status: 'ACTIVE' };
  if (depotId) activeTripsWhere.depot_id = depotId;
  
  const activeTrips = await prisma.tblTrips.count({ where: activeTripsWhere });

  return {
    ...statusCounts,
    active_trips: activeTrips,
  };
};

export const getRoutePerformance = async (depotId?: string, from?: Date, to?: Date, limit = 10) => {
  const tripWhere: Prisma.tblTripsWhereInput = {};
  if (depotId) tripWhere.depot_id = depotId;
  if (from || to) {
    tripWhere.started_at = {};
    if (from) tripWhere.started_at.gte = from;
    if (to) tripWhere.started_at.lte = to;
  }

  const trips = await prisma.tblTrips.findMany({
    where: tripWhere,
    include: {
      route: true,
      tickets: {
        include: { voids: true },
      },
    },
  });

  // Group by route
  const routeMap: Record<string, { route_id: string; route_label: string; ticket_count: number; revenue: number }> = {};

  trips.forEach((trip) => {
    if (!trip.route) return; // Skip trips without routes

    const routeKey = trip.route_id || 'unknown';
    if (!routeMap[routeKey]) {
      routeMap[routeKey] = {
        route_id: trip.route_id || '',
        route_label: `${trip.route.origin} → ${trip.route.destination}`,
        ticket_count: 0,
        revenue: 0,
      };
    }

    // Add valid tickets only
    const validTickets = trip.tickets.filter((t) => t.voids.length === 0);
    routeMap[routeKey].ticket_count += validTickets.length;
    routeMap[routeKey].revenue += validTickets.reduce((sum, t) => sum + Number(t.amount), 0);
  });

  return Object.values(routeMap)
    .sort((a, b) => b.revenue - a.revenue)
    .slice(0, limit);
};

export const getVoidRate = async (depotId?: string, from?: Date, to?: Date) => {
  const where: Prisma.tblTicketsWhereInput = {};
  if (depotId) where.depot_id = depotId;
  if (from || to) {
    where.issued_at = {};
    if (from) where.issued_at.gte = from;
    if (to) where.issued_at.lte = to;
  }

  const tickets = await prisma.tblTickets.findMany({
    where,
    include: { voids: true },
  });

  const total_tickets = tickets.length;
  const voided_tickets = tickets.filter((t) => t.voids.length > 0).length;
  const void_rate = total_tickets > 0 ? (voided_tickets / total_tickets) * 100 : 0;

  return {
    total_tickets,
    voided_tickets,
    void_rate: Number(void_rate.toFixed(2)),
  };
};

export const getDepotComparison = async () => {
  const depots = await prisma.tblDepots.findMany();

  const comparison = await Promise.all(
    depots.map(async (depot) => {
      const tickets = await prisma.tblTickets.findMany({
        where: { depot_id: depot.id },
        include: { voids: true },
      });

      const validTickets = tickets.filter((t) => t.voids.length === 0);
      const revenue = validTickets.reduce((sum, t) => sum + Number(t.amount), 0);

      const activeAgents = await prisma.tblAgents.count({
        where: { depot_id: depot.id, status: 'ACTIVE' },
      });

      const activeTrips = await prisma.tblTrips.count({
        where: { depot_id: depot.id, status: 'ACTIVE' },
      });

      return {
        depot_id: depot.id,
        depot_name: depot.name,
        revenue,
        tickets: validTickets.length,
        active_agents: activeAgents,
        active_trips: activeTrips,
      };
    })
  );

  return comparison.sort((a, b) => b.revenue - a.revenue);
};

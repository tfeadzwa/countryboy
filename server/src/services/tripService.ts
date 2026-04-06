import prisma from '../utils/prisma';
import { Prisma } from '@prisma/client';

export const startTrip = async (
  depotId: string,
  data: {
    agent_id: string;
    fleet_id: string;
    route_id?: string;
    device_id?: string;
    started_offline?: boolean;
  }
) => {
  return prisma.tblTrips.create({
    data: {
      ...data,
      depot_id: depotId,
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

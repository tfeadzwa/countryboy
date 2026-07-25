import prisma from '../utils/prisma';
import { Prisma } from '@prisma/client';
import { linkTicketSegmentToTrip } from './routeService';
import { allocateTripSerial } from '../utils/ticketSerial';

interface IssueArgs {
  depot_id: string;
  trip_id: string;
  agent_id: string;
  device_id?: string;
  ticket_category: string; // PASSENGER, PASSENGER_WITH_LUGGAGE, LUGGAGE
  currency: string;
  amount: number;
  luggage_amount?: number | null;
  departure?: string;
  destination?: string;
  passenger_phone?: string | null;
  luggage_description?: string | null;
  issued_at?: Date;
  linked_passenger_ticket_id?: string;
}

export const issueTicket = async (args: IssueArgs) => {
  return prisma.$transaction(async (tx) => {
    const trip = await tx.tblTrips.findUnique({
      where: { id: args.trip_id },
      select: {
        id: true,
        depot_id: true,
        origin: true,
        destination: true,
        route_id: true,
        status: true,
      },
    });

    if (!trip) {
      throw new Error('Trip not found');
    }

    if (trip.status !== 'ACTIVE') {
      throw new Error(
        'Trip is closed. Tickets can no longer be issued on this trip.',
      );
    }

    // Ticket OD becomes a normal route; link as child under the trip's main corridor.
    await linkTicketSegmentToTrip(
      trip,
      args.departure,
      args.destination,
      { client: tx },
    );

    const serial = await allocateTripSerial(tx, args.trip_id);

    return tx.tblTickets.create({
      data: {
        depot_id: args.depot_id,
        trip_id: args.trip_id,
        agent_id: args.agent_id,
        device_id: args.device_id,
        ticket_category: args.ticket_category,
        currency: args.currency,
        amount: args.amount,
        luggage_amount: args.luggage_amount ?? null,
        departure: args.departure,
        destination: args.destination,
        passenger_name: null,
        passenger_phone: args.passenger_phone?.trim() || null,
        luggage_description: args.luggage_description?.trim() || null,
        issued_at: args.issued_at || new Date(),
        linked_passenger_ticket_id: args.linked_passenger_ticket_id,
        serial_number: serial,
      },
    });
  });
};

export const voidTicket = async (
  ticketId: string,
  reason: string,
  opts?: { agent_id?: string; device_id?: string; admin_user_id?: string }
) => {
  // Create void record instead of updating ticket
  return prisma.tblTicketVoids.create({
    data: {
      ticket_id: ticketId,
      reason,
      agent_id: opts?.agent_id,
      device_id: opts?.device_id,
      admin_user_id: opts?.admin_user_id,
    },
  });
};

export const isTicketVoided = async (ticketId: string): Promise<boolean> => {
  const voidRecord = await prisma.tblTicketVoids.findFirst({
    where: { ticket_id: ticketId },
  });
  return !!voidRecord;
};

export const searchTickets = async (query: Prisma.tblTicketsWhereInput) => {
  return prisma.tblTickets.findMany({ where: query, include: { voids: true } });
};

export const listTickets = async (depotId?: string) => {
  const where: Prisma.tblTicketsWhereInput = {};
  if (depotId) where.depot_id = depotId;
  
  return prisma.tblTickets.findMany({
    where,
    include: {
      voids: true,
      trip: {
        include: {
          fleet: true,
          route: true,
        },
      },
      agent: true,
      device: true,
    },
    orderBy: { issued_at: 'desc' },
  });
};

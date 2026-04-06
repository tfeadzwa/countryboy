import prisma from '../utils/prisma';
import { Prisma } from '@prisma/client';

interface IssueArgs {
  depot_id: string;
  trip_id: string;
  agent_id: string;
  device_id?: string;
  ticket_category: string; // PASSENGER, PASSENGER_WITH_LUGGAGE, LUGGAGE
  currency: string;
  amount: number;
  departure?: string;
  destination?: string;
  issued_at?: Date;
  linked_passenger_ticket_id?: string;
}

export const issueTicket = async (args: IssueArgs) => {
  const ticket = await prisma.tblTickets.create({
    data: {
      ...args,
      issued_at: args.issued_at || new Date(),
    },
  });
  return ticket;
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

import prisma from '../utils/prisma';
import { formatTicketNumber } from '../utils/ticketSerial';

const categoryLabel = (category: string) => {
  switch (category) {
    case 'PASSENGER':
      return 'Passenger';
    case 'PASSENGER_WITH_LUGGAGE':
      return 'Passenger + Luggage';
    case 'LUGGAGE':
      return 'Luggage';
    default:
      return category;
  }
};

/**
 * Public ticket verification payload for QR scans.
 * Returns a safe subset of fields — no merchant/agent codes, device tokens, etc.
 */
export const getPublicTicketVerification = async (ticketId: string) => {
  const ticket = await prisma.tblTickets.findUnique({
    where: { id: ticketId },
    include: {
      voids: {
        orderBy: { created_at: 'desc' },
        take: 1,
        select: { reason: true, created_at: true },
      },
      depot: { select: { name: true, location: true } },
      agent: { select: { full_name: true } },
      trip: {
        select: {
          id: true,
          started_at: true,
          status: true,
          fleet: { select: { number: true } },
          route: { select: { origin: true, destination: true } },
        },
      },
    },
  });

  if (!ticket) return null;

  const voidRecord = ticket.voids[0] ?? null;
  const origin =
    ticket.departure ?? ticket.trip.route?.origin ?? null;
  const destination =
    ticket.destination ?? ticket.trip.route?.destination ?? null;

  return {
    verified: true,
    status: voidRecord ? 'VOIDED' : 'VALID',
    ticket: {
      id: ticket.id,
      serial_number: ticket.serial_number,
      display_number: formatTicketNumber(ticket.serial_number),
      category: ticket.ticket_category,
      category_label: categoryLabel(ticket.ticket_category),
      currency: ticket.currency,
      amount: Number(ticket.amount),
      luggage_amount:
        ticket.luggage_amount != null ? Number(ticket.luggage_amount) : null,
      origin,
      destination,
      route_label:
        origin && destination ? `${origin} -> ${destination}` : null,
      passenger_phone: ticket.passenger_phone,
      luggage_description: ticket.luggage_description,
      issued_at: ticket.issued_at.toISOString(),
    },
    trip: {
      fleet_number: ticket.trip.fleet?.number ?? null,
      started_at: ticket.trip.started_at.toISOString(),
      status: ticket.trip.status,
    },
    depot: {
      name: ticket.depot.name,
      location: ticket.depot.location,
    },
    conductor: {
      name: ticket.agent.full_name,
    },
    void_info: voidRecord
      ? {
          reason: voidRecord.reason,
          voided_at: voidRecord.created_at.toISOString(),
        }
      : null,
  };
};

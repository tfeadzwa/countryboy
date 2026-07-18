import { Prisma } from '@prisma/client';

/** Display ticket numbers as 001, 002, … (grows past 999 naturally). */
export const formatTicketNumber = (serial: number | null | undefined): string => {
  if (serial == null) return '—';
  return String(serial).padStart(3, '0');
};

/**
 * Next ticket number for a trip (1 = displayed as 001).
 * Resets when a new trip starts so conductors can count tickets per trip.
 */
export const allocateTripSerial = async (
  prismaTx: Prisma.TransactionClient,
  tripId: string,
): Promise<number> => {
  const last = await prismaTx.tblTickets.findFirst({
    where: { trip_id: tripId, serial_number: { not: null } },
    orderBy: { serial_number: 'desc' },
    select: { serial_number: true },
  });

  return (last?.serial_number ?? 0) + 1;
};

/** @deprecated Use allocateTripSerial */
export const allocateSerial = allocateTripSerial;

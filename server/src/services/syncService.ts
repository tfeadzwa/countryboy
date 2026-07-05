import prisma from '../utils/prisma';
import logger from '../utils/logger';
import { Prisma } from '@prisma/client';

interface PushPayload {
  trips?: any[];
  tickets?: any[];
}

/** Mobile sends Dart `toIso8601String()` without a timezone suffix — Prisma rejects those. */
const parseSyncDateTime = (value: unknown, field: string): Date => {
  if (value instanceof Date && !Number.isNaN(value.getTime())) return value;

  if (typeof value === 'string' && value.trim()) {
    let normalized = value.trim();
    if (/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?$/.test(normalized)) {
      normalized = `${normalized}Z`;
    }
    const parsed = new Date(normalized);
    if (!Number.isNaN(parsed.getTime())) return parsed;
  }

  throw new Error(`Invalid ${field} datetime: ${String(value)}`);
};

const normalizeTripRecord = (raw: Record<string, unknown>, depotId: string) => ({
  id: raw.id as string,
  depot_id: depotId,
  agent_id: raw.agent_id as string,
  fleet_id: raw.fleet_id as string,
  route_id: (raw.route_id as string | undefined) ?? null,
  device_id: (raw.device_id as string | undefined) ?? null,
  started_at: parseSyncDateTime(raw.started_at, 'started_at'),
  ended_at: raw.ended_at != null ? parseSyncDateTime(raw.ended_at, 'ended_at') : null,
  status: (raw.status as string | undefined) ?? 'ACTIVE',
  started_offline: Boolean(raw.started_offline),
});

const normalizeTicketRecord = (raw: Record<string, unknown>, depotId: string) => ({
  id: raw.id as string,
  depot_id: depotId,
  trip_id: raw.trip_id as string,
  agent_id: raw.agent_id as string,
  device_id: (raw.device_id as string | undefined) ?? null,
  serial_number: (raw.serial_number as number | undefined) ?? undefined,
  ticket_category: raw.ticket_category as string,
  currency: raw.currency as string,
  amount: raw.amount as number | string,
  departure: (raw.departure as string | undefined) ?? null,
  destination: (raw.destination as string | undefined) ?? null,
  passenger_name: (raw.passenger_name as string | undefined) ?? null,
  passenger_phone: (raw.passenger_phone as string | undefined) ?? null,
  linked_passenger_ticket_id:
    (raw.linked_passenger_ticket_id as string | undefined) ?? null,
  issued_at: parseSyncDateTime(raw.issued_at, 'issued_at'),
});

export const pushData = async (depotId: string, payload: PushPayload) => {
  const results: any = { trips: [], tickets: [] };
  const start = Date.now();
  let tripCount = 0;
  let ticketCount = 0;

  await prisma.$transaction(async (prismaTx) => {
    if (payload.trips) {
      for (const t of payload.trips) {
        const data = normalizeTripRecord(t, depotId);

        // Offline sync may legitimately replace a stale server-side active trip.
        if (data.status === 'ACTIVE') {
          await prismaTx.tblTrips.updateMany({
            where: {
              agent_id: data.agent_id,
              status: 'ACTIVE',
              id: { not: data.id },
            },
            data: {
              status: 'COMPLETED',
              ended_at: new Date(),
              updated_at: new Date(),
            },
          });
        }

        const upserted = await prismaTx.tblTrips.upsert({
          where: { id: data.id },
          update: { ...data, updated_at: new Date() },
          create: data,
        });
        results.trips.push(upserted);
        tripCount++;
      }
    }
    if (payload.tickets) {
      // Passenger tickets must exist before linked luggage tickets.
      const sortedTickets = [...payload.tickets].sort((a, b) => {
        const aLinked = a.linked_passenger_ticket_id ? 1 : 0;
        const bLinked = b.linked_passenger_ticket_id ? 1 : 0;
        return aLinked - bLinked;
      });

      for (const ti of sortedTickets) {
        const data = normalizeTicketRecord(ti, depotId);
        const upserted = await prismaTx.tblTickets.upsert({
          where: { id: data.id },
          update: { ...data, updated_at: new Date() },
          create: data,
        });
        if (!upserted.serial_number && data.currency) {
          const serial = await allocateSerial(
            prismaTx,
            depotId,
            data.currency,
            data.device_id ?? undefined,
          );
          await prismaTx.tblTickets.update({
            where: { id: upserted.id },
            data: { serial_number: serial },
          });
          upserted.serial_number = serial;
        }
        results.tickets.push(upserted);
        ticketCount++;
      }
    }
  });

  const duration = Date.now() - start;
  // log with details including counts and duration
  await prisma.tblSyncLogs.create({
    data: { depot_id: depotId, type: 'push', success: true, error: null,
      records_pushed: tripCount + ticketCount,
      duration_ms: duration
    }
  });
  logger.info('sync push', { depotId, tripCount, ticketCount, duration });
  return results;
};

export const pullData = async (depotId: string, since?: string) => {
  const start = Date.now();
  const sinceDate = since ? new Date(since) : new Date(0);
  const trips = await prisma.tblTrips.findMany({
    where: { depot_id: depotId, updated_at: { gte: sinceDate } }
  });
  const tickets = await prisma.tblTickets.findMany({
    where: { depot_id: depotId, updated_at: { gte: sinceDate } }
  });
  const duration = Date.now() - start;
  await prisma.tblSyncLogs.create({
    data: {
      depot_id: depotId,
      type: 'pull',
      success: true,
      error: null,
      records_pulled: trips.length + tickets.length,
      duration_ms: duration
    }
  });
  logger.info('sync pull', { depotId, tripCount: trips.length, ticketCount: tickets.length, duration });
  return { trips, tickets };
};

const allocateSerial = async (
  prismaTx: Prisma.TransactionClient,
  depotId: string,
  currency: string,
  deviceId?: string
) => {
  // If no device ID, use a fallback approach (depot-wide allocation)
  // This is for backward compatibility during transition
  if (!deviceId) {
    // For now, generate a simple incremental number
    // In production, you'd want to maintain a depot-level counter or use a different strategy
    return Math.floor(Math.random() * 1000000); // Temporary fallback
  }

  // Find an active serial range for this device and currency
  let range = await prismaTx.tblSerialRanges.findFirst({
    where: {
      depot_id: depotId,
      device_id: deviceId,
      currency,
      exhausted_at: null,
    },
    orderBy: { allocated_at: 'desc' },
  });

  // If no range exists or current range is exhausted, create a new one
  if (!range || range.next_number > range.end_number) {
    if (range) {
      // Mark the old range as exhausted
      await prismaTx.tblSerialRanges.update({
        where: { id: range.id },
        data: { exhausted_at: new Date() },
      });
    }

    // Calculate new range based on last allocated range
    const lastRange = await prismaTx.tblSerialRanges.findFirst({
      where: { depot_id: depotId, device_id: deviceId, currency },
      orderBy: { end_number: 'desc' },
    });

    const startNumber = lastRange ? lastRange.end_number + 1 : 1;
    const endNumber = startNumber + 999; // 1000 serials per range

    range = await prismaTx.tblSerialRanges.create({
      data: {
        depot_id: depotId,
        device_id: deviceId,
        currency,
        start_number: startNumber,
        end_number: endNumber,
        next_number: startNumber,
      },
    });
  }

  // Allocate the next serial number
  const serial = range.next_number;
  await prismaTx.tblSerialRanges.update({
    where: { id: range.id },
    data: { next_number: serial + 1 },
  });

  return serial;
};

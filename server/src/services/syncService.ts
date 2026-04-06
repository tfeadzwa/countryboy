import prisma from '../utils/prisma';
import logger from '../utils/logger';
import { Prisma } from '@prisma/client';

interface PushPayload {
  trips?: any[];
  tickets?: any[];
}

export const pushData = async (depotId: string, payload: PushPayload) => {
  const results: any = { trips: [], tickets: [] };
  const start = Date.now();
  let tripCount = 0;
  let ticketCount = 0;

  const tx = await prisma.$transaction(async (prismaTx) => {
    if (payload.trips) {
      for (const t of payload.trips) {
        const upserted = await prismaTx.tblTrips.upsert({
          where: { id: t.id },
          update: { ...t, depot_id: depotId, updated_at: new Date() },
          create: { ...t, depot_id: depotId }
        });
        results.trips.push(upserted);
        tripCount++;
      }
    }
    if (payload.tickets) {
      for (const ti of payload.tickets) {
        const upserted = await prismaTx.tblTickets.upsert({
          where: { id: ti.id },
          update: { ...ti, depot_id: depotId, updated_at: new Date() },
          create: { ...ti, depot_id: depotId }
        });
        // optionally allocate serial numbers
        if (!upserted.serial_number && ti.currency) {
          const serial = await allocateSerial(prismaTx, depotId, ti.currency, ti.device_id);
          await prismaTx.tblTickets.update({
            where: { id: upserted.id },
            data: { serial_number: serial }
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

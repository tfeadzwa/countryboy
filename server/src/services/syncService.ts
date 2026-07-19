import prisma from '../utils/prisma';
import logger from '../utils/logger';
import { touchDeviceActivity } from './agentSessionService';
import { listFleets } from './fleetService';
import { listRoutes } from './routeService';
import { listFares } from './fareService';
import { allocateTripSerial } from '../utils/ticketSerial';

interface PushPayload {
  trips?: any[];
  tickets?: any[];
}

interface SyncContext {
  agentId?: string;
  deviceId?: string;
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
  passenger_name: null,
  passenger_phone: (raw.passenger_phone as string | undefined)?.trim() || null,
  luggage_description:
    (raw.luggage_description as string | undefined)?.trim() || null,
  linked_passenger_ticket_id:
    (raw.linked_passenger_ticket_id as string | undefined) ?? null,
  issued_at: parseSyncDateTime(raw.issued_at, 'issued_at'),
});

export const pushData = async (
  depotId: string,
  payload: PushPayload,
  context: SyncContext = {},
) => {
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
        if (!upserted.serial_number) {
          const serial = await allocateTripSerial(prismaTx, data.trip_id);
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
    data: {
      depot_id: depotId,
      device_id: context.deviceId ?? null,
      agent_id: context.agentId ?? null,
      type: 'push',
      success: true,
      error: null,
      records_pushed: tripCount + ticketCount,
      duration_ms: duration,
    },
  });
  if (context.deviceId) {
    await touchDeviceActivity(context.deviceId, context.agentId);
  }
  logger.info('sync push', { depotId, tripCount, ticketCount, duration });
  return results;
};

const buildReferenceSnapshot = async (depotId: string) => {
  const [fleets, routes, fares] = await Promise.all([
    listFleets(depotId),
    listRoutes(depotId),
    listFares(depotId),
  ]);

  return {
    fleets: fleets.map((f) => ({
      id: f.id,
      number: f.number,
      status: f.status,
    })),
    routes,
    fares: fares.map((f) => ({
      id: f.id,
      route_id: f.route_id,
      currency: f.currency,
      amount: f.amount,
      route_label: `${f.route.origin} → ${f.route.destination}`,
    })),
  };
};

export const pullData = async (
  depotId: string,
  since?: string,
  context: SyncContext = {},
) => {
  const start = Date.now();
  const sinceDate = since ? new Date(since) : new Date(0);
  const [trips, tickets, reference] = await Promise.all([
    prisma.tblTrips.findMany({
      where: { depot_id: depotId, updated_at: { gte: sinceDate } },
    }),
    prisma.tblTickets.findMany({
      where: { depot_id: depotId, updated_at: { gte: sinceDate } },
    }),
    buildReferenceSnapshot(depotId),
  ]);
  const duration = Date.now() - start;
  await prisma.tblSyncLogs.create({
    data: {
      depot_id: depotId,
      device_id: context.deviceId ?? null,
      agent_id: context.agentId ?? null,
      type: 'pull',
      success: true,
      error: null,
      records_pulled: trips.length + tickets.length,
      duration_ms: duration,
    },
  });
  if (context.deviceId) {
    await touchDeviceActivity(context.deviceId, context.agentId);
  }
  logger.info('sync pull', {
    depotId,
    tripCount: trips.length,
    ticketCount: tickets.length,
    fleetCount: reference.fleets.length,
    routeCount: reference.routes.length,
    fareCount: reference.fares.length,
    duration,
  });
  return { trips, tickets, ...reference };
};

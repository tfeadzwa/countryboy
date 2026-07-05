import { NextFunction, Response } from 'express';
import { AuthenticatedRequest } from './auth';
import { syncPushLogger } from '../utils/logger';

function summarizePayload(body: Record<string, unknown>) {
  const trips = Array.isArray(body.trips) ? body.trips : [];
  const tickets = Array.isArray(body.tickets) ? body.tickets : [];

  return {
    tripCount: trips.length,
    ticketCount: tickets.length,
    tripIds: trips.map((t: { id?: string }) => t.id).filter(Boolean),
    ticketIds: tickets.map((t: { id?: string }) => t.id).filter(Boolean),
    ticketTripIds: tickets.map((t: { trip_id?: string }) => t.trip_id).filter(Boolean),
  };
}

/** Logs the raw sync/push body before validation and handler execution. */
export const logSyncPushRequest = (
  req: AuthenticatedRequest,
  _res: Response,
  next: NextFunction,
) => {
  const body = (req.body ?? {}) as Record<string, unknown>;

  syncPushLogger.info('sync push incoming request', {
    requestId: req.requestId,
    depotId: req.depotId ?? null,
    agentId: req.agentId ?? null,
    deviceId: req.deviceId ?? null,
    hasDeviceToken: Boolean(req.headers['x-device-token']),
    summary: summarizePayload(body),
    body,
  });

  next();
};

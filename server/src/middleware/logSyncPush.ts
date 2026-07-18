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

export function isSyncPushRequest(req: {
  method?: string;
  originalUrl?: string;
  baseUrl?: string;
  path?: string;
}) {
  const path = req.originalUrl ?? `${req.baseUrl ?? ''}${req.path ?? ''}`;
  return req.method === 'POST' && path.includes('/sync/push');
}

/** Logs every sync/push attempt as soon as the request hits the route. */
export const logSyncPushAttempt = (
  req: AuthenticatedRequest,
  _res: Response,
  next: NextFunction,
) => {
  if (!isSyncPushRequest(req)) return next();

  const body = (req.body ?? {}) as Record<string, unknown>;

  syncPushLogger.info('sync push attempt', {
    requestId: req.requestId,
    ip: req.ip,
    hasAuthHeader: Boolean(req.headers.authorization),
    hasDeviceToken: Boolean(req.headers['x-device-token']),
    summary: summarizePayload(body),
  });

  next();
};

/**
 * Wraps res.json to log any 4xx/5xx sync/push response (auth, device, validation, etc.).
 * Must run early in the middleware chain, before handlers that call res.status().json().
 */
export const logSyncPushResponse = (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction,
) => {
  if (!isSyncPushRequest(req)) return next();

  const originalJson = res.json.bind(res);
  const originalStatus = res.status.bind(res);
  let statusCode = res.statusCode || 200;

  res.status = function status(code: number) {
    statusCode = code;
    return originalStatus(code);
  };

  res.json = function json(body: unknown) {
    if (statusCode >= 400) {
      const payload = body as { error?: string; message?: string; details?: unknown };
      syncPushLogger.warn('sync push rejected', {
        requestId: req.requestId,
        status: statusCode,
        error: payload.error ?? payload.message ?? 'Unknown error',
        details: payload.details,
        depotId: req.depotId ?? null,
        agentId: req.agentId ?? null,
        deviceId: req.deviceId ?? null,
        hasAuthHeader: Boolean(req.headers.authorization),
        hasDeviceToken: Boolean(req.headers['x-device-token']),
        summary: req.body ? summarizePayload(req.body as Record<string, unknown>) : null,
      });
    }
    return originalJson(body);
  };

  next();
};

/** Logs the sync/push body after agent auth and depot scope, before device validation. */
export const logSyncPushRequest = (
  req: AuthenticatedRequest,
  _res: Response,
  next: NextFunction,
) => {
  if (!isSyncPushRequest(req)) return next();

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

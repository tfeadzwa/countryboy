/** Mobile sends heartbeats about every 30s while the conductor is signed in online. */
export const HEARTBEAT_INTERVAL_MS = 30_000;

/**
 * Treat a conductor as online when last_seen is within this window.
 * ~3 missed heartbeats before flipping to offline.
 */
export const ONLINE_THRESHOLD_MS = 90_000;

export const isRecentlyActive = (
  lastSeen: Date | string | null | undefined,
  now: Date = new Date(),
  thresholdMs: number = ONLINE_THRESHOLD_MS,
): boolean => {
  if (!lastSeen) return false;
  const lastSeenAt = lastSeen instanceof Date ? lastSeen : new Date(lastSeen);
  if (Number.isNaN(lastSeenAt.getTime())) return false;
  return now.getTime() - lastSeenAt.getTime() <= thresholdMs;
};

export const isDeviceOnline = (params: {
  paired: boolean;
  lastSeen: Date | string | null | undefined;
  hasOpenSession: boolean;
  now?: Date;
}): boolean => {
  if (!params.paired || !params.hasOpenSession) return false;
  return isRecentlyActive(params.lastSeen, params.now);
};

export const isAdminOnline = (params: {
  status?: string | null;
  lastSeenAt: Date | string | null | undefined;
  now?: Date;
}): boolean => {
  if (params.status && params.status !== 'ACTIVE') return false;
  return isRecentlyActive(params.lastSeenAt, params.now);
};

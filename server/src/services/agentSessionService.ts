import prisma from '../utils/prisma';

export type SessionEndReason =
  | 'logout'
  | 'new_login'
  | 'unpair'
  | 'token_expired';

const agentSelect = {
  id: true,
  full_name: true,
  agent_code: true,
} as const;

export const mapSession = (session: {
  id: string;
  depot_id: string;
  device_id: string;
  agent_id: string;
  started_at: Date;
  ended_at: Date | null;
  end_reason: string | null;
  app_version: string | null;
  login_type: string;
  agent?: { id: string; full_name: string; agent_code: string };
  device?: { id: string; serial_number: string };
}) => ({
  id: session.id,
  depot_id: session.depot_id,
  device_id: session.device_id,
  agent_id: session.agent_id,
  started_at: session.started_at,
  ended_at: session.ended_at,
  end_reason: session.end_reason,
  app_version: session.app_version,
  login_type: session.login_type,
  agent: session.agent
    ? {
        id: session.agent.id,
        full_name: session.agent.full_name,
        agent_code: session.agent.agent_code,
      }
    : undefined,
  device: session.device
    ? {
        id: session.device.id,
        serial_number: session.device.serial_number,
      }
    : undefined,
});

/**
 * Bump device last_seen (and optionally last_agent_id) without treating it as a new sign-in.
 * Used by sync, trips, and heartbeats.
 */
export const touchDeviceActivity = async (
  deviceId: string,
  agentId?: string,
) => {
  const now = new Date();
  await prisma.tblDevices.update({
    where: { id: deviceId },
    data: {
      last_seen: now,
      ...(agentId ? { last_agent_id: agentId } : {}),
    },
  });
};

const cleanPrinterField = (value: unknown): string | null | undefined => {
  if (value === undefined) return undefined;
  if (value === null) return null;
  if (typeof value !== 'string') return undefined;
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
};

/** Heartbeat from a signed-in conductor — refreshes presence and optional printer identity. */
export const recordAgentHeartbeat = async (params: {
  deviceId: string;
  agentId: string;
  printerName?: string | null;
  printerMac?: string | null;
  printerSerial?: string | null;
}) => {
  const { deviceId, agentId } = params;
  const openSession = await prisma.tblAgentDeviceSessions.findFirst({
    where: {
      device_id: deviceId,
      agent_id: agentId,
      ended_at: null,
    },
    orderBy: { started_at: 'desc' },
  });

  if (!openSession) {
    return { ok: false as const, reason: 'no_active_session' as const };
  }

  const printerName = cleanPrinterField(params.printerName);
  const printerMac = cleanPrinterField(params.printerMac);
  const printerSerial = cleanPrinterField(params.printerSerial);
  const hasPrinterUpdate =
    printerName !== undefined ||
    printerMac !== undefined ||
    printerSerial !== undefined;

  const now = new Date();
  await prisma.tblDevices.update({
    where: { id: deviceId },
    data: {
      last_seen: now,
      last_agent_id: agentId,
      ...(hasPrinterUpdate
        ? {
            ...(printerName !== undefined ? { printer_name: printerName } : {}),
            ...(printerMac !== undefined ? { printer_mac: printerMac } : {}),
            ...(printerSerial !== undefined
              ? { printer_serial: printerSerial }
              : {}),
          }
        : {}),
    },
  });

  return {
    ok: true as const,
    last_seen: now.toISOString(),
    session_id: openSession.id,
  };
};

export const closeOpenSessionsForDevice = async (
  deviceId: string,
  endReason: SessionEndReason,
  agentId?: string,
) => {
  const now = new Date();
  await prisma.tblAgentDeviceSessions.updateMany({
    where: {
      device_id: deviceId,
      ended_at: null,
      ...(agentId ? { agent_id: agentId } : {}),
    },
    data: {
      ended_at: now,
      end_reason: endReason,
    },
  });
};

export const startAgentDeviceSession = async (params: {
  deviceId: string;
  agentId: string;
  depotId: string;
  loginType?: 'online' | 'offline';
  appVersion?: string;
}) => {
  const { deviceId, agentId, depotId, loginType = 'online', appVersion } =
    params;
  const now = new Date();

  return prisma.$transaction(async (tx) => {
    await tx.tblAgentDeviceSessions.updateMany({
      where: { device_id: deviceId, ended_at: null },
      data: { ended_at: now, end_reason: 'new_login' },
    });

    const session = await tx.tblAgentDeviceSessions.create({
      data: {
        depot_id: depotId,
        device_id: deviceId,
        agent_id: agentId,
        login_type: loginType,
        app_version: appVersion,
      },
      include: { agent: { select: agentSelect } },
    });

    await tx.tblDevices.update({
      where: { id: deviceId },
      data: {
        last_agent_id: agentId,
        last_agent_login_at: now,
        last_seen: now,
        ...(appVersion ? { app_version: appVersion } : {}),
      },
    });

    return mapSession(session);
  });
};

export const endAgentDeviceSession = async (params: {
  deviceId: string;
  agentId: string;
  endReason?: SessionEndReason;
}) => {
  const { deviceId, agentId, endReason = 'logout' } = params;
  await closeOpenSessionsForDevice(deviceId, endReason, agentId);
};

export const closeAllSessionsForDevice = async (
  deviceId: string,
  endReason: SessionEndReason = 'unpair',
) => {
  await closeOpenSessionsForDevice(deviceId, endReason);
};

export const getActiveSessionForDevice = async (deviceId: string) => {
  const session = await prisma.tblAgentDeviceSessions.findFirst({
    where: { device_id: deviceId, ended_at: null },
    orderBy: { started_at: 'desc' },
    include: {
      agent: { select: agentSelect },
    },
  });
  return session ? mapSession(session) : null;
};

export const listDeviceSessions = async (
  deviceId: string,
  limit = 20,
) => {
  const sessions = await prisma.tblAgentDeviceSessions.findMany({
    where: { device_id: deviceId },
    orderBy: { started_at: 'desc' },
    take: limit,
    include: {
      agent: { select: agentSelect },
    },
  });
  return sessions.map(mapSession);
};

/**
 * Close any open sessions still hanging on an unpaired device (data heal).
 * Unpair should already do this; this covers stale rows from older data / manual edits.
 */
export const ensureNoOpenSessionsIfUnpaired = async (
  deviceId: string,
  paired: boolean,
) => {
  if (paired) return;
  await closeOpenSessionsForDevice(deviceId, 'unpair');
};

export const listAgentSessions = async (agentId: string, limit = 20) => {
  const sessions = await prisma.tblAgentDeviceSessions.findMany({
    where: { agent_id: agentId },
    orderBy: { started_at: 'desc' },
    take: limit,
    include: {
      device: { select: { id: true, serial_number: true } },
    },
  });
  return sessions.map(mapSession);
};

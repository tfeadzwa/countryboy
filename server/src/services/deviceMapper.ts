const agentSummary = (agent?: {
  id: string;
  full_name: string;
  agent_code: string;
} | null) =>
  agent
    ? {
        id: agent.id,
        full_name: agent.full_name,
        agent_code: agent.agent_code,
      }
    : null;

export const mapDeviceRecord = (
  device: {
    id: string;
    serial_number: string;
    token?: string | null;
    pairing_code?: string | null;
    paired: boolean;
    paired_at: Date | null;
    depot_id: string;
    device_name?: string | null;
    device_model?: string | null;
    last_seen: Date | null;
    last_agent_id?: string | null;
    last_agent_login_at?: Date | null;
    app_version?: string | null;
    sync_errors: number;
    created_at: Date;
    updated_at: Date;
    created_by?: string | null;
    updated_by?: string | null;
    depot?: { name: string } | null;
    lastAgent?: {
      id: string;
      full_name: string;
      agent_code: string;
    } | null;
    agentDeviceSessions?: Array<{
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
    }>;
  },
  options?: { includeToken?: boolean },
) => {
  const openSession = device.agentDeviceSessions?.find((s) => !s.ended_at);

  return {
    id: device.id,
    serial_number: device.serial_number,
    ...(options?.includeToken ? { token: device.token } : {}),
    pairing_code: device.pairing_code,
    paired: device.paired,
    paired_at: device.paired_at,
    depot_id: device.depot_id,
    depot_name: device.depot?.name ?? null,
    device_name: device.device_name,
    device_model: device.device_model,
    last_seen: device.last_seen,
    last_agent_id: device.last_agent_id,
    last_agent_login_at: device.last_agent_login_at,
    last_agent: agentSummary(device.lastAgent),
    active_session: openSession
      ? {
          id: openSession.id,
          started_at: openSession.started_at,
          login_type: openSession.login_type,
          agent: agentSummary(openSession.agent),
        }
      : null,
    app_version: device.app_version,
    sync_errors: device.sync_errors,
    created_at: device.created_at,
    updated_at: device.updated_at,
    created_by: device.created_by,
    updated_by: device.updated_by,
  };
};

export const deviceInclude = {
  depot: { select: { name: true } },
  lastAgent: { select: { id: true, full_name: true, agent_code: true } },
  agentDeviceSessions: {
    where: { ended_at: null },
    orderBy: { started_at: 'desc' as const },
    take: 1,
    include: {
      agent: { select: { id: true, full_name: true, agent_code: true } },
    },
  },
};

import prisma from '../utils/prisma';
import { Prisma } from '@prisma/client';
import { generatePairingCode, generateDeviceToken } from '../utils/tokenGenerator';
import { closeAllSessionsForDevice } from './agentSessionService';
import { deviceInclude, mapDeviceRecord } from './deviceMapper';

const clearUnpairedActivity = {
  last_agent_id: null,
  last_agent_login_at: null,
  last_seen: null,
  paired_at: null,
} as const;

/** Clear leftover activity fields left by older unpair (token kept working). */
const healStaleUnpairedDevice = async <T extends {
  id: string;
  paired: boolean;
  last_agent_id: string | null;
  last_seen: Date | null;
  paired_at: Date | null;
  lastAgent?: unknown;
}>(device: T): Promise<T> => {
  if (
    device.paired ||
    (device.last_agent_id == null && device.last_seen == null && device.paired_at == null)
  ) {
    return device;
  }

  await prisma.tblDevices.update({
    where: { id: device.id },
    data: clearUnpairedActivity,
  });

  return {
    ...device,
    ...clearUnpairedActivity,
    lastAgent: null,
  };
};

export const listDevices = async (depotId?: string) => {
  const where: Prisma.tblDevicesWhereInput = {};
  if (depotId) where.depot_id = depotId;

  const devices = await prisma.tblDevices.findMany({
    where,
    include: deviceInclude,
    orderBy: { serial_number: 'asc' },
  });

  const staleIds = devices
    .filter(
      (d) =>
        !d.paired &&
        (d.last_agent_id != null || d.last_seen != null || d.paired_at != null),
    )
    .map((d) => d.id);

  if (staleIds.length > 0) {
    await prisma.tblDevices.updateMany({
      where: { id: { in: staleIds } },
      data: clearUnpairedActivity,
    });
  }

  return devices.map((device) =>
    mapDeviceRecord(
      staleIds.includes(device.id)
        ? {
            ...device,
            ...clearUnpairedActivity,
            lastAgent: null,
          }
        : device,
    ),
  );
};

export const createDevice = async (depotId: string, data: { serial_number: string }, createdBy?: string) => {
  const token = generateDeviceToken();
  const pairing_code = generatePairingCode();

  const device = await prisma.tblDevices.create({
    data: {
      ...data,
      depot_id: depotId,
      token,
      pairing_code,
      paired: false,
      created_by: createdBy,
    },
    include: deviceInclude,
  });

  return mapDeviceRecord(device, { includeToken: true });
};

export const pairDevice = async (pairingCode: string, deviceInfo?: { device_name?: string; device_model?: string; app_version?: string }) => {
  const device = await prisma.tblDevices.findUnique({
    where: { pairing_code: pairingCode.toUpperCase().replace('-', '') },
    include: { depot: true },
  });

  if (!device) {
    throw new Error('Invalid pairing code');
  }

  if (device.paired) {
    throw new Error('Device already paired');
  }

  const updated = await prisma.tblDevices.update({
    where: { id: device.id },
    data: {
      paired: true,
      paired_at: new Date(),
      last_seen: new Date(),
      pairing_code: null,
      device_name: deviceInfo?.device_name,
      device_model: deviceInfo?.device_model,
      app_version: deviceInfo?.app_version,
    },
  });

  return {
    device_id: updated.id,
    device_token: updated.token,
    depot_id: updated.depot_id,
    depot_name: device.depot.name,
    serial_number: updated.serial_number,
    merchant_code: device.depot.merchant_code,
    message: 'Device paired successfully',
  };
};

export const updateDevice = async (
  id: string,
  data: Partial<{
    serial_number: string;
    depot_id: string;
    last_seen: Date;
    app_version: string;
    sync_errors: number;
  }>,
  updatedBy?: string,
) => {
  const existing = await prisma.tblDevices.findUnique({ where: { id } });
  if (!existing) {
    throw new Error('Device not found');
  }

  if (data.depot_id && data.depot_id !== existing.depot_id) {
    if (existing.paired) {
      throw new Error(
        'Unpair the device before moving it to another depot.',
      );
    }
    const depot = await prisma.tblDepots.findUnique({
      where: { id: data.depot_id },
    });
    if (!depot) {
      throw new Error('Depot not found');
    }
  }

  const device = await prisma.tblDevices.update({
    where: { id },
    data: {
      ...(data.serial_number !== undefined
        ? { serial_number: data.serial_number.trim() }
        : {}),
      ...(data.depot_id !== undefined ? { depot_id: data.depot_id } : {}),
      ...(data.last_seen !== undefined ? { last_seen: data.last_seen } : {}),
      ...(data.app_version !== undefined ? { app_version: data.app_version } : {}),
      ...(data.sync_errors !== undefined ? { sync_errors: data.sync_errors } : {}),
      updated_by: updatedBy,
    },
    include: deviceInclude,
  });
  return mapDeviceRecord(device);
};

export const deleteDevice = async (id: string) => {
  const device = await prisma.tblDevices.findUnique({
    where: { id },
    include: {
      _count: {
        select: {
          tickets: true,
          trips: true,
          serialRanges: true,
          voids: true,
        },
      },
    },
  });

  if (!device) {
    throw new Error('Device not found');
  }

  if (device.paired) {
    throw new Error('Unpair the device before deleting it.');
  }

  const usage =
    device._count.tickets +
    device._count.trips +
    device._count.serialRanges +
    device._count.voids;

  if (usage > 0) {
    throw new Error(
      'Cannot delete this device because it has ticket or trip history. Keep it unpaired instead.',
    );
  }

  await prisma.$transaction(async (tx) => {
    await tx.tblAgentDeviceSessions.deleteMany({ where: { device_id: id } });
    await tx.tblDevices.delete({ where: { id } });
  });

  return {
    id: device.id,
    serial_number: device.serial_number,
    message: 'Device deleted successfully.',
  };
};

export const getDevice = async (id: string) => {
  const device = await prisma.tblDevices.findUnique({
    where: { id },
    include: deviceInclude,
  });
  if (!device) return null;
  const healed = await healStaleUnpairedDevice(device);
  return mapDeviceRecord(healed);
};

export const unpairDevice = async (id: string) => {
  const device = await prisma.tblDevices.findUnique({ where: { id } });

  if (!device) {
    throw new Error('Device not found');
  }

  await closeAllSessionsForDevice(id, 'unpair');

  const newPairingCode = generatePairingCode();
  // Rotate token so the previously paired phone can no longer authenticate.
  const newToken = generateDeviceToken();

  const updated = await prisma.tblDevices.update({
    where: { id },
    data: {
      paired: false,
      paired_at: null,
      pairing_code: newPairingCode,
      token: newToken,
      device_name: null,
      device_model: null,
      app_version: null,
      last_seen: null,
      last_agent_id: null,
      last_agent_login_at: null,
    },
  });

  return {
    id: updated.id,
    serial_number: updated.serial_number,
    pairing_code: newPairingCode,
    message: 'Device unpaired successfully. Use the new pairing code to re-pair.',
  };
};

/**
 * Regenerate pairing code for an unpaired device without a full unpair reset.
 * Invalidates the previous code so a forgotten/leaked code can be replaced safely.
 */
export const regeneratePairingCode = async (id: string) => {
  const device = await prisma.tblDevices.findUnique({ where: { id } });

  if (!device) {
    throw new Error('Device not found');
  }

  if (device.paired) {
    throw new Error(
      'Device is already paired. Unpair it first to generate a new pairing code.',
    );
  }

  const newPairingCode = generatePairingCode();

  const updated = await prisma.tblDevices.update({
    where: { id },
    data: { pairing_code: newPairingCode },
  });

  return {
    id: updated.id,
    serial_number: updated.serial_number,
    pairing_code: newPairingCode,
    message: 'New pairing code generated. The previous code no longer works.',
  };
};

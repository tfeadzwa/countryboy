import prisma from '../utils/prisma';
import { Prisma } from '@prisma/client';
import { generatePairingCode, generateDeviceToken } from '../utils/tokenGenerator';

export const listDevices = async (depotId?: string) => {
  const where: Prisma.tblDevicesWhereInput = {};
  if (depotId) where.depot_id = depotId;
  return prisma.tblDevices.findMany({ where });
};

export const createDevice = async (depotId: string, data: { serial_number: string }, createdBy?: string) => {
  const token = generateDeviceToken();        // Long UUID for API auth
  const pairing_code = generatePairingCode(); // Short 6-char code for setup
  
  return prisma.tblDevices.create({
    data: { 
      ...data, 
      depot_id: depotId, 
      token,
      pairing_code,
      paired: false, // Not paired until conductor completes setup
      created_by: createdBy
    }
  });
};

export const pairDevice = async (pairingCode: string, deviceInfo?: { device_name?: string; device_model?: string; app_version?: string }) => {
  // Find device by pairing code
  const device = await prisma.tblDevices.findUnique({
    where: { pairing_code: pairingCode.toUpperCase().replace('-', '') },
    include: { depot: true }
  });

  if (!device) {
    throw new Error('Invalid pairing code');
  }

  if (device.paired) {
    throw new Error('Device already paired');
  }

  // Mark as paired and save device info
  const updated = await prisma.tblDevices.update({
    where: { id: device.id },
    data: { 
      paired: true,
      paired_at: new Date(),
      last_seen: new Date(),
      device_name: deviceInfo?.device_name,
      device_model: deviceInfo?.device_model,
      app_version: deviceInfo?.app_version
    }
  });

  return {
    device_id: updated.id,
    device_token: updated.token,
    depot_id: updated.depot_id,
    serial_number: updated.serial_number,
    merchant_code: device.depot.merchant_code,
    message: 'Device paired successfully'
  };
};

export const updateDevice = async (id: string, data: Partial<{ last_seen: Date; app_version: string; sync_errors: number; }>, updatedBy?: string) => {
  return prisma.tblDevices.update({ where: { id }, data: { ...data, updated_by: updatedBy } });
};

export const getDevice = async (id: string) => {
  return prisma.tblDevices.findUnique({ where: { id } });
};

export const unpairDevice = async (id: string) => {
  // Check if device exists
  const device = await prisma.tblDevices.findUnique({ where: { id } });
  
  if (!device) {
    throw new Error('Device not found');
  }

  // Generate new pairing code
  const newPairingCode = generatePairingCode();

  // Reset device to unpaired state with new pairing code
  const updated = await prisma.tblDevices.update({
    where: { id },
    data: {
      paired: false,
      paired_at: null,
      pairing_code: newPairingCode,
      device_name: null,
      device_model: null,
      app_version: null,
      last_seen: null,
    }
  });

  return {
    id: updated.id,
    serial_number: updated.serial_number,
    pairing_code: newPairingCode,
    message: 'Device unpaired successfully. Use the new pairing code to re-pair.'
  };
};

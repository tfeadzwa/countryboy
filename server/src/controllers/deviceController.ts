import { AuthenticatedRequest } from '../middleware/auth';
import { Request, Response } from 'express';
import * as deviceService from '../services/deviceService';
import { formatPrismaError } from '../utils/prismaErrors';

export const list = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const depotId = req.depotId;
    const devices = await deviceService.listDevices(depotId);
    res.json(devices);
  } catch (err) {
    res.status(500).json({ error: 'Unable to list devices', details: err });
  }
};

export const create = async (req: AuthenticatedRequest, res: Response) => {
  const depotId = req.depotId as string;
  const { serial_number } = req.body;

  if (!depotId) {
    return res.status(400).json({
      error: 'Cannot register device: depot context is missing for this user.'
    });
  }

  try {
    const device = await deviceService.createDevice(depotId, { serial_number }, req.user?.id);
    res.status(201).json(device);
  } catch (err) {
    const friendly = formatPrismaError(err, { serial_number });
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(400).json({ error: 'Could not create device', details: err });
  }
};

export const update = async (req: AuthenticatedRequest, res: Response) => {
  const id = req.params.id;
  const data = req.body;

  try {
    const updated = await deviceService.updateDevice(id, data, req.user?.id);
    res.json(updated);
  } catch (err) {
    const friendly = formatPrismaError(err, data as Record<string, any>);
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(400).json({ error: 'Could not update device', details: err });
  }
};

export const getOne = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const id = req.params.id;
    const device = await deviceService.getDevice(id);
    if (!device) return res.status(404).json({ error: 'Device not found' });
    res.json(device);
  } catch (err) {
    res.status(500).json({ error: 'Error fetching device', details: err });
  }
};

/**
 * Pair a device using its pairing code
 * This is called once by the mobile app during initial setup
 * Returns the long device token that will be stored in the app
 */
export const pair = async (req: Request, res: Response) => {
  try {
    const { pairing_code, device_name, device_model, app_version } = req.body;
    
    if (!pairing_code) {
      return res.status(400).json({ error: 'Pairing code is required' });
    }

    const result = await deviceService.pairDevice(pairing_code, {
      device_name,
      device_model,
      app_version
    });
    res.json(result);
  } catch (err: any) {
    if (err.message === 'Invalid pairing code') {
      return res.status(404).json({ error: 'Invalid pairing code' });
    }
    if (err.message === 'Device already paired') {
      return res.status(409).json({ error: 'Device already paired' });
    }
    res.status(500).json({ error: 'Failed to pair device', details: err });
  }
};

/**
 * Unpair a device (admin only)
 * Resets the device to unpaired state and generates a new pairing code
 * Used when device needs to be re-paired (app reinstalled, device lost/recovered, etc.)
 */
export const unpair = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const id = req.params.id;
    const result = await deviceService.unpairDevice(id);
    res.json(result);
  } catch (err: any) {
    if (err.message === 'Device not found') {
      return res.status(404).json({ error: 'Device not found' });
    }
    res.status(500).json({ error: 'Failed to unpair device', details: err });
  }
};

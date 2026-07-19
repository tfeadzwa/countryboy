import { AuthenticatedRequest } from '../middleware/auth';
import { Request, Response } from 'express';
import * as deviceService from '../services/deviceService';
import { formatPrismaError } from '../utils/prismaErrors';
import { listDeviceSessions, ensureNoOpenSessionsIfUnpaired } from '../services/agentSessionService';
import { isSuperAdmin } from '../middleware/rbac';

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
  const { serial_number, depot_id, last_seen, app_version, sync_errors } = req.body;

  try {
    const existing = await deviceService.getDevice(id);
    if (!existing) {
      return res.status(404).json({ error: 'Device not found' });
    }
    if (req.depotId && existing.depot_id !== req.depotId) {
      return res.status(403).json({ error: 'Device not in your depot' });
    }

    // Depot admins cannot move devices to another depot (super admins can).
    if (!isSuperAdmin(req) && depot_id && req.depotId && depot_id !== req.depotId) {
      return res.status(403).json({ error: 'You can only keep devices in your own depot' });
    }

    const updated = await deviceService.updateDevice(
      id,
      {
        ...(serial_number !== undefined ? { serial_number } : {}),
        ...(depot_id !== undefined ? { depot_id } : {}),
        ...(last_seen !== undefined ? { last_seen } : {}),
        ...(app_version !== undefined ? { app_version } : {}),
        ...(sync_errors !== undefined ? { sync_errors } : {}),
      },
      req.user?.id,
    );
    res.json(updated);
  } catch (err: any) {
    if (err.message === 'Device not found' || err.message === 'Depot not found') {
      return res.status(404).json({ error: err.message });
    }
    if (err.message?.includes('Unpair the device')) {
      return res.status(409).json({ error: err.message });
    }
    const friendly = formatPrismaError(err, req.body as Record<string, any>);
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(400).json({ error: 'Could not update device', details: err });
  }
};

export const remove = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const id = req.params.id;
    const existing = await deviceService.getDevice(id);
    if (!existing) {
      return res.status(404).json({ error: 'Device not found' });
    }
    if (req.depotId && existing.depot_id !== req.depotId) {
      return res.status(403).json({ error: 'Device not in your depot' });
    }

    const result = await deviceService.deleteDevice(id);
    res.json(result);
  } catch (err: any) {
    if (err.message === 'Device not found') {
      return res.status(404).json({ error: err.message });
    }
    if (
      err.message?.includes('Unpair the device') ||
      err.message?.includes('Cannot delete')
    ) {
      return res.status(409).json({ error: err.message });
    }
    const friendly = formatPrismaError(err);
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(500).json({ error: 'Failed to delete device', details: err });
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
      return res.status(409).json({
        error:
          'This pairing code has already been used. Ask your depot admin to unpair the device or regenerate a new pairing code.',
      });
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

/**
 * Regenerate pairing code for an unpaired device (admin only).
 * Does not wipe device metadata beyond rotating the code.
 */
export const regeneratePairingCode = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const id = req.params.id;
    const result = await deviceService.regeneratePairingCode(id);
    res.json(result);
  } catch (err: any) {
    if (err.message === 'Device not found') {
      return res.status(404).json({ error: 'Device not found' });
    }
    if (err.message?.includes('already paired')) {
      return res.status(409).json({ error: err.message });
    }
    res.status(500).json({ error: 'Failed to regenerate pairing code', details: err });
  }
};

export const sessions = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const id = req.params.id;
    const limit = Math.min(Number(req.query.limit) || 20, 100);
    const device = await deviceService.getDevice(id);
    if (!device) {
      return res.status(404).json({ error: 'Device not found' });
    }
    if (req.depotId && device.depot_id !== req.depotId) {
      return res.status(403).json({ error: 'Device not in your depot' });
    }
    // Unpaired devices must not keep "active" sessions; heal any stale open rows.
    await ensureNoOpenSessionsIfUnpaired(id, device.paired);
    const sessions = await listDeviceSessions(id, limit);
    res.json({ device_id: id, sessions });
  } catch (err) {
    res.status(500).json({ error: 'Unable to list device sessions', details: err });
  }
};

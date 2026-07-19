import { Request, Response, NextFunction } from 'express';
import prisma from '../utils/prisma';
import { syncPushLogger } from '../utils/logger';
import { isSyncPushRequest } from './logSyncPush';

export const deviceAuthMiddleware = async (req: Request & { deviceId?: string; depotId?: string; requestId?: string }, res: Response, next: NextFunction) => {
  const token = req.headers['x-device-token'] as string;
  if (!token) {
    return res.status(401).json({ error: 'Device token missing' });
  }

  const device = await prisma.tblDevices.findUnique({ where: { token } });
  if (!device) {
    return res.status(401).json({ error: 'Invalid device token' });
  }

  if (!device.paired) {
    return res.status(401).json({
      error: 'Device is unpaired. Pair this device again with a new pairing code.',
    });
  }

  req.deviceId = device.id;
  if (req.depotId && device.depot_id !== req.depotId) {
    if (isSyncPushRequest(req)) {
      syncPushLogger.warn('sync push device depot mismatch', {
        requestId: req.requestId,
        status: 403,
        error: 'Device not allowed for this depot',
        agentDepotId: req.depotId,
        deviceDepotId: device.depot_id,
        deviceId: device.id,
        agentId: (req as Request & { agentId?: string }).agentId ?? null,
      });
    }
    return res.status(403).json({ error: 'Device not allowed for this depot' });
  }

  next();
};

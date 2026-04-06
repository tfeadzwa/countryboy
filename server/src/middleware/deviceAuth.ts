import { Request, Response, NextFunction } from 'express';
import prisma from '../utils/prisma';

export const deviceAuthMiddleware = async (req: Request & { deviceId?: string; depotId?: string }, res: Response, next: NextFunction) => {
  const token = req.headers['x-device-token'] as string;
  if (!token) return res.status(401).json({ error: 'Device token missing' });

  const device = await prisma.tblDevices.findUnique({ where: { token } });
  if (!device) return res.status(401).json({ error: 'Invalid device token' });

  req.deviceId = device.id;
  // optionally check depot consistency with req.depotId if available
  if (req.depotId && device.depot_id !== req.depotId) {
    return res.status(403).json({ error: 'Device not allowed for this depot' });
  }

  next();
};

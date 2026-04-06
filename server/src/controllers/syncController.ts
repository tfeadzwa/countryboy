import { Request, Response } from 'express';
import { pushData, pullData } from '../services/syncService';
import { AuthenticatedRequest } from '@/middleware/auth';
import { formatPrismaError } from '../utils/prismaErrors';

export const push = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const depotId = req.depotId as string;
    const payload = req.body;
    const result = await pushData(depotId, payload);
    res.json(result);
  } catch (err) {
    const friendly = formatPrismaError(err);
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(500).json({ error: 'Sync push failed', details: err });
  }
};

export const pull = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const depotId = req.depotId as string;
    const since = req.query.since as string | undefined;
    const data = await pullData(depotId, since);
    res.json(data);
  } catch (err) {
    const friendly = formatPrismaError(err);
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(500).json({ error: 'Sync pull failed', details: err });
  }
};

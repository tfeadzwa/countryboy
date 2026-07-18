import { Request, Response } from 'express';
import { pushData, pullData } from '../services/syncService';
import { AuthenticatedRequest } from '@/middleware/auth';
import { formatPrismaError } from '../utils/prismaErrors';
import { syncPushLogger } from '../utils/logger';

export const push = async (req: AuthenticatedRequest, res: Response) => {
  const depotId = req.depotId as string;
  const payload = req.body;

  try {
    syncPushLogger.debug('sync push processing', {
      requestId: req.requestId,
      depotId,
      payload,
    });

    const result = await pushData(depotId, payload, {
      agentId: req.agentId,
      deviceId: req.deviceId,
    });

    syncPushLogger.info('sync push succeeded', {
      requestId: req.requestId,
      depotId,
      tripsSynced: result.trips?.length ?? 0,
      ticketsSynced: result.tickets?.length ?? 0,
    });

    res.json(result);
  } catch (err) {
    syncPushLogger.error('sync push failed', {
      requestId: req.requestId,
      depotId,
      payload,
      error: err instanceof Error ? err.message : String(err),
      stack: err instanceof Error ? err.stack : undefined,
    });

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
    const data = await pullData(depotId, since, {
      agentId: req.agentId,
      deviceId: req.deviceId,
    });
    res.json(data);
  } catch (err) {
    const friendly = formatPrismaError(err);
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(500).json({ error: 'Sync pull failed', details: err });
  }
};

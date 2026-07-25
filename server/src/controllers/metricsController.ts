import { Request, Response } from 'express';
import { 
  getOverview, 
  getRevenueTimeseries,
  getRevenueByCurrency,
  getAgentPerformance,
  getFleetUtilization,
  getRoutePerformance,
  getVoidRate,
  getDepotComparison
} from '../services/metricsService';
import { AuthenticatedRequest } from '@/middleware/auth';
import { formatPrismaError } from '../utils/prismaErrors';

const parseDayStart = (value?: string) => {
  if (!value) return undefined;
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return undefined;
  return new Date(d.getFullYear(), d.getMonth(), d.getDate());
};

const parseDayEnd = (value?: string) => {
  if (!value) return undefined;
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return undefined;
  return new Date(d.getFullYear(), d.getMonth(), d.getDate(), 23, 59, 59, 999);
};

export const overview = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const depotId = req.depotId as string | undefined;
    const result = await getOverview(depotId);
    res.json(result);
  } catch (err) {
    const friendly = formatPrismaError(err);
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(500).json({ error: 'Could not fetch overview', details: err });
  }
};

export const revenueTimeseries = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const depotId = req.depotId as string | undefined;
    const from = parseDayStart(req.query.from as string | undefined);
    const to = parseDayEnd(req.query.to as string | undefined);
    const data = await getRevenueTimeseries(depotId, from, to);
    res.json(data);
  } catch (err) {
    const friendly = formatPrismaError(err);
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(500).json({ error: 'Unable to load timeseries', details: err });
  }
};

export const revenueByCurrency = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const depotId = req.depotId as string | undefined;
    const from = parseDayStart(req.query.from as string | undefined);
    const to = parseDayEnd(req.query.to as string | undefined);
    const data = await getRevenueByCurrency(depotId, from, to);
    res.json(data);
  } catch (err) {
    const friendly = formatPrismaError(err);
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(500).json({ error: 'Could not fetch revenue by currency', details: err });
  }
};

export const agentPerformance = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const depotId = req.depotId as string | undefined;
    const from = parseDayStart(req.query.from as string | undefined);
    const to = parseDayEnd(req.query.to as string | undefined);
    const limit = req.query.limit ? parseInt(req.query.limit as string) : undefined;
    const data = await getAgentPerformance(depotId, from, to, limit);
    res.json(data);
  } catch (err) {
    const friendly = formatPrismaError(err);
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(500).json({ error: 'Could not fetch agent performance', details: err });
  }
};

export const fleetUtilization = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const depotId = req.depotId as string | undefined;
    const data = await getFleetUtilization(depotId);
    res.json(data);
  } catch (err) {
    const friendly = formatPrismaError(err);
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(500).json({ error: 'Could not fetch fleet utilization', details: err });
  }
};

export const routePerformance = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const depotId = req.depotId as string | undefined;
    const from = parseDayStart(req.query.from as string | undefined);
    const to = parseDayEnd(req.query.to as string | undefined);
    const limit = req.query.limit ? parseInt(req.query.limit as string) : undefined;
    const data = await getRoutePerformance(depotId, from, to, limit);
    res.json(data);
  } catch (err) {
    const friendly = formatPrismaError(err);
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(500).json({ error: 'Could not fetch route performance', details: err });
  }
};

export const voidRate = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const depotId = req.depotId as string | undefined;
    const from = parseDayStart(req.query.from as string | undefined);
    const to = parseDayEnd(req.query.to as string | undefined);
    const data = await getVoidRate(depotId, from, to);
    res.json(data);
  } catch (err) {
    const friendly = formatPrismaError(err);
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(500).json({ error: 'Could not fetch void rate', details: err });
  }
};

export const depotComparison = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const data = await getDepotComparison();
    res.json(data);
  } catch (err) {
    const friendly = formatPrismaError(err);
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(500).json({ error: 'Could not fetch depot comparison', details: err });
  }
};

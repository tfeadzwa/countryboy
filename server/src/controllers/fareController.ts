import { AuthenticatedRequest } from '../middleware/auth';
import { Request, Response } from 'express';
import * as fareService from '../services/fareService';
import { formatPrismaError } from '../utils/prismaErrors';

export const list = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const fares = await fareService.listFares(req.depotId);
    const formatted = fares.map(f => ({
      ...f,
      depot_name: f.depot.name,
      route_label: `${f.route.origin} → ${f.route.destination}`
    }));
    res.json(formatted);
  } catch (err) {
    res.status(500).json({ error: 'Unable to list fares', details: err });
  }
};

export const create = async (req: AuthenticatedRequest, res: Response) => {
  const depotId = req.depotId as string;
  const { route_id, currency, amount } = req.body;

  if (!depotId) {
    return res.status(400).json({
      error: 'Depot context missing. Use a depot-scoped account or assign a depot to this user before creating fares.'
    });
  }

  try {
    const fare = await fareService.createFare(depotId, { route_id, currency, amount }, req.user?.id);
    const formatted = {
      ...fare,
      depot_name: fare.depot.name,
      route_label: `${fare.route.origin} → ${fare.route.destination}`
    };
    res.status(201).json(formatted);
  } catch (err) {
    const friendly = formatPrismaError(err, { route_id, currency, amount });
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(400).json({ error: 'Could not create fare', details: err });
  }
};

export const update = async (req: AuthenticatedRequest, res: Response) => {
  const id = req.params.id;
  const data = req.body;

  try {
    const updated = await fareService.updateFare(id, data, req.user?.id);
    const formatted = {
      ...updated,
      depot_name: updated.depot.name,
      route_label: `${updated.route.origin} → ${updated.route.destination}`
    };
    res.json(formatted);
  } catch (err) {
    const friendly = formatPrismaError(err, data as Record<string, any>);
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(400).json({ error: 'Could not update fare', details: err });
  }
};

export const getOne = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const id = req.params.id;
    const fare = await fareService.getFare(id);
    if (!fare) return res.status(404).json({ error: 'Fare not found' });
    const formatted = {
      ...fare,
      depot_name: fare.depot.name,
      route_label: `${fare.route.origin} → ${fare.route.destination}`
    };
    res.json(formatted);
  } catch (err) {
    res.status(500).json({ error: 'Error fetching fare', details: err });
  }
};

import { AuthenticatedRequest } from '../middleware/auth';
import { Request, Response } from 'express';
import * as routeService from '../services/routeService';

export const list = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const routes = await routeService.listRoutes(req.depotId);
    const formatted = routes.map(r => ({
      ...r,
      depot_name: r.depot.name
    }));
    res.json(formatted);
  } catch (err) {
    res.status(500).json({ error: 'Unable to list routes', details: err });
  }
};

import { formatPrismaError } from '../utils/prismaErrors';

export const create = async (req: AuthenticatedRequest, res: Response) => {
  const depotId = req.depotId as string;
  const { origin, destination, is_active, distance_km } = req.body;

  if (!depotId) {
    return res.status(400).json({
      error: 'Cannot create route: depot context is missing for this user.'
    });
  }

  try {
    const route = await routeService.createRoute(
      depotId, 
      { origin, destination, is_active, distance_km }, 
      req.user?.id
    );
    const formatted = {
      ...route,
      depot_name: route.depot.name
    };
    res.status(201).json(formatted);
  } catch (err) {
    const friendly = formatPrismaError(err, { origin, destination });
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(400).json({ error: 'Could not create route', details: err });
  }
};

export const update = async (req: AuthenticatedRequest, res: Response) => {
  const id = req.params.id;
  const data = req.body;

  try {
    const updated = await routeService.updateRoute(id, data, req.user?.id);
    const formatted = {
      ...updated,
      depot_name: updated.depot.name
    };
    res.json(formatted);
  } catch (err) {
    const friendly = formatPrismaError(err, data as Record<string, any>);
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(400).json({ error: 'Could not update route', details: err });
  }
};

export const getOne = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const id = req.params.id;
    const route = await routeService.getRoute(id);
    if (!route) return res.status(404).json({ error: 'Route not found' });
    const formatted = {
      ...route,
      depot_name: route.depot.name
    };
    res.json(formatted);
  } catch (err) {
    res.status(500).json({ error: 'Error fetching route', details: err });
  }
};

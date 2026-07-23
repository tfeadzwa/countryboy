import { AuthenticatedRequest } from '../middleware/auth';
import { Response } from 'express';
import * as routeService from '../services/routeService';
import * as tripService from '../services/tripService';
import { formatPrismaError } from '../utils/prismaErrors';
import { buildPaginatedResult, parsePagination, wantsPagination } from '../utils/pagination';

/** Conductor-run corridors derived from trips (read-only admin view). */
export const listCorridors = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const corridors = await tripService.listCorridors(req.depotId);
    res.json(corridors);
  } catch (err) {
    res.status(500).json({ error: 'Unable to list corridors', details: err });
  }
};

export const getCorridor = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const detail = await tripService.getCorridorDetail(req.params.id, req.depotId);
    if (!detail) {
      return res.status(404).json({ error: 'Route corridor not found' });
    }
    res.json(detail);
  } catch (err) {
    res.status(500).json({ error: 'Unable to load corridor detail', details: err });
  }
};

export const list = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const query = req.query as { page?: string; limit?: string };

    if (wantsPagination(query)) {
      const { page, limit, skip } = parsePagination(query);
      const [routes, total] = await Promise.all([
        routeService.listRoutes(req.depotId, { skip, limit }),
        routeService.countRoutes(req.depotId),
      ]);
      return res.json(buildPaginatedResult(routes, total, page, limit));
    }

    const routes = await routeService.listRoutes(req.depotId);
    res.json(routes);
  } catch (err) {
    res.status(500).json({ error: 'Unable to list routes', details: err });
  }
};

export const create = async (req: AuthenticatedRequest, res: Response) => {
  const depotId = req.depotId as string;
  const {
    origin,
    destination,
    parent_route_ids,
    parent_route_id,
    child_route_ids,
    is_active,
    distance_km,
  } = req.body;

  if (!depotId) {
    return res.status(400).json({
      error: 'Cannot create route: depot context is missing for this user.',
    });
  }

  try {
    const route = await routeService.createRoute(
      depotId,
      {
        origin,
        destination,
        parent_route_ids,
        parent_route_id,
        child_route_ids,
        is_active,
        distance_km,
      },
      req.user?.id,
    );
    res.status(201).json(route);
  } catch (err) {
    if (
      err instanceof Error &&
      (err.message.includes('parent routes') ||
        err.message.includes('child routes') ||
        err.message.includes('both parent and child') ||
        err.message.includes('cycle') ||
        err.message.includes('itself'))
    ) {
      return res.status(400).json({ error: err.message });
    }
    const friendly = formatPrismaError(err, {
      origin,
      destination,
      parent_route_ids,
      parent_route_id,
    });
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
    res.json(updated);
  } catch (err) {
    if (
      err instanceof Error &&
      (err.message.includes('parent routes') ||
        err.message.includes('child routes') ||
        err.message.includes('both parent and child') ||
        err.message.includes('cycle') ||
        err.message.includes('itself') ||
        err.message.includes('not found'))
    ) {
      return res.status(400).json({ error: err.message });
    }
    const friendly = formatPrismaError(err, data as Record<string, unknown>);
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(400).json({ error: 'Could not update route', details: err });
  }
};

export const remove = async (req: AuthenticatedRequest, res: Response) => {
  const id = req.params.id;

  try {
    await routeService.deleteRoute(id, req.depotId);
    res.json({ message: 'Route deleted successfully' });
  } catch (err) {
    if (err instanceof Error) {
      if (err.message === 'Route not found') {
        return res.status(404).json({ error: err.message });
      }
      if (err.message.includes('Cannot delete')) {
        return res.status(409).json({ error: err.message });
      }
    }
    const friendly = formatPrismaError(err);
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(400).json({ error: 'Could not delete route', details: err });
  }
};

export const getOne = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const id = req.params.id;
    const route = await routeService.getRoute(id);
    if (!route) return res.status(404).json({ error: 'Route not found' });
    res.json(route);
  } catch (err) {
    res.status(500).json({ error: 'Error fetching route', details: err });
  }
};

export const listChildren = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const id = req.params.id;
    const children = await routeService.listChildRoutes(id, req.depotId);
    res.json(children);
  } catch (err) {
    res.status(500).json({ error: 'Unable to list child routes', details: err });
  }
};

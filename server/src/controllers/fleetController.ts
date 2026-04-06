import { AuthenticatedRequest } from '../middleware/auth';
import { Request, Response } from 'express';
import * as fleetService from '../services/fleetService';
import { formatPrismaError } from '../utils/prismaErrors';

export const list = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const fleets = await fleetService.listFleets(req.depotId);
    const formatted = fleets.map(f => ({
      ...f,
      depot_name: f.depot.name
    }));
    res.json(formatted);
  } catch (err) {
    res.status(500).json({ error: 'Unable to list fleets', details: err });
  }
};

export const create = async (req: AuthenticatedRequest, res: Response) => {
  const depotId = req.depotId as string;
  const { number: fleetNumber, status, capacity } = req.body;

  if (!depotId) {
    return res.status(400).json({
      error: 'Cannot register fleet vehicle: depot context is missing for this user.'
    });
  }

  try {
    const fleet = await fleetService.createFleet(
      depotId, 
      { number: fleetNumber, status, capacity }, 
      req.user?.id
    );
    const formatted = {
      ...fleet,
      depot_name: fleet.depot.name
    };
    res.status(201).json(formatted);
  } catch (err) {
    const friendly = formatPrismaError(err, { number: fleetNumber });
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(400).json({ error: 'Could not create fleet', details: err });
  }
};

export const update = async (req: AuthenticatedRequest, res: Response) => {
  const id = req.params.id;
  const data = req.body;

  try {
    const updated = await fleetService.updateFleet(id, data, req.user?.id);
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
    res.status(400).json({ error: 'Could not update fleet', details: err });
  }
};

export const getOne = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const id = req.params.id;
    const fleet = await fleetService.getFleet(id);
    if (!fleet) return res.status(404).json({ error: 'Fleet not found' });
    const formatted = {
      ...fleet,
      depot_name: fleet.depot.name
    };
    res.json(formatted);
  } catch (err) {
    res.status(500).json({ error: 'Error fetching fleet', details: err });
  }
};

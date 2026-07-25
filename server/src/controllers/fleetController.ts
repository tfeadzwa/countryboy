import { AuthenticatedRequest } from '../middleware/auth';
import { Response } from 'express';
import * as fleetService from '../services/fleetService';
import { formatPrismaError } from '../utils/prismaErrors';
import { buildPaginatedResult, parsePagination, wantsPagination } from '../utils/pagination';

export const list = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const query = req.query as { page?: string; limit?: string };

    if (wantsPagination(query)) {
      const { page, limit, skip } = parsePagination(query);
      const [fleets, total] = await Promise.all([
        fleetService.listFleets(req.depotId, { skip, limit }),
        fleetService.countFleets(req.depotId),
      ]);
      return res.json(
        buildPaginatedResult(
          fleets.map(fleetService.formatFleetResponse),
          total,
          page,
          limit
        )
      );
    }

    const fleets = await fleetService.listFleets(req.depotId);
    res.json(fleets.map(fleetService.formatFleetResponse));
  } catch (err) {
    res.status(500).json({ error: 'Unable to list fleets', details: err });
  }
};

export const create = async (req: AuthenticatedRequest, res: Response) => {
  const depotId = req.depotId as string;
  const {
    number: fleetNumber,
    registration_number,
    status,
    capacity,
    licence_disc_expiry,
    cof_expiry,
    passenger_liability_expiry,
    route_authority_expiry,
    ppa_expiry,
  } = req.body;

  if (!depotId) {
    return res.status(400).json({
      error: 'Cannot register fleet vehicle: depot context is missing for this user.',
    });
  }

  try {
    const fleet = await fleetService.createFleet(
      depotId,
      {
        number: fleetNumber,
        registration_number,
        status,
        capacity,
        licence_disc_expiry,
        cof_expiry,
        passenger_liability_expiry,
        route_authority_expiry,
        ppa_expiry,
      },
      req.user?.id
    );
    res.status(201).json(fleetService.formatFleetResponse(fleet));
  } catch (err) {
    const friendly = formatPrismaError(err, {
      number: fleetNumber,
      registration_number,
    });
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
    res.json(fleetService.formatFleetResponse(updated));
  } catch (err) {
    const friendly = formatPrismaError(err, data as Record<string, any>);
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(400).json({ error: 'Could not update fleet', details: err });
  }
};

export const remove = async (req: AuthenticatedRequest, res: Response) => {
  const id = req.params.id;

  try {
    await fleetService.deleteFleet(id, req.depotId);
    res.json({ message: 'Fleet deleted successfully' });
  } catch (err) {
    if (err instanceof Error) {
      if (err.message === 'Fleet not found') {
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
    res.status(400).json({ error: 'Could not delete fleet', details: err });
  }
};

export const getOne = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const id = req.params.id;
    const fleet = await fleetService.getFleet(id);
    if (!fleet) return res.status(404).json({ error: 'Fleet not found' });
    res.json(fleetService.formatFleetResponse(fleet));
  } catch (err) {
    res.status(500).json({ error: 'Error fetching fleet', details: err });
  }
};

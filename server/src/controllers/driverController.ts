import { Response } from 'express';
import { AuthenticatedRequest } from '../middleware/auth';
import * as driverService from '../services/driverService';
import { formatPrismaError } from '../utils/prismaErrors';
import { buildPaginatedResult, parsePagination, wantsPagination } from '../utils/pagination';

export const list = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const query = req.query as { page?: string; limit?: string };

    if (wantsPagination(query)) {
      const { page, limit, skip } = parsePagination(query);
      const [drivers, total] = await Promise.all([
        driverService.listDrivers(req.depotId, { skip, limit }),
        driverService.countDrivers(req.depotId),
      ]);
      return res.json(
        buildPaginatedResult(
          drivers.map(driverService.formatDriverResponse),
          total,
          page,
          limit,
        ),
      );
    }

    const drivers = await driverService.listDrivers(req.depotId);
    res.json(drivers.map(driverService.formatDriverResponse));
  } catch (err) {
    res.status(500).json({ error: 'Unable to list drivers', details: err });
  }
};

export const create = async (req: AuthenticatedRequest, res: Response) => {
  const depotId = req.depotId as string;
  const { full_name, employee_code, phone, licence_number, status } = req.body;

  if (!depotId) {
    return res.status(400).json({
      error: 'Cannot register driver: depot context is missing for this user.',
    });
  }

  try {
    const driver = await driverService.createDriver(
      depotId,
      { full_name, employee_code, phone, licence_number, status },
      req.user?.id,
    );
    res.status(201).json(driverService.formatDriverResponse(driver));
  } catch (err) {
    const friendly = formatPrismaError(err, {
      employee_code,
      full_name,
    });
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(400).json({ error: 'Could not create driver', details: err });
  }
};

export const update = async (req: AuthenticatedRequest, res: Response) => {
  const id = req.params.id;
  const data = req.body;

  try {
    const updated = await driverService.updateDriver(
      id,
      data,
      req.user?.id,
      req.depotId,
    );
    res.json(driverService.formatDriverResponse(updated));
  } catch (err) {
    if (err instanceof Error && err.message === 'Driver not found') {
      return res.status(404).json({ error: err.message });
    }
    const friendly = formatPrismaError(err, data as Record<string, unknown>);
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(400).json({ error: 'Could not update driver', details: err });
  }
};

export const remove = async (req: AuthenticatedRequest, res: Response) => {
  const id = req.params.id;

  try {
    await driverService.deleteDriver(id, req.depotId);
    res.json({ message: 'Driver deleted successfully' });
  } catch (err) {
    if (err instanceof Error) {
      if (err.message === 'Driver not found') {
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
    res.status(400).json({ error: 'Could not delete driver', details: err });
  }
};

export const getOne = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const id = req.params.id;
    const driver = await driverService.getDriver(id);
    if (!driver) return res.status(404).json({ error: 'Driver not found' });
    if (req.depotId && driver.depot_id !== req.depotId) {
      return res.status(404).json({ error: 'Driver not found' });
    }
    res.json(driverService.formatDriverResponse(driver));
  } catch (err) {
    res.status(500).json({ error: 'Error fetching driver', details: err });
  }
};

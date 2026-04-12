import { Response } from 'express';
import prisma from '../utils/prisma';
import { AuthenticatedRequest } from '@/middleware/auth';
import { formatPrismaError } from '../utils/prismaErrors';

export const createDepot = async (req: AuthenticatedRequest, res: Response) => {
  const { merchant_code, name, location } = req.body;
  try {
    const depot = await prisma.tblDepots.create({
      data: { merchant_code, name, location, created_by: req.user?.id }
    });
    res.status(201).json(depot);
  } catch (err) {
    const friendly = formatPrismaError(err, { merchant_code, name, location });
    if (friendly) {
      // return attempted payload so UI can re-display values like location
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(400).json({ error: 'Could not create depot', details: err });
  }
};

export const listDepots = async (req: AuthenticatedRequest, res: Response) => {
  // SUPER_ADMIN (no depot_id) sees all depots; DEPOT_ADMIN sees only their own
  const where = req.depotId ? { id: req.depotId } : {};
  const depots = await prisma.tblDepots.findMany({ where });
  res.json(depots);
};

export const updateDepot = async (req: AuthenticatedRequest, res: Response) => {
  const { id } = req.params;
  const { merchant_code, name, location } = req.body;
  
  try {
    // Check if depot exists
    const existingDepot = await prisma.tblDepots.findUnique({
      where: { id }
    });
    
    if (!existingDepot) {
      return res.status(404).json({ error: 'Depot not found' });
    }
    
    const depot = await prisma.tblDepots.update({
      where: { id },
      data: { merchant_code, name, location, updated_by: req.user?.id }
    });
    
    res.json(depot);
  } catch (err) {
    const friendly = formatPrismaError(err, { merchant_code, name, location });
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(400).json({ error: 'Could not update depot', details: err });
  }
};

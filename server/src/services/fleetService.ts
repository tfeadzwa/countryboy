import prisma from '../utils/prisma';
import { Prisma } from '@prisma/client';

export const listFleets = async (depotId?: string) => {
  const where: Prisma.tblFleetsWhereInput = {};
  if (depotId) where.depot_id = depotId;
  return prisma.tblFleets.findMany({ 
    where,
    include: { depot: true }
  });
};

export const createFleet = async (depotId: string, data: { number: string; status?: string; capacity?: number }, createdBy?: string) => {
  return prisma.tblFleets.create({ 
    data: { ...data, depot_id: depotId, created_by: createdBy },
    include: { depot: true }
  });
};

export const updateFleet = async (id: string, data: Partial<{ number: string; status?: string; capacity?: number }>, updatedBy?: string) => {
  return prisma.tblFleets.update({ 
    where: { id }, 
    data: { ...data, updated_by: updatedBy },
    include: { depot: true }
  });
};

export const getFleet = async (id: string) => {
  return prisma.tblFleets.findUnique({ 
    where: { id },
    include: { depot: true }
  });
};

import prisma from '../utils/prisma';
import { Prisma } from '@prisma/client';

export const listFares = async (depotId?: string) => {
  const where: Prisma.tblFaresWhereInput = {};
  if (depotId) where.depot_id = depotId;
  return prisma.tblFares.findMany({ 
    where,
    include: { depot: true, route: true }
  });
};

export const createFare = async (depotId: string, data: { route_id: string; currency: string; amount: number; }, createdBy?: string) => {
  return prisma.tblFares.create({ 
    data: { ...data, depot_id: depotId, created_by: createdBy },
    include: { depot: true, route: true }
  });
};

export const updateFare = async (id: string, data: Partial<{ currency: string; amount: number; }>, updatedBy?: string) => {
  return prisma.tblFares.update({ 
    where: { id }, 
    data: { ...data, updated_by: updatedBy },
    include: { depot: true, route: true }
  });
};

export const getFare = async (id: string) => {
  return prisma.tblFares.findUnique({ 
    where: { id },
    include: { depot: true, route: true }
  });
};

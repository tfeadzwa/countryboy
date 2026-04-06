import prisma from '../utils/prisma';
import { Prisma } from '@prisma/client';

export const listRoutes = async (depotId?: string) => {
  const where: Prisma.tblRoutesWhereInput = {};
  if (depotId) where.depot_id = depotId;
  return prisma.tblRoutes.findMany({ 
    where,
    include: { depot: true }
  });
};

export const createRoute = async (depotId: string, data: { origin: string; destination: string; is_active?: boolean; distance_km?: number }, createdBy?: string) => {
  return prisma.tblRoutes.create({ 
    data: { ...data, depot_id: depotId, created_by: createdBy },
    include: { depot: true }
  });
};

export const updateRoute = async (id: string, data: Partial<{ origin: string; destination: string; is_active?: boolean; distance_km?: number }>, updatedBy?: string) => {
  return prisma.tblRoutes.update({ 
    where: { id }, 
    data: { ...data, updated_by: updatedBy },
    include: { depot: true }
  });
};

export const getRoute = async (id: string) => {
  return prisma.tblRoutes.findUnique({ 
    where: { id },
    include: { depot: true }
  });
};

import prisma from '../utils/prisma';
import { tblFleets, tblDepots, FleetStatus } from '@prisma/client';

type FleetWithDepot = tblFleets & { depot: tblDepots | null };

export const listFleets = async (depotId?: string): Promise<FleetWithDepot[]> => {
  const where = {} as any;
  if (depotId) where.depot_id = depotId;
  return prisma.tblFleets.findMany({
    where,
    include: { depot: true },
  }) as Promise<FleetWithDepot[]>;
};

export const createFleet = async (
  depotId: string,
  data: { number: string; status?: FleetStatus; capacity?: number },
  createdBy?: string
): Promise<FleetWithDepot> => {
  return prisma.tblFleets.create({
    data: { ...data, depot_id: depotId, created_by: createdBy } as any,
    include: { depot: true },
  }) as Promise<FleetWithDepot>;
};

export const updateFleet = async (
  id: string,
  data: Partial<{ number: string; status?: FleetStatus; capacity?: number }>,
  updatedBy?: string
): Promise<FleetWithDepot> => {
  return prisma.tblFleets.update({
    where: { id },
    data: { ...data, updated_by: updatedBy } as any,
    include: { depot: true },
  }) as Promise<FleetWithDepot>;
};

export const getFleet = async (id: string): Promise<FleetWithDepot | null> => {
  return prisma.tblFleets.findUnique({
    where: { id },
    include: { depot: true },
  }) as Promise<FleetWithDepot | null>;
};

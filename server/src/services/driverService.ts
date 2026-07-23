import prisma from '../utils/prisma';
import { tblDrivers, tblDepots } from '@prisma/client';

type DriverWithDepot = tblDrivers & { depot: tblDepots | null };

export type DriverInput = {
  full_name: string;
  employee_code?: string | null;
  phone?: string | null;
  licence_number?: string | null;
  status?: string;
};

const normalizeOptional = (value?: string | null) => {
  const trimmed = value?.trim();
  return trimmed ? trimmed : null;
};

export const formatDriverResponse = (driver: DriverWithDepot) => ({
  ...driver,
  depot_name: driver.depot?.name ?? null,
});

export const listDrivers = async (
  depotId?: string,
  pagination?: { skip: number; limit: number },
): Promise<DriverWithDepot[]> => {
  const where = {} as { depot_id?: string };
  if (depotId) where.depot_id = depotId;
  return prisma.tblDrivers.findMany({
    where,
    include: { depot: true },
    orderBy: { full_name: 'asc' },
    ...(pagination ? { skip: pagination.skip, take: pagination.limit } : {}),
  }) as Promise<DriverWithDepot[]>;
};

export const countDrivers = async (depotId?: string): Promise<number> => {
  const where = {} as { depot_id?: string };
  if (depotId) where.depot_id = depotId;
  return prisma.tblDrivers.count({ where });
};

export const getDriver = async (id: string): Promise<DriverWithDepot | null> => {
  return prisma.tblDrivers.findUnique({
    where: { id },
    include: { depot: true },
  }) as Promise<DriverWithDepot | null>;
};

export const createDriver = async (
  depotId: string,
  data: DriverInput,
  createdBy?: string,
): Promise<DriverWithDepot> => {
  return prisma.tblDrivers.create({
    data: {
      full_name: data.full_name.trim(),
      employee_code: normalizeOptional(data.employee_code),
      phone: normalizeOptional(data.phone),
      licence_number: normalizeOptional(data.licence_number),
      status: data.status ?? 'ACTIVE',
      depot_id: depotId,
      created_by: createdBy,
    },
    include: { depot: true },
  }) as Promise<DriverWithDepot>;
};

export const updateDriver = async (
  id: string,
  data: Partial<DriverInput> & { depot_id?: string },
  updatedBy?: string,
  depotId?: string,
): Promise<DriverWithDepot> => {
  const existing = await prisma.tblDrivers.findFirst({
    where: { id, ...(depotId ? { depot_id: depotId } : {}) },
  });
  if (!existing) {
    throw new Error('Driver not found');
  }

  return prisma.tblDrivers.update({
    where: { id },
    data: {
      ...(data.full_name !== undefined
        ? { full_name: data.full_name.trim() }
        : {}),
      ...(data.employee_code !== undefined
        ? { employee_code: normalizeOptional(data.employee_code) }
        : {}),
      ...(data.phone !== undefined ? { phone: normalizeOptional(data.phone) } : {}),
      ...(data.licence_number !== undefined
        ? { licence_number: normalizeOptional(data.licence_number) }
        : {}),
      ...(data.status !== undefined ? { status: data.status } : {}),
      ...(data.depot_id !== undefined ? { depot_id: data.depot_id } : {}),
      updated_by: updatedBy,
    },
    include: { depot: true },
  }) as Promise<DriverWithDepot>;
};

export const deleteDriver = async (id: string, depotId?: string): Promise<void> => {
  const driver = await prisma.tblDrivers.findFirst({
    where: { id, ...(depotId ? { depot_id: depotId } : {}) },
    include: { _count: { select: { trips: true } } },
  });

  if (!driver) {
    throw new Error('Driver not found');
  }

  if (driver._count.trips > 0) {
    throw new Error(
      'Cannot delete a driver with trip history. Set their status to Inactive instead.',
    );
  }

  await prisma.tblDrivers.delete({ where: { id } });
};

import prisma from '../utils/prisma';
import { tblDrivers, tblDepots } from '@prisma/client';

type ActiveTripInclude = {
  id: string;
  origin: string;
  destination: string;
  started_at: Date;
  fleet: { number: string } | null;
  agent: { id: string; full_name: string; agent_code: string } | null;
};

type DriverWithDepot = tblDrivers & {
  depot: tblDepots | null;
  trips?: ActiveTripInclude[];
};

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

const mapActiveTrip = (trip?: ActiveTripInclude | null) => {
  if (!trip) return null;
  return {
    id: trip.id,
    origin: trip.origin,
    destination: trip.destination,
    fleet_number: trip.fleet?.number ?? null,
    agent_id: trip.agent?.id ?? null,
    agent_name: trip.agent?.full_name ?? null,
    agent_code: trip.agent?.agent_code ?? null,
    started_at: trip.started_at.toISOString(),
  };
};

export const formatDriverResponse = (driver: DriverWithDepot) => {
  const activeTrip = mapActiveTrip(driver.trips?.[0]);
  const accountActive = driver.status === 'ACTIVE';
  // Duty reflects real assignment, not just account flags.
  const duty_status = !accountActive
    ? 'off_duty'
    : activeTrip
      ? 'on_trip'
      : 'available';

  return {
    id: driver.id,
    full_name: driver.full_name,
    employee_code: driver.employee_code,
    phone: driver.phone,
    licence_number: driver.licence_number,
    depot_id: driver.depot_id,
    depot_name: driver.depot?.name ?? null,
    status: driver.status,
    duty_status,
    on_trip: Boolean(activeTrip),
    active_trip: activeTrip,
    created_at: driver.created_at,
    updated_at: driver.updated_at,
  };
};

const activeTripInclude = {
  where: { status: 'ACTIVE' as const },
  take: 1,
  orderBy: { started_at: 'desc' as const },
  select: {
    id: true,
    origin: true,
    destination: true,
    started_at: true,
    fleet: { select: { number: true } },
    agent: { select: { id: true, full_name: true, agent_code: true } },
  },
};

export const listDrivers = async (
  depotId?: string,
  pagination?: { skip: number; limit: number },
): Promise<DriverWithDepot[]> => {
  const where = {} as { depot_id?: string };
  if (depotId) where.depot_id = depotId;

  // Load full depot set first so on-trip drivers can rank above the rest before pagination.
  const drivers = (await prisma.tblDrivers.findMany({
    where,
    include: { depot: true, trips: activeTripInclude },
    orderBy: { full_name: 'asc' },
  })) as DriverWithDepot[];

  drivers.sort((a, b) => {
    const aOnTrip = Boolean(a.trips?.[0]);
    const bOnTrip = Boolean(b.trips?.[0]);
    if (aOnTrip !== bOnTrip) return aOnTrip ? -1 : 1;

    const aActive = a.status === 'ACTIVE';
    const bActive = b.status === 'ACTIVE';
    if (aActive !== bActive) return aActive ? -1 : 1;

    const aStarted = a.trips?.[0]?.started_at?.getTime() ?? 0;
    const bStarted = b.trips?.[0]?.started_at?.getTime() ?? 0;
    if (aStarted !== bStarted) return bStarted - aStarted;

    return a.full_name.localeCompare(b.full_name);
  });

  if (pagination) {
    return drivers.slice(pagination.skip, pagination.skip + pagination.limit);
  }

  return drivers;
};

export const countDrivers = async (depotId?: string): Promise<number> => {
  const where = {} as { depot_id?: string };
  if (depotId) where.depot_id = depotId;
  return prisma.tblDrivers.count({ where });
};

export const getDriver = async (id: string): Promise<DriverWithDepot | null> => {
  return prisma.tblDrivers.findUnique({
    where: { id },
    include: { depot: true, trips: activeTripInclude },
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
    include: { depot: true, trips: activeTripInclude },
  }) as Promise<DriverWithDepot>;
};

export const updateDriver = async (
  id: string,
  data: Partial<DriverInput> & { depot_id?: string },
  updatedBy?: string,
  depotId?: string,
): Promise<DriverWithDepot> => {
  const existing = await prisma.tblDrivers.findUnique({ where: { id } });
  if (!existing) {
    throw new Error('Driver not found');
  }
  // Enforce depot scope against the driver's current depot (not the target depot).
  if (depotId && existing.depot_id !== depotId) {
    throw new Error('Driver not found');
  }

  return prisma.tblDrivers.update({
    where: { id },
    data: {
      ...(data.full_name !== undefined ? { full_name: data.full_name.trim() } : {}),
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
    include: { depot: true, trips: activeTripInclude },
  }) as Promise<DriverWithDepot>;
};

export const deleteDriver = async (id: string, depotId?: string): Promise<void> => {
  const existing = await prisma.tblDrivers.findFirst({
    where: { id, ...(depotId ? { depot_id: depotId } : {}) },
    include: { _count: { select: { trips: true } } },
  });
  if (!existing) {
    throw new Error('Driver not found');
  }
  if (existing._count.trips > 0) {
    throw new Error(
      'Cannot delete a driver with trip history. Set status to Inactive instead.',
    );
  }
  await prisma.tblDrivers.delete({ where: { id } });
};

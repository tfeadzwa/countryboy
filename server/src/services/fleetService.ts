import prisma from '../utils/prisma';
import { tblFleets, tblDepots, FleetStatus } from '@prisma/client';
import {
  FLEET_COMPLIANCE_ITEMS,
  FleetComplianceKey,
  getComplianceAlertLevel,
  parseDateInput,
  type AlertFrequency,
  type AlertSeverity,
} from '../utils/fleetCompliance';

type FleetWithDepot = tblFleets & { depot: tblDepots | null };

export type FleetComplianceStatusItem = {
  key: FleetComplianceKey;
  label: string;
  shortLabel: string;
  expiry_date: string | null;
  days_remaining: number | null;
  frequency: AlertFrequency | null;
  severity: AlertSeverity;
  status_label: string;
};

export type FleetCompliancePayload = {
  licence_disc_expiry?: string | Date | null;
  cof_expiry?: string | Date | null;
  passenger_liability_expiry?: string | Date | null;
  route_authority_expiry?: string | Date | null;
  ppa_expiry?: string | Date | null;
};

function buildComplianceStatus(fleet: tblFleets): FleetComplianceStatusItem[] {
  return FLEET_COMPLIANCE_ITEMS.map((item) => {
    const raw = fleet[item.key as keyof tblFleets] as Date | null | undefined;
    if (!raw) {
      return {
        key: item.key,
        label: item.label,
        shortLabel: item.shortLabel,
        expiry_date: null,
        days_remaining: null,
        frequency: 'daily' as AlertFrequency,
        severity: 'expired' as AlertSeverity,
        status_label: 'Missing expiry date',
      };
    }

    const level = getComplianceAlertLevel(new Date(raw));
    return {
      key: item.key,
      label: item.label,
      shortLabel: item.shortLabel,
      expiry_date: new Date(raw).toISOString(),
      days_remaining: level.daysRemaining,
      frequency: level.frequency,
      severity: level.severity,
      status_label: level.label,
    };
  });
}

function worstSeverity(items: FleetComplianceStatusItem[]): AlertSeverity {
  const order: AlertSeverity[] = ['expired', 'urgent', 'warning', 'info', 'ok'];
  for (const s of order) {
    if (items.some((i) => i.severity === s)) return s;
  }
  return 'ok';
}

export function formatFleetResponse(fleet: FleetWithDepot) {
  const compliance = buildComplianceStatus(fleet);
  return {
    ...fleet,
    depot_name: fleet.depot?.name ?? null,
    compliance,
    compliance_summary: {
      worst_severity: worstSeverity(compliance),
      items_needing_attention: compliance.filter(
        (c) => c.severity === 'expired' || c.severity === 'urgent' || c.severity === 'warning'
      ).length,
    },
  };
}

function toComplianceDbFields(data: FleetCompliancePayload) {
  const out: Record<string, Date | null | undefined> = {};
  for (const item of FLEET_COMPLIANCE_ITEMS) {
    if (data[item.key] !== undefined) {
      out[item.key] = parseDateInput(data[item.key]);
    }
  }
  return out;
}

export const listFleets = async (
  depotId?: string,
  pagination?: { skip: number; limit: number }
): Promise<FleetWithDepot[]> => {
  const where = {} as any;
  if (depotId) where.depot_id = depotId;
  return prisma.tblFleets.findMany({
    where,
    include: { depot: true },
    orderBy: { number: 'asc' },
    ...(pagination ? { skip: pagination.skip, take: pagination.limit } : {}),
  }) as Promise<FleetWithDepot[]>;
};

export const countFleets = async (depotId?: string): Promise<number> => {
  const where = {} as any;
  if (depotId) where.depot_id = depotId;
  return prisma.tblFleets.count({ where });
};

export const deleteFleet = async (id: string, depotId?: string): Promise<void> => {
  const fleet = await prisma.tblFleets.findFirst({
    where: { id, ...(depotId ? { depot_id: depotId } : {}) },
    include: { _count: { select: { trips: true } } },
  });

  if (!fleet) {
    throw new Error('Fleet not found');
  }

  if (fleet._count.trips > 0) {
    throw new Error(
      'Cannot delete a fleet with trip history. Set its status to Retired instead.'
    );
  }

  await prisma.tblFleets.delete({ where: { id } });
};

export const createFleet = async (
  depotId: string,
  data: {
    number: string;
    status?: FleetStatus;
    capacity?: number;
  } & FleetCompliancePayload,
  createdBy?: string
): Promise<FleetWithDepot> => {
  const { number, status, capacity, ...compliance } = data;
  return prisma.tblFleets.create({
    data: {
      number,
      status,
      capacity,
      depot_id: depotId,
      created_by: createdBy,
      ...toComplianceDbFields(compliance),
    } as any,
    include: { depot: true },
  }) as Promise<FleetWithDepot>;
};

export const updateFleet = async (
  id: string,
  data: Partial<{
    number: string;
    status?: FleetStatus;
    capacity?: number;
  } & FleetCompliancePayload>,
  updatedBy?: string
): Promise<FleetWithDepot> => {
  const { number, status, capacity, ...rest } = data;
  const compliance = toComplianceDbFields(rest);

  return prisma.tblFleets.update({
    where: { id },
    data: {
      ...(number !== undefined ? { number } : {}),
      ...(status !== undefined ? { status } : {}),
      ...(capacity !== undefined ? { capacity } : {}),
      ...compliance,
      updated_by: updatedBy,
    } as any,
    include: { depot: true },
  }) as Promise<FleetWithDepot>;
};

export const getFleet = async (id: string): Promise<FleetWithDepot | null> => {
  return prisma.tblFleets.findUnique({
    where: { id },
    include: { depot: true },
  }) as Promise<FleetWithDepot | null>;
};

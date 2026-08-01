import fs from 'fs/promises';
import path from 'path';
import prisma from '../utils/prisma';
import { tblDrivers, tblDepots } from '@prisma/client';
import {
  buildDriverDocumentStatus,
  getDocumentItem,
  validateDriverDocumentExpiry,
  type DriverDocumentType,
  worstDocumentSeverity,
} from '../utils/driverCompliance';
import { parseDateInput } from '../utils/fleetCompliance';
import {
  buildStoredRelativePath,
  deleteStoredFile,
  ensureDriverDocumentDir,
  ensureUploadRoot,
  resolveStoredFile,
  resolveUploadMime,
  UPLOAD_ROOT,
} from '../utils/fileStorage';

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
  drivers_licence_expiry?: string | Date | null;
  medical_certificate_expiry?: string | Date | null;
  defensive_driving_certificate_expiry?: string | Date | null;
  defensive_driving_certificate_number?: string | null;
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
  // ACTIVE trip is source of truth; ignore sticky on_trip left by old end paths.
  const onTrip = Boolean(activeTrip);
  const documents = buildDriverDocumentStatus(driver);
  const duty_status = !accountActive
    ? 'off_duty'
    : onTrip
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
    on_trip: onTrip,
    active_trip: activeTrip,
    drivers_licence_expiry: driver.drivers_licence_expiry?.toISOString() ?? null,
    medical_certificate_expiry: driver.medical_certificate_expiry?.toISOString() ?? null,
    defensive_driving_certificate_expiry:
      driver.defensive_driving_certificate_expiry?.toISOString() ?? null,
    defensive_driving_certificate_number:
      driver.defensive_driving_certificate_number ?? null,
    drivers_licence_file_name: driver.drivers_licence_file_name ?? null,
    medical_certificate_file_name: driver.medical_certificate_file_name ?? null,
    defensive_driving_certificate_file_name:
      driver.defensive_driving_certificate_file_name ?? null,
    drivers_licence_uploaded_at: driver.drivers_licence_uploaded_at?.toISOString() ?? null,
    medical_certificate_uploaded_at: driver.medical_certificate_uploaded_at?.toISOString() ?? null,
    defensive_driving_certificate_uploaded_at:
      driver.defensive_driving_certificate_uploaded_at?.toISOString() ?? null,
    documents,
    documents_summary: {
      worst_severity: worstDocumentSeverity(documents),
      items_needing_attention: documents.filter(
        (doc) =>
          doc.severity === 'expired' ||
          doc.severity === 'urgent' ||
          doc.severity === 'warning',
      ).length,
    },
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

const assertDriverAccess = async (id: string, depotId?: string) => {
  const driver = await prisma.tblDrivers.findUnique({ where: { id } });
  if (!driver) {
    throw new Error('Driver not found');
  }
  if (depotId && driver.depot_id !== depotId) {
    throw new Error('Driver not found');
  }
  return driver;
};

export const listDrivers = async (
  depotId?: string,
  pagination?: { skip: number; limit: number },
): Promise<DriverWithDepot[]> => {
  const where = {} as { depot_id?: string };
  if (depotId) where.depot_id = depotId;

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
      defensive_driving_certificate_number: normalizeOptional(
        data.defensive_driving_certificate_number,
      ),
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
  const existing = await assertDriverAccess(id, depotId);

  if (data.defensive_driving_certificate_expiry !== undefined) {
    validateDriverDocumentExpiry(
      'defensive_driving_certificate',
      parseDateInput(data.defensive_driving_certificate_expiry),
    );
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
      ...(data.defensive_driving_certificate_number !== undefined
        ? {
            defensive_driving_certificate_number: normalizeOptional(
              data.defensive_driving_certificate_number,
            ),
          }
        : {}),
      ...(data.status !== undefined ? { status: data.status } : {}),
      ...(data.depot_id !== undefined ? { depot_id: data.depot_id } : {}),
      ...(data.drivers_licence_expiry !== undefined
        ? { drivers_licence_expiry: parseDateInput(data.drivers_licence_expiry) }
        : {}),
      ...(data.medical_certificate_expiry !== undefined
        ? { medical_certificate_expiry: parseDateInput(data.medical_certificate_expiry) }
        : {}),
      ...(data.defensive_driving_certificate_expiry !== undefined
        ? {
            defensive_driving_certificate_expiry: parseDateInput(
              data.defensive_driving_certificate_expiry,
            ),
          }
        : {}),
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

  await deleteStoredFile(existing.drivers_licence_file_path);
  await deleteStoredFile(existing.medical_certificate_file_path);
  await deleteStoredFile(existing.defensive_driving_certificate_file_path);

  await prisma.tblDrivers.delete({ where: { id } });
};

export const uploadDriverDocument = async (
  id: string,
  documentType: DriverDocumentType,
  file: Express.Multer.File,
  expiryDate: string | null | undefined,
  updatedBy?: string,
  depotId?: string,
): Promise<DriverWithDepot> => {
  const existing = await assertDriverAccess(id, depotId);
  const item = getDocumentItem(documentType);
  if (!item) {
    throw new Error('Invalid document type');
  }

  const resolvedMime = resolveUploadMime(file.originalname, file.mimetype);
  if (!resolvedMime) {
    throw new Error('File type not allowed. Use PDF, JPEG, PNG, or WebP.');
  }

  const parsedExpiry = parseDateInput(expiryDate);
  validateDriverDocumentExpiry(documentType, parsedExpiry);

  await ensureUploadRoot();
  const relativePath = buildStoredRelativePath(
    id,
    documentType,
    file.originalname,
    resolvedMime,
  );
  await ensureDriverDocumentDir(id);
  const absolutePath = path.join(UPLOAD_ROOT, relativePath);
  await fs.writeFile(absolutePath, file.buffer);

  const previousPath = existing[item.fileField];
  await deleteStoredFile(previousPath);

  const now = new Date();
  const updateData: Record<string, unknown> = {
    [item.fileField]: relativePath.replace(/\\/g, '/'),
    [item.fileNameField]: file.originalname,
    [item.uploadedAtField]: now,
    updated_by: updatedBy,
  };

  if (expiryDate !== undefined) {
    updateData[item.expiryField] = parsedExpiry;
  }

  return prisma.tblDrivers.update({
    where: { id },
    data: updateData,
    include: { depot: true, trips: activeTripInclude },
  }) as Promise<DriverWithDepot>;
};

export const getDriverDocumentForDownload = async (
  id: string,
  documentType: DriverDocumentType,
  depotId?: string,
) => {
  const driver = await assertDriverAccess(id, depotId);
  const item = getDocumentItem(documentType);
  if (!item) {
    throw new Error('Invalid document type');
  }

  const storedPath = driver[item.fileField];
  if (!storedPath) {
    throw new Error('Document not found');
  }

  const absolutePath = resolveStoredFile(storedPath);
  const fileName = driver[item.fileNameField] ?? `${documentType}${path.extname(storedPath)}`;

  return { absolutePath, fileName };
};

export const removeDriverDocument = async (
  id: string,
  documentType: DriverDocumentType,
  updatedBy?: string,
  depotId?: string,
): Promise<DriverWithDepot> => {
  const existing = await assertDriverAccess(id, depotId);
  const item = getDocumentItem(documentType);
  if (!item) {
    throw new Error('Invalid document type');
  }

  await deleteStoredFile(existing[item.fileField]);

  return prisma.tblDrivers.update({
    where: { id },
    data: {
      [item.fileField]: null,
      [item.fileNameField]: null,
      [item.expiryField]: null,
      [item.uploadedAtField]: null,
      ...('numberField' in item ? { [item.numberField]: null } : {}),
      updated_by: updatedBy,
    },
    include: { depot: true, trips: activeTripInclude },
  }) as Promise<DriverWithDepot>;
};

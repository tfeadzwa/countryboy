/** Driver document compliance definitions and status helpers */

import {
  getComplianceAlertLevel,
  type AlertFrequency,
  type AlertSeverity,
} from './fleetCompliance';

export const DDC_MAX_VALIDITY_YEARS = 2;

export const DRIVER_DOCUMENT_TYPES = [
  'drivers_licence',
  'medical_certificate',
  'defensive_driving_certificate',
] as const;
export type DriverDocumentType = (typeof DRIVER_DOCUMENT_TYPES)[number];

export const DRIVER_DOCUMENT_ITEMS = [
  {
    key: 'drivers_licence' as const,
    label: "Driver's Licence",
    shortLabel: 'Licence',
    numberField: 'licence_number' as const,
    expiryField: 'drivers_licence_expiry' as const,
    fileField: 'drivers_licence_file_path' as const,
    fileNameField: 'drivers_licence_file_name' as const,
    uploadedAtField: 'drivers_licence_uploaded_at' as const,
    expiryOptional: true,
    maxYearsFromToday: undefined,
  },
  {
    key: 'medical_certificate' as const,
    label: 'Medical Certificate',
    shortLabel: 'Medical',
    expiryField: 'medical_certificate_expiry' as const,
    fileField: 'medical_certificate_file_path' as const,
    fileNameField: 'medical_certificate_file_name' as const,
    uploadedAtField: 'medical_certificate_uploaded_at' as const,
    expiryOptional: false,
    maxYearsFromToday: undefined,
  },
  {
    key: 'defensive_driving_certificate' as const,
    label: 'Defensive Driving Certificate',
    shortLabel: 'DDC',
    numberField: 'defensive_driving_certificate_number' as const,
    expiryField: 'defensive_driving_certificate_expiry' as const,
    fileField: 'defensive_driving_certificate_file_path' as const,
    fileNameField: 'defensive_driving_certificate_file_name' as const,
    uploadedAtField: 'defensive_driving_certificate_uploaded_at' as const,
    expiryOptional: false,
    maxYearsFromToday: DDC_MAX_VALIDITY_YEARS,
  },
] as const;

export type DriverDocumentKey = (typeof DRIVER_DOCUMENT_ITEMS)[number]['key'];

export interface DriverDocumentStatusItem {
  key: DriverDocumentKey;
  label: string;
  shortLabel: string;
  certificate_number: string | null;
  expiry_date: string | null;
  file_name: string | null;
  uploaded_at: string | null;
  has_file: boolean;
  days_remaining: number | null;
  frequency: AlertFrequency | null;
  severity: AlertSeverity;
  status_label: string;
}

type DriverRecord = {
  licence_number?: string | null;
  drivers_licence_file_path?: string | null;
  drivers_licence_file_name?: string | null;
  drivers_licence_expiry?: Date | null;
  drivers_licence_uploaded_at?: Date | null;
  medical_certificate_file_path?: string | null;
  medical_certificate_file_name?: string | null;
  medical_certificate_expiry?: Date | null;
  medical_certificate_uploaded_at?: Date | null;
  defensive_driving_certificate_number?: string | null;
  defensive_driving_certificate_file_path?: string | null;
  defensive_driving_certificate_file_name?: string | null;
  defensive_driving_certificate_expiry?: Date | null;
  defensive_driving_certificate_uploaded_at?: Date | null;
};

export function maxExpiryDateYearsFrom(reference: Date, years: number): Date {
  const max = new Date(reference);
  max.setFullYear(max.getFullYear() + years);
  max.setHours(23, 59, 59, 999);
  return max;
}

export function validateDriverDocumentExpiry(
  documentType: DriverDocumentType,
  expiry: Date | null,
  referenceDate: Date = new Date(),
): void {
  const item = getDocumentItem(documentType);
  if (!item) {
    throw new Error('Invalid document type');
  }

  if (!item.expiryOptional && !expiry) {
    throw new Error(`${item.label} expiry date is required`);
  }

  if (item.maxYearsFromToday && expiry) {
    const maxExpiry = maxExpiryDateYearsFrom(referenceDate, item.maxYearsFromToday);
    if (expiry > maxExpiry) {
      throw new Error(
        `${item.shortLabel} expiry cannot be more than ${item.maxYearsFromToday} years from today`,
      );
    }
  }
}

function buildDocumentStatus(
  item: (typeof DRIVER_DOCUMENT_ITEMS)[number],
  driver: DriverRecord,
): DriverDocumentStatusItem {
  const filePath = driver[item.fileField];
  const fileName = driver[item.fileNameField] ?? null;
  const uploadedAt = driver[item.uploadedAtField];
  const expiryRaw = driver[item.expiryField];
  const certificateNumber =
    'numberField' in item ? (driver[item.numberField] ?? null) : null;
  const hasFile = Boolean(filePath);

  if (!hasFile) {
    return {
      key: item.key,
      label: item.label,
      shortLabel: item.shortLabel,
      certificate_number: certificateNumber,
      expiry_date: null,
      file_name: null,
      uploaded_at: null,
      has_file: false,
      days_remaining: null,
      frequency: 'weekly',
      severity: 'warning',
      status_label: 'Document not uploaded',
    };
  }

  if (!expiryRaw) {
    if (item.expiryOptional) {
      return {
        key: item.key,
        label: item.label,
        shortLabel: item.shortLabel,
        certificate_number: certificateNumber,
        expiry_date: null,
        file_name: fileName,
        uploaded_at: uploadedAt ? new Date(uploadedAt).toISOString() : null,
        has_file: true,
        days_remaining: null,
        frequency: 'monthly',
        severity: 'info',
        status_label: 'Uploaded — no expiry on record',
      };
    }

    return {
      key: item.key,
      label: item.label,
      shortLabel: item.shortLabel,
      certificate_number: certificateNumber,
      expiry_date: null,
      file_name: fileName,
      uploaded_at: uploadedAt ? new Date(uploadedAt).toISOString() : null,
      has_file: true,
      days_remaining: null,
      frequency: 'weekly',
      severity: 'warning',
      status_label: 'Expiry date required',
    };
  }

  const level = getComplianceAlertLevel(new Date(expiryRaw));
  return {
    key: item.key,
    label: item.label,
    shortLabel: item.shortLabel,
    certificate_number: certificateNumber,
    expiry_date: new Date(expiryRaw).toISOString(),
    file_name: fileName,
    uploaded_at: uploadedAt ? new Date(uploadedAt).toISOString() : null,
    has_file: true,
    days_remaining: level.daysRemaining,
    frequency: level.frequency,
    severity: level.severity,
    status_label: level.label,
  };
}

export function buildDriverDocumentStatus(driver: DriverRecord): DriverDocumentStatusItem[] {
  return DRIVER_DOCUMENT_ITEMS.map((item) => buildDocumentStatus(item, driver));
}

export function worstDocumentSeverity(items: DriverDocumentStatusItem[]): AlertSeverity {
  const order: AlertSeverity[] = ['expired', 'urgent', 'warning', 'info', 'ok'];
  for (const severity of order) {
    if (items.some((item) => item.severity === severity)) return severity;
  }
  return 'ok';
}

export function isDriverDocumentType(value: string): value is DriverDocumentType {
  return (DRIVER_DOCUMENT_TYPES as readonly string[]).includes(value);
}

export function getDocumentItem(type: DriverDocumentType) {
  return DRIVER_DOCUMENT_ITEMS.find((item) => item.key === type);
}

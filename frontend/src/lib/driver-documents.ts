/** Shared driver document field definitions (mirrors backend). */

import type { Driver, DriverDocumentKey } from '@/types';
import { severityStyles } from '@/lib/fleet-compliance';

export const DDC_MAX_VALIDITY_YEARS = 2;

export const DRIVER_DOCUMENT_FIELDS = [
  {
    key: 'drivers_licence' as const,
    label: "Driver's Licence",
    shortLabel: 'Licence',
    description: 'Official issued driver\'s licence (scan or photo)',
    expiryOptional: true,
    expiryHint: 'Leave blank for older licences with no expiry date',
    maxYearsFromToday: undefined as number | undefined,
  },
  {
    key: 'medical_certificate' as const,
    label: 'Medical Certificate',
    shortLabel: 'Medical',
    description: 'Medical fitness certificate from a registered practitioner',
    expiryOptional: false,
    expiryHint: 'Required — medical certificates always have an expiry date',
    maxYearsFromToday: undefined as number | undefined,
  },
  {
    key: 'defensive_driving_certificate' as const,
    label: 'Defensive Driving Certificate (DDC)',
    shortLabel: 'DDC',
    description: 'Valid defensive driving certificate for the driver',
    expiryOptional: false,
    expiryHint: `Required — expiry cannot be more than ${DDC_MAX_VALIDITY_YEARS} years from today`,
    maxYearsFromToday: DDC_MAX_VALIDITY_YEARS,
  },
];

export type DriverDocumentFormState = {
  licence_number: string;
  drivers_licence_expiry: string;
  medical_certificate_expiry: string;
  defensive_driving_certificate_expiry: string;
  defensive_driving_certificate_number: string;
  drivers_licence_no_expiry: boolean;
};

export const emptyDriverDocumentForm = (): DriverDocumentFormState => ({
  licence_number: '',
  drivers_licence_expiry: '',
  medical_certificate_expiry: '',
  defensive_driving_certificate_expiry: '',
  defensive_driving_certificate_number: '',
  drivers_licence_no_expiry: false,
});

export function toDateInputValue(iso?: string | null): string {
  if (!iso) return '';
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return '';
  return d.toISOString().slice(0, 10);
}

export function maxDateYearsFromToday(years: number): string {
  const d = new Date();
  d.setFullYear(d.getFullYear() + years);
  return d.toISOString().slice(0, 10);
}

export function certificateNumberFieldForDocument(
  key: DriverDocumentKey,
): keyof Pick<
  DriverDocumentFormState,
  'licence_number' | 'defensive_driving_certificate_number'
> | null {
  if (key === 'drivers_licence') return 'licence_number';
  if (key === 'defensive_driving_certificate') return 'defensive_driving_certificate_number';
  return null;
}

export function expiryFieldForDocument(
  key: DriverDocumentKey,
): keyof Pick<
  DriverDocumentFormState,
  | 'drivers_licence_expiry'
  | 'medical_certificate_expiry'
  | 'defensive_driving_certificate_expiry'
> {
  if (key === 'drivers_licence') return 'drivers_licence_expiry';
  if (key === 'medical_certificate') return 'medical_certificate_expiry';
  return 'defensive_driving_certificate_expiry';
}

export function getDocumentFieldConfig(key: DriverDocumentKey) {
  return DRIVER_DOCUMENT_FIELDS.find((field) => field.key === key);
}

export function validateDocumentExpiryInput(
  key: DriverDocumentKey,
  expiryValue: string,
  options?: { noExpiry?: boolean },
): string | null {
  const field = getDocumentFieldConfig(key);
  if (!field) return 'Unknown document type';

  if (field.expiryOptional && options?.noExpiry) return null;

  if (!field.expiryOptional && !expiryValue.trim()) {
    return `${field.label} expiry date is required.`;
  }

  if (!expiryValue.trim()) return null;

  const expiry = new Date(expiryValue);
  if (Number.isNaN(expiry.getTime())) {
    return `${field.label} expiry date is invalid.`;
  }

  if (field.maxYearsFromToday) {
    const max = new Date();
    max.setFullYear(max.getFullYear() + field.maxYearsFromToday);
    max.setHours(23, 59, 59, 999);
    if (expiry > max) {
      return `${field.shortLabel} expiry cannot be more than ${field.maxYearsFromToday} years from today.`;
    }
  }

  return null;
}

export function documentsFromDriver(driver: Driver): DriverDocumentFormState {
  const licenceDoc = driver.documents?.find((d) => d.key === 'drivers_licence');
  const hasLicenceExpiry =
    Boolean(driver.drivers_licence_expiry) || Boolean(licenceDoc?.expiry_date);

  return {
    licence_number:
      driver.licence_number ??
      driver.documents?.find((d) => d.key === 'drivers_licence')?.certificate_number ??
      '',
    drivers_licence_expiry: toDateInputValue(
      driver.drivers_licence_expiry ?? licenceDoc?.expiry_date,
    ),
    medical_certificate_expiry: toDateInputValue(
      driver.medical_certificate_expiry ??
        driver.documents?.find((d) => d.key === 'medical_certificate')?.expiry_date,
    ),
    defensive_driving_certificate_expiry: toDateInputValue(
      driver.defensive_driving_certificate_expiry ??
        driver.documents?.find((d) => d.key === 'defensive_driving_certificate')?.expiry_date,
    ),
    defensive_driving_certificate_number:
      driver.defensive_driving_certificate_number ??
      driver.documents?.find((d) => d.key === 'defensive_driving_certificate')?.certificate_number ??
      '',
    drivers_licence_no_expiry: Boolean(licenceDoc?.has_file) && !hasLicenceExpiry,
  };
}

export function getUploadExpiryForField(
  field: (typeof DRIVER_DOCUMENT_FIELDS)[number],
  docForm: DriverDocumentFormState,
): string | null {
  if (field.key === 'drivers_licence') {
    return docForm.drivers_licence_no_expiry
      ? null
      : docForm.drivers_licence_expiry.trim() || null;
  }
  return docForm[expiryFieldForDocument(field.key)].trim() || null;
}

export { severityStyles };

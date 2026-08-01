/** Shared validation for trip mileage + waybill fields. */

export const WAYBILL_NO_REGEX = /^\d{5}$/;

export const parseRequiredMileage = (
  value: unknown,
  fieldLabel: string,
): number => {
  const n =
    typeof value === 'number'
      ? value
      : typeof value === 'string'
        ? Number(value.trim())
        : NaN;
  if (!Number.isInteger(n) || n < 0) {
    throw new Error(`${fieldLabel} must be a whole number of 0 or greater`);
  }
  return n;
};

export const parseRequiredWaybillNo = (value: unknown): string => {
  const raw = typeof value === 'string' || typeof value === 'number'
    ? String(value).trim()
    : '';
  if (!WAYBILL_NO_REGEX.test(raw)) {
    throw new Error('Waybill number must be exactly 5 digits');
  }
  return raw;
};

export const assertClosingMileageValid = (
  closingMileage: number,
  startingMileage: number | null | undefined,
) => {
  if (
    startingMileage != null &&
    Number.isFinite(startingMileage) &&
    closingMileage < startingMileage
  ) {
    throw new Error(
      'Closing mileage cannot be less than the starting mileage',
    );
  }
};

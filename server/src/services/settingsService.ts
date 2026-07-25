import prisma from '../utils/prisma';
import { TICKET_CURRENCIES, isTicketCurrency } from '../utils/fareCurrency';

const SETTINGS_ID = 'default';

const defaultCurrencies = [...TICKET_CURRENCIES];

export type SystemSettingsRecord = {
  id: string;
  company_name: string;
  company_email: string | null;
  company_phone: string | null;
  support_email: string | null;
  enabled_currencies: unknown;
  default_currency: string;
  timezone: string;
  updated_at: Date;
  updated_by: string | null;
};

export const parseEnabledCurrencies = (raw: unknown): string[] => {
  if (Array.isArray(raw)) {
    return raw.map(String).filter(isTicketCurrency);
  }
  if (typeof raw === 'string') {
    try {
      const parsed = JSON.parse(raw);
      if (Array.isArray(parsed)) {
        return parsed.map(String).filter(isTicketCurrency);
      }
    } catch {
      return defaultCurrencies.slice();
    }
  }
  return defaultCurrencies.slice();
};

export const formatSystemSettings = (row: SystemSettingsRecord) => {
  const enabled = parseEnabledCurrencies(row.enabled_currencies);
  const currencies = enabled.length > 0 ? enabled : defaultCurrencies.slice();
  const defaultCurrency = currencies.includes(row.default_currency)
    ? row.default_currency
    : currencies[0];

  return {
    company_name: row.company_name,
    company_email: row.company_email,
    company_phone: row.company_phone,
    support_email: row.support_email,
    enabled_currencies: currencies,
    default_currency: defaultCurrency,
    timezone: row.timezone,
    updated_at: row.updated_at.toISOString(),
  };
};

export const ensureSystemSettings = async () => {
  const existing = await prisma.tblSystemSettings.findUnique({
    where: { id: SETTINGS_ID },
  });
  if (existing) return existing as SystemSettingsRecord;

  return prisma.tblSystemSettings.create({
    data: {
      id: SETTINGS_ID,
      company_name: 'CountryBoy',
      company_email: 'bus@countryboy.co.zw',
      enabled_currencies: defaultCurrencies,
      default_currency: 'USD',
      timezone: 'Africa/Harare',
    },
  }) as Promise<SystemSettingsRecord>;
};

export const getSystemSettings = async () => {
  const row = await ensureSystemSettings();
  return formatSystemSettings(row);
};

export type SystemSettingsInput = {
  company_name?: string;
  company_email?: string | null;
  company_phone?: string | null;
  support_email?: string | null;
  enabled_currencies?: string[];
  default_currency?: string;
  timezone?: string;
};

export const updateSystemSettings = async (
  data: SystemSettingsInput,
  updatedBy?: string,
) => {
  await ensureSystemSettings();

  let enabled = data.enabled_currencies
    ? data.enabled_currencies.filter(isTicketCurrency)
    : undefined;

  if (enabled && enabled.length === 0) {
    throw new Error('At least one currency must be enabled');
  }

  const current = await ensureSystemSettings();
  const nextEnabled =
    enabled ?? parseEnabledCurrencies(current.enabled_currencies);
  const nextDefault =
    data.default_currency ?? current.default_currency;

  if (!nextEnabled.includes(nextDefault)) {
    throw new Error('Default currency must be one of the enabled currencies');
  }

  const updated = await prisma.tblSystemSettings.update({
    where: { id: SETTINGS_ID },
    data: {
      ...(data.company_name !== undefined
        ? { company_name: data.company_name.trim() || 'CountryBoy' }
        : {}),
      ...(data.company_email !== undefined
        ? {
            company_email: data.company_email?.trim()
              ? data.company_email.trim()
              : null,
          }
        : {}),
      ...(data.company_phone !== undefined
        ? {
            company_phone: data.company_phone?.trim()
              ? data.company_phone.trim()
              : null,
          }
        : {}),
      ...(data.support_email !== undefined
        ? {
            support_email: data.support_email?.trim()
              ? data.support_email.trim()
              : null,
          }
        : {}),
      ...(enabled !== undefined ? { enabled_currencies: enabled } : {}),
      ...(data.default_currency !== undefined
        ? { default_currency: data.default_currency }
        : {}),
      ...(data.timezone !== undefined
        ? { timezone: data.timezone.trim() || 'Africa/Harare' }
        : {}),
      updated_by: updatedBy ?? null,
    },
  });

  return formatSystemSettings(updated as SystemSettingsRecord);
};

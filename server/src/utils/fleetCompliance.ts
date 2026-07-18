/** Fleet compliance document definitions and expiry alert helpers */

export const FLEET_COMPLIANCE_ITEMS = [
  {
    key: 'licence_disc_expiry',
    label: 'Vehicle Licence Disc',
    shortLabel: 'Licence Disc',
  },
  {
    key: 'cof_expiry',
    label: 'Certificate of Fitness',
    shortLabel: 'COF',
  },
  {
    key: 'passenger_liability_expiry',
    label: 'Passenger Liability Insurance',
    shortLabel: 'Liability Insurance',
  },
  {
    key: 'route_authority_expiry',
    label: 'Route Authority',
    shortLabel: 'Route Authority',
  },
  {
    key: 'ppa_expiry',
    label: 'Public Passenger Permit (PPA)',
    shortLabel: 'PPA',
  },
] as const;

export type FleetComplianceKey = (typeof FLEET_COMPLIANCE_ITEMS)[number]['key'];

export type AlertFrequency = 'monthly' | 'weekly' | 'daily';
export type AlertSeverity = 'ok' | 'info' | 'warning' | 'urgent' | 'expired';

export interface ComplianceAlertLevel {
  frequency: AlertFrequency | null;
  severity: AlertSeverity;
  daysRemaining: number;
  label: string;
}

/**
 * Escalating alert rules:
 * - > 30 days  → monthly notifications (info / green-leaning)
 * - 8–30 days  → weekly notifications (warning / amber)
 * - ≤ 7 days   → daily notifications (urgent / red)
 * - < 0 days   → expired (urgent / red)
 */
export function getComplianceAlertLevel(expiryDate: Date, now = new Date()): ComplianceAlertLevel {
  const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const expiryDay = new Date(expiryDate.getFullYear(), expiryDate.getMonth(), expiryDate.getDate());
  const msPerDay = 24 * 60 * 60 * 1000;
  const daysRemaining = Math.round((expiryDay.getTime() - startOfToday.getTime()) / msPerDay);

  if (daysRemaining < 0) {
    return {
      frequency: 'daily',
      severity: 'expired',
      daysRemaining,
      label: `Expired ${Math.abs(daysRemaining)} day${Math.abs(daysRemaining) === 1 ? '' : 's'} ago`,
    };
  }

  if (daysRemaining <= 7) {
    return {
      frequency: 'daily',
      severity: 'urgent',
      daysRemaining,
      label: daysRemaining === 0
        ? 'Expires today'
        : `Expires in ${daysRemaining} day${daysRemaining === 1 ? '' : 's'}`,
    };
  }

  if (daysRemaining <= 30) {
    return {
      frequency: 'weekly',
      severity: 'warning',
      daysRemaining,
      label: `Expires in ${daysRemaining} days`,
    };
  }

  return {
    frequency: 'monthly',
    severity: 'info',
    daysRemaining,
    label: `Valid — ${daysRemaining} days remaining`,
  };
}

export function parseDateInput(value: unknown): Date | null {
  if (value == null || value === '') return null;
  if (value instanceof Date) {
    return Number.isNaN(value.getTime()) ? null : value;
  }
  if (typeof value === 'string' || typeof value === 'number') {
    const d = new Date(value);
    return Number.isNaN(d.getTime()) ? null : d;
  }
  return null;
}

/** Shared fleet compliance field definitions (mirrors backend). */

import type { Fleet, FleetComplianceKey } from '@/types';

export const FLEET_COMPLIANCE_FIELDS = [
  {
    key: 'licence_disc_expiry' as const,
    label: 'Vehicle Licence Disc',
    hint: 'Licence disc expiry date',
  },
  {
    key: 'cof_expiry' as const,
    label: 'Certificate of Fitness',
    hint: 'COF expiry date',
  },
  {
    key: 'passenger_liability_expiry' as const,
    label: 'Passenger Liability Insurance',
    hint: 'Insurance policy expiry',
  },
  {
    key: 'route_authority_expiry' as const,
    label: 'Route Authority',
    hint: 'Route authority expiry',
  },
  {
    key: 'ppa_expiry' as const,
    label: 'Public Passenger Permit (PPA)',
    hint: 'PPA expiry date',
  },
];

export type ComplianceFormState = {
  licence_disc_expiry: string;
  cof_expiry: string;
  passenger_liability_expiry: string;
  route_authority_expiry: string;
  ppa_expiry: string;
};

export const emptyComplianceForm = (): ComplianceFormState => ({
  licence_disc_expiry: '',
  cof_expiry: '',
  passenger_liability_expiry: '',
  route_authority_expiry: '',
  ppa_expiry: '',
});

export function toDateInputValue(iso?: string | null): string {
  if (!iso) return '';
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return '';
  return d.toISOString().slice(0, 10);
}

export function complianceFromFleet(fleet: Fleet): ComplianceFormState {
  const fromKey = (key: FleetComplianceKey) => {
    const topLevel = toDateInputValue(fleet[key] as string | null | undefined);
    if (topLevel) return topLevel;
    const nested = fleet.compliance?.find((c) => c.key === key)?.expiry_date;
    return toDateInputValue(nested);
  };

  return {
    licence_disc_expiry: fromKey('licence_disc_expiry'),
    cof_expiry: fromKey('cof_expiry'),
    passenger_liability_expiry: fromKey('passenger_liability_expiry'),
    route_authority_expiry: fromKey('route_authority_expiry'),
    ppa_expiry: fromKey('ppa_expiry'),
  };
}

export const severityStyles: Record<
  string,
  { badge: string; bar: string; iconBg: string; iconText: string; ring: string }
> = {
  ok: {
    badge: 'bg-success/10 text-success border-success/20',
    bar: 'bg-success',
    iconBg: 'bg-success/10',
    iconText: 'text-success',
    ring: 'ring-success/20',
  },
  info: {
    badge: 'bg-success/10 text-success border-success/20',
    bar: 'bg-success',
    iconBg: 'bg-success/10',
    iconText: 'text-success',
    ring: 'ring-success/20',
  },
  warning: {
    badge: 'bg-amber-500/10 text-amber-700 border-amber-500/25 dark:text-amber-400',
    bar: 'bg-amber-500',
    iconBg: 'bg-amber-500/10',
    iconText: 'text-amber-600 dark:text-amber-400',
    ring: 'ring-amber-500/20',
  },
  urgent: {
    badge: 'bg-destructive/10 text-destructive border-destructive/25',
    bar: 'bg-destructive',
    iconBg: 'bg-destructive/10',
    iconText: 'text-destructive',
    ring: 'ring-destructive/20',
  },
  expired: {
    badge: 'bg-destructive/15 text-destructive border-destructive/30',
    bar: 'bg-destructive',
    iconBg: 'bg-destructive/15',
    iconText: 'text-destructive',
    ring: 'ring-destructive/25',
  },
};

export const frequencyStyles: Record<string, string> = {
  monthly: 'bg-success/10 text-success border-success/20',
  weekly: 'bg-amber-500/10 text-amber-700 border-amber-500/25 dark:text-amber-400',
  daily: 'bg-destructive/10 text-destructive border-destructive/25',
};

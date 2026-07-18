import * as fleetService from './fleetService';
import {
  FLEET_COMPLIANCE_ITEMS,
  getComplianceAlertLevel,
  type AlertFrequency,
  type AlertSeverity,
} from '../utils/fleetCompliance';

export type FleetComplianceNotification = {
  id: string;
  category: 'fleet_compliance';
  title: string;
  message: string;
  type: 'info' | 'warning' | 'error' | 'success';
  severity: AlertSeverity;
  frequency: AlertFrequency;
  frequency_label: string;
  fleet_id: string;
  fleet_number: string;
  depot_id: string;
  depot_name: string | null;
  compliance_key: string;
  compliance_label: string;
  expiry_date: string;
  days_remaining: number;
  time: string;
  created_at: string;
};

const FREQUENCY_LABEL: Record<AlertFrequency, string> = {
  monthly: 'Monthly alert',
  weekly: 'Weekly alert',
  daily: 'Daily alert',
};

function severityToType(severity: AlertSeverity): FleetComplianceNotification['type'] {
  switch (severity) {
    case 'expired':
    case 'urgent':
      return 'error';
    case 'warning':
      return 'warning';
    case 'info':
      return 'info';
    default:
      return 'success';
  }
}

function formatRelative(daysRemaining: number): string {
  if (daysRemaining < 0) {
    const ago = Math.abs(daysRemaining);
    return ago === 0 ? 'Expired' : `Expired ${ago}d ago`;
  }
  if (daysRemaining === 0) return 'Expires today';
  if (daysRemaining === 1) return 'Expires tomorrow';
  return `${daysRemaining} days left`;
}

/**
 * Builds in-app notification payloads from fleet compliance expiry dates.
 * Escalation: monthly (>30d) → weekly (8–30d) → daily (≤7d / expired).
 */
export const getFleetComplianceNotifications = async (
  depotId?: string
): Promise<FleetComplianceNotification[]> => {
  const fleets = await fleetService.listFleets(depotId);
  const now = new Date();
  const notifications: FleetComplianceNotification[] = [];

  for (const fleet of fleets) {
    for (const item of FLEET_COMPLIANCE_ITEMS) {
      const raw = (fleet as any)[item.key] as Date | null | undefined;
      if (!raw) {
        notifications.push({
          id: `fleet-compliance:${fleet.id}:${item.key}:missing`,
          category: 'fleet_compliance',
          title: `${item.shortLabel} missing — ${fleet.number}`,
          message: `${item.label} has no expiry date set for fleet ${fleet.number}${
            fleet.depot?.name ? ` at ${fleet.depot.name}` : ''
          }. Update the fleet record to enable compliance tracking.`,
          type: 'error',
          severity: 'expired',
          frequency: 'daily',
          frequency_label: FREQUENCY_LABEL.daily,
          fleet_id: fleet.id,
          fleet_number: fleet.number,
          depot_id: fleet.depot_id,
          depot_name: fleet.depot?.name ?? null,
          compliance_key: item.key,
          compliance_label: item.label,
          expiry_date: '',
          days_remaining: -999,
          time: 'Action required',
          created_at: now.toISOString(),
        });
        continue;
      }

      const expiry = new Date(raw);
      const level = getComplianceAlertLevel(expiry, now);
      if (!level.frequency) continue;

      // Always surface monthly/weekly/daily so admins can see the full cadence board.
      notifications.push({
        id: `fleet-compliance:${fleet.id}:${item.key}:${level.frequency}`,
        category: 'fleet_compliance',
        title: `${item.shortLabel} — ${fleet.number}`,
        message: `${item.label} for fleet ${fleet.number}${
          fleet.depot?.name ? ` (${fleet.depot.name})` : ''
        } ${level.label.toLowerCase()}. Expiry: ${expiry.toISOString().slice(0, 10)}.`,
        type: severityToType(level.severity),
        severity: level.severity,
        frequency: level.frequency,
        frequency_label: FREQUENCY_LABEL[level.frequency],
        fleet_id: fleet.id,
        fleet_number: fleet.number,
        depot_id: fleet.depot_id,
        depot_name: fleet.depot?.name ?? null,
        compliance_key: item.key,
        compliance_label: item.label,
        expiry_date: expiry.toISOString(),
        days_remaining: level.daysRemaining,
        time: formatRelative(level.daysRemaining),
        created_at: now.toISOString(),
      });
    }
  }

  // Sort: expired/urgent first, then warning, then info; within same severity by days remaining
  const severityRank: Record<AlertSeverity, number> = {
    expired: 0,
    urgent: 1,
    warning: 2,
    info: 3,
    ok: 4,
  };

  notifications.sort((a, b) => {
    const sr = severityRank[a.severity] - severityRank[b.severity];
    if (sr !== 0) return sr;
    return a.days_remaining - b.days_remaining;
  });

  return notifications;
};

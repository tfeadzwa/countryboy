// ---- ENUMS ----
export type TicketCategory = "PASSENGER" | "LUGGAGE";
export type PaymentNature = "CASH" | "MOBILE" | "CARD";
export type Currency = "USD" | "ZWL" | "ZAR";
export type TripStatus = "ACTIVE" | "ENDED" | "CANCELLED";
export type AgentStatus = "ACTIVE" | "SUSPENDED" | "INACTIVE";
export type DeviceStatus = "REGISTERED" | "BLOCKED";
export type AdminRole = "SUPER_ADMIN" | "DEPOT_ADMIN" | "MANAGER" | "VIEWER";

// ---- ENTITIES ----
export interface AdminUser {
  id: string;
  username: string;
  full_name: string;
  email: string;
  role: AdminRole;
  roles?: AdminRole[]; // Allow multiple roles
  depot_id?: string;
  depot_name?: string;
}

export interface Depot {
  id: string;
  merchant_code: string;
  name: string;
  location: string;
  created_at: string;
}

export interface Agent {
  id: string;
  username: string;
  merchant_code: string;
  agent_code: string;
  full_name: string;
  depot_id: string;
  depot_name?: string;
  status: AgentStatus;
  created_at: string;
  pin: string;
}

export type ComplianceSeverity = 'ok' | 'info' | 'warning' | 'urgent' | 'expired';
export type AlertFrequency = 'monthly' | 'weekly' | 'daily';

export type FleetComplianceKey =
  | 'licence_disc_expiry'
  | 'cof_expiry'
  | 'passenger_liability_expiry'
  | 'route_authority_expiry'
  | 'ppa_expiry';

export interface FleetComplianceItem {
  key: FleetComplianceKey;
  label: string;
  shortLabel: string;
  expiry_date: string | null;
  days_remaining: number | null;
  frequency: AlertFrequency | null;
  severity: ComplianceSeverity;
  status_label: string;
}

export interface Fleet {
  id: string;
  number: string;
  depot_id: string;
  depot_name?: string | null;
  status: 'ACTIVE' | 'MAINTENANCE' | 'OUT_OF_SERVICE' | 'RETIRED';
  capacity: number;
  licence_disc_expiry?: string | null;
  cof_expiry?: string | null;
  passenger_liability_expiry?: string | null;
  route_authority_expiry?: string | null;
  ppa_expiry?: string | null;
  compliance?: FleetComplianceItem[];
  compliance_summary?: {
    worst_severity: ComplianceSeverity;
    items_needing_attention: number;
  };
  created_at: string;
  updated_at: string;
  created_by?: string;
  updated_by?: string;
}

export interface FleetComplianceNotification {
  id: string;
  category: 'fleet_compliance';
  title: string;
  message: string;
  type: 'info' | 'warning' | 'error' | 'success';
  severity: ComplianceSeverity;
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
}

export interface NotificationsResponse {
  notifications: FleetComplianceNotification[];
  summary: {
    total: number;
    urgent: number;
    warning: number;
    monthly: number;
    weekly: number;
    daily: number;
    attention_count: number;
  };
}

export interface RouteLinkSummary {
  id: string;
  origin: string;
  destination: string;
  label: string;
  is_active?: boolean;
}

export interface RouteInfo {
  id: string;
  origin: string;
  destination: string;
  depot_id: string;
  depot_name?: string;
  parent_route_ids?: string[];
  parent_routes?: RouteLinkSummary[];
  parent_route_labels?: string[];
  child_route_ids?: string[];
  child_routes?: RouteLinkSummary[];
  child_route_labels?: string[];
  /** @deprecated Prefer parent_route_ids — kept for compatibility */
  parent_route_id?: string | null;
  /** @deprecated Prefer parent_route_labels */
  parent_route_label?: string | null;
  is_active: boolean;
  distance_km?: number | string;
  created_at: string;
  updated_at: string;
  created_by?: string;
  updated_by?: string;
}

export interface Fare {
  id: string;
  route_id: string;
  route_label?: string;
  depot_id: string;
  depot_name?: string;
  currency: string;
  amount: number | string;
  created_at: string;
  updated_at: string;
  created_by?: string;
  updated_by?: string;
}

export interface Trip {
  id: string;
  depot_id: string;
  depot_name?: string;
  agent_id: string;
  agent_name?: string;
  fleet_id: string;
  fleet_number?: string;
  route_id?: string;
  route_label?: string;
  status: TripStatus;
  started_at: string;
  ended_at?: string;
  started_offline?: boolean;
  ticket_count?: number;
  total_revenue?: number;
  created_at?: string;
  updated_at?: string;
}

export interface Ticket {
  id: string;
  depot_id: string;
  trip_id: string;
  agent_id: string;
  device_id?: string;
  serial_number?: number;
  ticket_category: string;
  currency: string;
  amount: number;
  departure?: string;
  destination?: string;
  linked_passenger_ticket_id?: string;
  issued_at: string;
  created_at: string;
  updated_at: string;
  // Additional fields from backend
  is_voided: boolean;
  agent_name?: string;
  fleet_number?: string;
  route_label?: string;
  depot_name?: string;
  voids?: Array<{
    id: string;
    reason: string;
    created_at: string;
    agent_id?: string;
    device_id?: string;
    admin_user_id?: string;
  }>;
}

export interface DeviceAgentSummary {
  id: string;
  full_name: string;
  agent_code: string;
}

export interface DeviceActiveSession {
  id: string;
  started_at: string;
  login_type: string;
  agent?: DeviceAgentSummary | null;
}

export interface DeviceSession {
  id: string;
  depot_id: string;
  device_id: string;
  agent_id: string;
  started_at: string;
  ended_at?: string | null;
  end_reason?: string | null;
  app_version?: string | null;
  login_type: string;
  agent?: DeviceAgentSummary;
  device?: { id: string; serial_number: string };
}

export interface Device {
  id: string;
  serial_number: string;
  token?: string;
  pairing_code?: string;
  paired: boolean;
  paired_at?: string;
  depot_id: string;
  depot_name?: string;
  device_name?: string;
  device_model?: string;
  last_seen?: string;
  last_agent_id?: string | null;
  last_agent_login_at?: string | null;
  last_agent?: DeviceAgentSummary | null;
  active_session?: DeviceActiveSession | null;
  app_version?: string;
  sync_errors: number;
  created_at: string;
  updated_at: string;
  created_by?: string;
  updated_by?: string;
}

// ---- DASHBOARD ----
export interface DailySales {
  date: string;
  usd: number;
  zwl: number;
  zar: number;
  ticket_count: number;
}

// ---- ENUMS ----
export type TicketCategory = "PASSENGER" | "LUGGAGE";
export type PaymentNature = "CASH" | "MOBILE" | "CARD";
export type Currency = "USD" | "ZWL" | "ZAR";
export type TripStatus = "ACTIVE" | "ENDED" | "COMPLETED" | "CANCELLED";
export type AgentStatus = "ACTIVE" | "SUSPENDED" | "INACTIVE";
export type DeviceStatus = "REGISTERED" | "BLOCKED";
export type AdminRole =
  | "SUPER_ADMIN"
  | "DEPOT_ADMIN"
  | "CASHIER"
  | "MANAGER"
  | "VIEWER";

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
  is_online?: boolean;
  conductor_status?: "online" | "offline" | null;
  last_seen?: string | null;
  active_session?: {
    id: string;
    device_id: string;
    device_serial?: string | null;
    started_at: string;
    login_type: string;
  } | null;
  active_trip?: AgentActiveTrip | null;
}

export interface AgentActiveTrip {
  id: string;
  origin: string;
  destination: string;
  fleet_id?: string;
  fleet_number?: string | null;
  driver_id?: string | null;
  driver_name?: string | null;
  route_id?: string | null;
  route_origin?: string | null;
  route_destination?: string | null;
  started_at: string;
  started_offline?: boolean;
}

export type DriverStatus = "ACTIVE" | "INACTIVE" | "SUSPENDED";
export type DriverDutyStatus = "on_trip" | "available" | "off_duty";

export interface DriverActiveTrip {
  id: string;
  origin: string;
  destination: string;
  fleet_number?: string | null;
  agent_id?: string | null;
  agent_name?: string | null;
  agent_code?: string | null;
  started_at: string;
}

export interface Driver {
  id: string;
  full_name: string;
  employee_code?: string | null;
  phone?: string | null;
  licence_number?: string | null;
  depot_id: string;
  depot_name?: string | null;
  status: DriverStatus;
  duty_status?: DriverDutyStatus;
  on_trip?: boolean;
  active_trip?: DriverActiveTrip | null;
  created_at: string;
  updated_at: string;
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
  registration_number?: string | null;
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
  origin?: string;
  destination?: string;
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

export interface TripDetailTicket {
  id: string;
  serial_number?: number | null;
  ticket_category: string;
  currency: string;
  amount: number;
  luggage_amount?: number | null;
  departure?: string | null;
  destination?: string | null;
  passenger_name?: string | null;
  passenger_phone?: string | null;
  luggage_description?: string | null;
  printed?: boolean;
  printed_at?: string | null;
  printer_name?: string | null;
  printer_mac?: string | null;
  printer_serial?: string | null;
  issued_at: string;
  is_voided: boolean;
  voids?: Array<{
    id: string;
    reason: string;
    created_at: string;
    agent_id?: string | null;
    device_id?: string | null;
    admin_user_id?: string | null;
  }>;
}

export interface TripDetail extends Trip {
  depot_merchant_code?: string | null;
  agent_code?: string | null;
  agent_username?: string | null;
  agent_status?: string | null;
  conductor_presence?: "online" | "offline" | "signed_out" | null;
  conductor_is_online?: boolean;
  driver_id?: string | null;
  driver_name?: string | null;
  driver_phone?: string | null;
  driver_licence?: string | null;
  driver_employee_code?: string | null;
  driver_status?: string | null;
  driver_duty_status?: "on_trip" | "available" | "off_duty" | null;
  fleet_registration_number?: string | null;
  fleet_capacity?: number | null;
  fleet_status?: string | null;
  device_id?: string | null;
  device_serial?: string | null;
  device_name?: string | null;
  device_model?: string | null;
  device_paired?: boolean | null;
  device_last_seen?: string | null;
  device_presence?: "online" | "offline" | "unpaired" | null;
  route_origin?: string | null;
  route_destination?: string | null;
  duration_ms?: number;
  voided_ticket_count?: number;
  revenue_by_currency?: Record<string, number>;
  category_counts?: Record<string, number>;
  tickets?: TripDetailTicket[];
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
  printed?: boolean;
  printed_at?: string | null;
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
  printer_name?: string | null;
  printer_mac?: string | null;
  printer_serial?: string | null;
  last_seen?: string;
  last_agent_id?: string | null;
  last_agent_login_at?: string | null;
  last_agent?: DeviceAgentSummary | null;
  active_session?: DeviceActiveSession | null;
  /** True when open session + recent heartbeat (last_seen within ~90s). */
  is_online?: boolean;
  /** online | offline when a conductor session is open; null otherwise. */
  conductor_status?: "online" | "offline" | null;
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

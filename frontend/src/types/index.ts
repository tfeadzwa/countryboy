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

export interface Fleet {
  id: string;
  number: string;
  depot_id: string;
  depot_name?: string;
  status: 'ACTIVE' | 'MAINTENANCE' | 'OUT_OF_SERVICE' | 'RETIRED';
  capacity: number;
  created_at: string;
  updated_at: string;
  created_by?: string;
  updated_by?: string;
}

export interface RouteInfo {
  id: string;
  origin: string;
  destination: string;
  depot_id: string;
  depot_name?: string;
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

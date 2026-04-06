import type { Depot, Agent, Fleet, RouteInfo, Fare, Trip, Ticket, DailySales, Device, AdminUser } from "@/types";

// ---- CURRENT ADMIN (mock) ----
export const currentAdmin: AdminUser = {
  id: "admin1",
  username: "superadmin",
  full_name: "Admin User",
  email: "admin@busticket.co",
  role: "SUPER_ADMIN",
};

export const depots: Depot[] = [
  { id: "d1", merchant_code: "MRC-001", name: "Harare Central", location: "Harare CBD", created_at: "2025-01-15" },
  { id: "d2", merchant_code: "MRC-002", name: "Bulawayo Main", location: "Bulawayo CBD", created_at: "2025-01-20" },
  { id: "d3", merchant_code: "MRC-003", name: "Mutare Depot", location: "Mutare Town", created_at: "2025-02-01" },
  { id: "d4", merchant_code: "MRC-004", name: "Gweru Terminal", location: "Gweru Centre", created_at: "2025-02-10" },
];

export const agents: Agent[] = [
  { id: "a1", username: "jmoyo", merchant_code: "MRC3B4", agent_code: "AGT3B4", full_name: "James Moyo", depot_id: "d1", depot_name: "Harare Central", status: "ACTIVE", created_at: "2025-01-16", pin: "1234" },
  { id: "a2", username: "tnkomo", merchant_code: "MRC7D8", agent_code: "AGT7D8", full_name: "Tendai Nkomo", depot_id: "d1", depot_name: "Harare Central", status: "ACTIVE", created_at: "2025-01-17", pin: "5678" },
  { id: "a3", username: "smaposa", merchant_code: "MRCF1G", agent_code: "AGTF1G", full_name: "Sarah Maposa", depot_id: "d2", depot_name: "Bulawayo Main", status: "SUSPENDED", created_at: "2025-01-22", pin: "9012" },
  { id: "a4", username: "dchirwa", merchant_code: "MRC3K4", agent_code: "AGT3K4", full_name: "David Chirwa", depot_id: "d3", depot_name: "Mutare Depot", status: "ACTIVE", created_at: "2025-02-03", pin: "3456" },
];

export const fleets: Fleet[] = [
  { id: "f1", number: "FL-001", capacity: 65, depot_id: "d1", depot_name: "Harare Central", status: "ACTIVE", created_at: "2025-01-16", updated_at: "2025-01-16" },
  { id: "f2", number: "FL-002", capacity: 45, depot_id: "d1", depot_name: "Harare Central", status: "ACTIVE", created_at: "2025-01-17", updated_at: "2025-01-17" },
  { id: "f3", number: "FL-003", capacity: 65, depot_id: "d2", depot_name: "Bulawayo Main", status: "OUT_OF_SERVICE", created_at: "2025-01-22", updated_at: "2025-01-22" },
  { id: "f4", number: "FL-004", capacity: 30, depot_id: "d3", depot_name: "Mutare Depot", status: "ACTIVE", created_at: "2025-02-03", updated_at: "2025-02-03" },
];

export const routes: RouteInfo[] = [
  { id: "r1", origin: "Harare", destination: "Bulawayo", depot_id: "d1", distance_km: 439, is_active: true, created_at: "2025-01-15", updated_at: "2025-01-15" },
  { id: "r2", origin: "Harare", destination: "Mutare", depot_id: "d1", distance_km: 263, is_active: true, created_at: "2025-01-15", updated_at: "2025-01-15" },
  { id: "r3", origin: "Bulawayo", destination: "Victoria Falls", depot_id: "d2", distance_km: 440, is_active: true, created_at: "2025-01-20", updated_at: "2025-01-20" },
  { id: "r4", origin: "Harare", destination: "Masvingo", depot_id: "d1", distance_km: 292, is_active: false, created_at: "2025-02-01", updated_at: "2025-02-01" },
];

export const fares: Fare[] = [
  { id: "fr1", route_id: "r1", route_label: "Harare → Bulawayo", depot_id: "d1", currency: "USD", amount: 15.00, created_at: "2025-01-01", updated_at: "2025-01-01" },
  { id: "fr2", route_id: "r1", route_label: "Harare → Bulawayo", depot_id: "d1", currency: "USD", amount: 5.00, created_at: "2025-01-01", updated_at: "2025-01-01" },
  { id: "fr3", route_id: "r2", route_label: "Harare → Mutare", depot_id: "d1", currency: "USD", amount: 10.00, created_at: "2025-01-01", updated_at: "2025-01-01" },
  { id: "fr4", route_id: "r1", route_label: "Harare → Bulawayo", depot_id: "d1", currency: "ZWL", amount: 5000, created_at: "2025-01-01", updated_at: "2025-01-01" },
];

export const trips: Trip[] = [
  { id: "t1", fleet_number: "FL-001", agent_id: "a1", agent_name: "James Moyo", depot_id: "d1", depot_name: "Harare Central", status: "ENDED", started_at: "2025-02-28T06:00:00Z", ended_at: "2025-02-28T14:00:00Z", ticket_count: 42, total_revenue: 630 },
  { id: "t2", fleet_number: "FL-002", agent_id: "a2", agent_name: "Tendai Nkomo", depot_id: "d1", depot_name: "Harare Central", status: "ACTIVE", started_at: "2025-02-28T07:30:00Z", ticket_count: 18, total_revenue: 180 },
  { id: "t3", fleet_number: "FL-003", agent_id: "a3", agent_name: "Sarah Maposa", depot_id: "d2", depot_name: "Bulawayo Main", status: "ENDED", started_at: "2025-02-27T05:30:00Z", ended_at: "2025-02-27T13:00:00Z", ticket_count: 55, total_revenue: 825 },
  { id: "t4", fleet_number: "FL-004", agent_id: "a4", agent_name: "David Chirwa", depot_id: "d3", depot_name: "Mutare Depot", status: "ACTIVE", started_at: "2025-02-28T08:00:00Z", ticket_count: 12, total_revenue: 120 },
];

export const tickets: Ticket[] = [
  { id: "tk1", trip_id: "t1", ticket_category: "PASSENGER", fleet_number: "FL-001", departure: "Harare", destination: "Bulawayo", currency: "USD", amount: 15, payment_nature: "CASH", agent_id: "a1", agent_name: "James Moyo", depot_id: "d1", depot_name: "Harare Central", device_id: "dev1", issued_at: "2025-02-28T06:15:00Z", server_received_at: "2025-02-28T06:16:00Z", serial_number: "SN-000001", is_voided: false },
  { id: "tk2", trip_id: "t1", ticket_category: "PASSENGER", fleet_number: "FL-001", departure: "Harare", destination: "Bulawayo", currency: "USD", amount: 15, payment_nature: "CASH", agent_id: "a1", agent_name: "James Moyo", depot_id: "d1", depot_name: "Harare Central", device_id: "dev1", issued_at: "2025-02-28T06:17:00Z", server_received_at: "2025-02-28T06:18:00Z", serial_number: "SN-000002", is_voided: false },
  { id: "tk3", trip_id: "t1", ticket_category: "PASSENGER", fleet_number: "FL-001", departure: "Harare", destination: "Bulawayo", currency: "ZWL", amount: 5000, payment_nature: "CASH", agent_id: "a1", agent_name: "James Moyo", depot_id: "d1", depot_name: "Harare Central", device_id: "dev1", issued_at: "2025-02-28T06:20:00Z", serial_number: "SN-000003", is_voided: false },
  { id: "tk4", trip_id: "t1", ticket_category: "LUGGAGE", linked_passenger_ticket_id: "tk1", fleet_number: "FL-001", departure: "Harare", destination: "Bulawayo", currency: "USD", amount: 5, payment_nature: "CASH", agent_id: "a1", agent_name: "James Moyo", depot_id: "d1", depot_name: "Harare Central", device_id: "dev1", issued_at: "2025-02-28T06:15:30Z", server_received_at: "2025-02-28T06:16:00Z", serial_number: "SN-000004", is_voided: false },
  { id: "tk5", trip_id: "t2", ticket_category: "PASSENGER", fleet_number: "FL-002", departure: "Harare", destination: "Mutare", currency: "USD", amount: 10, payment_nature: "CASH", agent_id: "a2", agent_name: "Tendai Nkomo", depot_id: "d1", depot_name: "Harare Central", device_id: "dev2", issued_at: "2025-02-28T07:45:00Z", serial_number: "SN-000005", is_voided: true },
  { id: "tk6", trip_id: "t3", ticket_category: "PASSENGER", fleet_number: "FL-003", departure: "Bulawayo", destination: "Victoria Falls", currency: "USD", amount: 15, payment_nature: "CASH", agent_id: "a3", agent_name: "Sarah Maposa", depot_id: "d2", depot_name: "Bulawayo Main", device_id: "dev3", issued_at: "2025-02-27T05:50:00Z", server_received_at: "2025-02-27T05:51:00Z", serial_number: "SN-000006", is_voided: false },
];

export const devices: Device[] = [
  { id: "dev1", serial_number: "DEV-HRE-001", depot_id: "d1", depot_name: "Harare Central", paired: true, paired_at: "2025-01-16", last_seen: "2025-02-28T14:30:00Z", sync_errors: 0, created_at: "2025-01-16", updated_at: "2025-02-28" },
  { id: "dev2", serial_number: "DEV-HRE-002", depot_id: "d1", depot_name: "Harare Central", paired: true, paired_at: "2025-01-17", last_seen: "2025-02-28T12:15:00Z", sync_errors: 0, created_at: "2025-01-17", updated_at: "2025-02-28" },
  { id: "dev3", serial_number: "DEV-BYO-001", depot_id: "d2", depot_name: "Bulawayo Main", paired: true, paired_at: "2025-01-22", last_seen: "2025-02-27T13:00:00Z", sync_errors: 0, created_at: "2025-01-22", updated_at: "2025-02-27" },
  { id: "dev4", serial_number: "DEV-MUT-001", depot_id: "d3", depot_name: "Mutare Depot", paired: false, last_seen: "2025-02-20T09:00:00Z", sync_errors: 3, created_at: "2025-02-03", updated_at: "2025-02-20" },
  { id: "dev5", serial_number: "DEV-GWE-001", depot_id: "d4", depot_name: "Gweru Terminal", paired: true, paired_at: "2025-02-10", sync_errors: 0, created_at: "2025-02-10", updated_at: "2025-02-10" },
];

export const dailySales: DailySales[] = [
  { date: "2025-02-22", usd: 450, zwl: 25000, zar: 800, ticket_count: 38 },
  { date: "2025-02-23", usd: 620, zwl: 30000, zar: 1200, ticket_count: 52 },
  { date: "2025-02-24", usd: 380, zwl: 18000, zar: 600, ticket_count: 30 },
  { date: "2025-02-25", usd: 710, zwl: 35000, zar: 1500, ticket_count: 61 },
  { date: "2025-02-26", usd: 540, zwl: 28000, zar: 900, ticket_count: 45 },
  { date: "2025-02-27", usd: 825, zwl: 42000, zar: 1800, ticket_count: 68 },
  { date: "2025-02-28", usd: 930, zwl: 45000, zar: 2100, ticket_count: 72 },
];

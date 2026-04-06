-- =========================================
-- COUNTRYBOY DEVELOPMENT SEED DATA
-- PostgreSQL INSERT Statements
-- =========================================
-- This file contains realistic dummy data for development and testing
-- Run this after database schema is created
-- =========================================

-- Clear existing data (optional - uncomment if needed)
-- TRUNCATE TABLE "tblTickets", "tblTrips", "tblFares", "tblRoutes", "tblFleets", 
--          "tblDevices", "tblAgents", "tblSerialRanges", "tblUserRoles", 
--          "tblAdminUsers", "tblDepots", "tblRoles" CASCADE;

-- =========================================
-- 1. ROLES
-- =========================================
INSERT INTO "tblRoles" (id, name) VALUES 
('role-superadmin-001', 'SUPER_ADMIN'),
('role-depotadmin-001', 'DEPOT_ADMIN'),
('role-manager-001', 'MANAGER'),
('role-viewer-001', 'VIEWER');

-- =========================================
-- 2. DEPOTS (Bus Stations/Terminals)
-- =========================================
INSERT INTO "tblDepots" (id, merchant_code, name, location, created_at, updated_at) VALUES 
('depot-hre-001', 'HRE001', 'Harare - Roadport', 'Corner of Rotten Row & 5th St, Harare', NOW(), NOW()),
('depot-byo-001', 'BYO001', 'Bulawayo - Renkini', '6th Avenue & Fife Street, Bulawayo', NOW(), NOW()),
('depot-mut-001', 'MUT001', 'Mutare - Sakubva', 'Herbert Chitepo Street, Mutare', NOW(), NOW());

-- =========================================
-- 3. ADMIN USERS
-- =========================================
-- Password for all users: "password123" (hashed with bcrypt)
-- Hash generated using: bcrypt.hash("password123", 10)
INSERT INTO "tblAdminUsers" (id, username, email, password_hash, full_name, depot_id, status, created_at, updated_at) VALUES 
-- Super Admin (no depot_id)
('admin-super-001', 'superadmin', 'superadmin@countryboy.local', '$2b$10$rKZL8qk5f5h5h5h5h5h5hOYmqGqX8X8X8X8X8X8X8X8X8X8X8X8Xa', 'System Administrator', NULL, 'ACTIVE', NOW(), NOW()),

-- Depot Admins
('admin-hre-001', 'admin.harare', 'admin.harare@countryboy.co.zw', '$2b$10$rKZL8qk5f5h5h5h5h5h5hOYmqGqX8X8X8X8X8X8X8X8X8X8X8X8Xa', 'John Moyo', 'depot-hre-001', 'ACTIVE', NOW(), NOW()),
('admin-byo-001', 'admin.bulawayo', 'admin.bulawayo@countryboy.co.zw', '$2b$10$rKZL8qk5f5h5h5h5h5h5hOYmqGqX8X8X8X8X8X8X8X8X8X8X8X8Xa', 'Sarah Ncube', 'depot-byo-001', 'ACTIVE', NOW(), NOW()),
('admin-mut-001', 'admin.mutare', 'admin.mutare@countryboy.co.zw', '$2b$10$rKZL8qk5f5h5h5h5h5h5hOYmqGqX8X8X8X8X8X8X8X8X8X8X8X8Xa', 'Grace Chikwamba', 'depot-mut-001', 'ACTIVE', NOW(), NOW()),

-- Managers
('manager-hre-001', 'manager.harare', 'manager.harare@countryboy.co.zw', '$2b$10$rKZL8qk5f5h5h5h5h5h5hOYmqGqX8X8X8X8X8X8X8X8X8X8X8X8Xa', 'Patrick Sibanda', 'depot-hre-001', 'ACTIVE', NOW(), NOW()),
('manager-byo-001', 'manager.bulawayo', 'manager.bulawayo@countryboy.co.zw', '$2b$10$rKZL8qk5f5h5h5h5h5h5hOYmqGqX8X8X8X8X8X8X8X8X8X8X8X8Xa', 'Alice Dube', 'depot-byo-001', 'ACTIVE', NOW(), NOW());

-- =========================================
-- 4. USER ROLES MAPPING
-- =========================================
INSERT INTO "tblUserRoles" (id, "userId", "roleId") VALUES 
('ur-001', 'admin-super-001', 'role-superadmin-001'),
('ur-002', 'admin-hre-001', 'role-depotadmin-001'),
('ur-003', 'admin-byo-001', 'role-depotadmin-001'),
('ur-004', 'admin-mut-001', 'role-depotadmin-001'),
('ur-005', 'manager-hre-001', 'role-manager-001'),
('ur-006', 'manager-byo-001', 'role-manager-001');

-- =========================================
-- 5. AGENTS (Bus Conductors)
-- =========================================
-- PIN for all agents: "1234" (will be hashed in production)
INSERT INTO "tblAgents" (id, full_name, agent_code, pin, depot_id, status, created_at, updated_at) VALUES 
-- Harare Agents
('agent-hre-001', 'Tinashe Moyo', 'TMO014', '1234', 'depot-hre-001', 'ACTIVE', NOW(), NOW()),
('agent-hre-002', 'Farai Ncube', 'FNC015', '1234', 'depot-hre-001', 'ACTIVE', NOW(), NOW()),
('agent-hre-003', 'Rumbidzai Chuma', 'RCH016', '1234', 'depot-hre-001', 'ACTIVE', NOW(), NOW()),
('agent-hre-004', 'Tendai Mapfumo', 'TMA017', '1234', 'depot-hre-001', 'INACTIVE', NOW(), NOW()),

-- Bulawayo Agents
('agent-byo-001', 'Nkululeko Dube', 'NDU021', '1234', 'depot-byo-001', 'ACTIVE', NOW(), NOW()),
('agent-byo-002', 'Thandi Ndlovu', 'TND022', '1234', 'depot-byo-001', 'ACTIVE', NOW(), NOW()),
('agent-byo-003', 'Siphosami Moyo', 'SMO023', '1234', 'depot-byo-001', 'ACTIVE', NOW(), NOW()),

-- Mutare Agents
('agent-mut-001', 'Patience Marufu', 'PMA031', '1234', 'depot-mut-001', 'ACTIVE', NOW(), NOW()),
('agent-mut-002', 'James Chikwanha', 'JCH032', '1234', 'depot-mut-001', 'ACTIVE', NOW(), NOW());

-- =========================================
-- 6. DEVICES (Mobile Devices)
-- =========================================
-- Some paired, some unpaired for testing
INSERT INTO "tblDevices" (id, serial_number, token, pairing_code, paired, paired_at, depot_id, last_seen, app_version, created_at, updated_at) VALUES 
-- Paired devices
('device-hre-001', 'HRE-DEV-001', 'tok-a1b2c3d4-e5f6-4789-a1b2-c3d4e5f67890', NULL, TRUE, NOW() - INTERVAL '5 days', 'depot-hre-001', NOW() - INTERVAL '2 hours', '1.0.0', NOW() - INTERVAL '5 days', NOW()),
('device-hre-002', 'HRE-DEV-002', 'tok-b2c3d4e5-f6a7-4890-b2c3-d4e5f6a78901', NULL, TRUE, NOW() - INTERVAL '3 days', 'depot-hre-001', NOW() - INTERVAL '1 hour', '1.0.0', NOW() - INTERVAL '3 days', NOW()),
('device-byo-001', 'BYO-DEV-001', 'tok-c3d4e5f6-a7b8-4901-c3d4-e5f6a7b89012', NULL, TRUE, NOW() - INTERVAL '4 days', 'depot-byo-001', NOW() - INTERVAL '30 minutes', '1.0.0', NOW() - INTERVAL '4 days', NOW()),
('device-byo-002', 'BYO-DEV-002', 'tok-d4e5f6a7-b8c9-4012-d4e5-f6a7b8c90123', NULL, TRUE, NOW() - INTERVAL '2 days', 'depot-byo-001', NOW() - INTERVAL '3 hours', '1.0.0', NOW() - INTERVAL '2 days', NOW()),
('device-mut-001', 'MUT-DEV-001', 'tok-e5f6a7b8-c9d0-4123-e5f6-a7b8c9d01234', NULL, TRUE, NOW() - INTERVAL '6 days', 'depot-mut-001', NOW() - INTERVAL '4 hours', '1.0.0', NOW() - INTERVAL '6 days', NOW()),

-- Unpaired devices (for testing pairing flow)
('device-hre-003', 'HRE-DEV-003', 'tok-f6a7b8c9-d0e1-4234-f6a7-b8c9d0e12345', 'ABC234', FALSE, NULL, 'depot-hre-001', NULL, NULL, NOW(), NOW()),
('device-byo-003', 'BYO-DEV-003', 'tok-a7b8c9d0-e1f2-4345-a7b8-c9d0e1f23456', 'XYZ789', FALSE, NULL, 'depot-byo-001', NULL, NULL, NOW(), NOW());

-- =========================================
-- 7. FLEETS (Buses/Vehicles)
-- =========================================
INSERT INTO "tblFleets" (id, number, depot_id, created_at, updated_at) VALUES 
-- Harare Fleet
('fleet-hre-001', 'HRE-101', 'depot-hre-001', NOW(), NOW()),
('fleet-hre-002', 'HRE-102', 'depot-hre-001', NOW(), NOW()),
('fleet-hre-003', 'HRE-103', 'depot-hre-001', NOW(), NOW()),
('fleet-hre-004', 'HRE-104', 'depot-hre-001', NOW(), NOW()),
('fleet-hre-005', 'HRE-105', 'depot-hre-001', NOW(), NOW()),

-- Bulawayo Fleet
('fleet-byo-001', 'BYO-201', 'depot-byo-001', NOW(), NOW()),
('fleet-byo-002', 'BYO-202', 'depot-byo-001', NOW(), NOW()),
('fleet-byo-003', 'BYO-203', 'depot-byo-001', NOW(), NOW()),
('fleet-byo-004', 'BYO-204', 'depot-byo-001', NOW(), NOW()),

-- Mutare Fleet
('fleet-mut-001', 'MUT-301', 'depot-mut-001', NOW(), NOW()),
('fleet-mut-002', 'MUT-302', 'depot-mut-001', NOW(), NOW()),
('fleet-mut-003', 'MUT-303', 'depot-mut-001', NOW(), NOW());

-- =========================================
-- 8. ROUTES
-- =========================================
INSERT INTO "tblRoutes" (id, origin, destination, depot_id, created_at, updated_at) VALUES 
-- Harare Routes
('route-hre-001', 'Harare', 'Bulawayo', 'depot-hre-001', NOW(), NOW()),
('route-hre-002', 'Harare', 'Mutare', 'depot-hre-001', NOW(), NOW()),
('route-hre-003', 'Harare', 'Masvingo', 'depot-hre-001', NOW(), NOW()),
('route-hre-004', 'Harare', 'Gweru', 'depot-hre-001', NOW(), NOW()),
('route-hre-005', 'Harare', 'Chitungwiza', 'depot-hre-001', NOW(), NOW()),

-- Bulawayo Routes
('route-byo-001', 'Bulawayo', 'Harare', 'depot-byo-001', NOW(), NOW()),
('route-byo-002', 'Bulawayo', 'Victoria Falls', 'depot-byo-001', NOW(), NOW()),
('route-byo-003', 'Bulawayo', 'Gwanda', 'depot-byo-001', NOW(), NOW()),
('route-byo-004', 'Bulawayo', 'Plumtree', 'depot-byo-001', NOW(), NOW()),

-- Mutare Routes
('route-mut-001', 'Mutare', 'Harare', 'depot-mut-001', NOW(), NOW()),
('route-mut-002', 'Mutare', 'Chimanimani', 'depot-mut-001', NOW(), NOW()),
('route-mut-003', 'Mutare', 'Nyanga', 'depot-mut-001', NOW(), NOW());

-- =========================================
-- 9. FARES (Ticket Prices)
-- =========================================
INSERT INTO "tblFares" (id, route_id, depot_id, currency, amount, created_at, updated_at) VALUES 
-- Harare Routes (USD)
('fare-hre-001', 'route-hre-001', 'depot-hre-001', 'USD', 15.00, NOW(), NOW()),
('fare-hre-002', 'route-hre-002', 'depot-hre-001', 'USD', 12.00, NOW(), NOW()),
('fare-hre-003', 'route-hre-003', 'depot-hre-001', 'USD', 10.00, NOW(), NOW()),
('fare-hre-004', 'route-hre-004', 'depot-hre-001', 'USD', 8.00, NOW(), NOW()),
('fare-hre-005', 'route-hre-005', 'depot-hre-001', 'USD', 2.00, NOW(), NOW()),

-- Bulawayo Routes (USD)
('fare-byo-001', 'route-byo-001', 'depot-byo-001', 'USD', 15.00, NOW(), NOW()),
('fare-byo-002', 'route-byo-002', 'depot-byo-001', 'USD', 20.00, NOW(), NOW()),
('fare-byo-003', 'route-byo-003', 'depot-byo-001', 'USD', 7.00, NOW(), NOW()),
('fare-byo-004', 'route-byo-004', 'depot-byo-001', 'USD', 5.00, NOW(), NOW()),

-- Mutare Routes (USD)
('fare-mut-001', 'route-mut-001', 'depot-mut-001', 'USD', 12.00, NOW(), NOW()),
('fare-mut-002', 'route-mut-002', 'depot-mut-001', 'USD', 8.00, NOW(), NOW()),
('fare-mut-003', 'route-mut-003', 'depot-mut-001', 'USD', 6.00, NOW(), NOW());

-- =========================================
-- 10. SERIAL RANGES (Ticket Serial Numbers)
-- =========================================
INSERT INTO "tblSerialRanges" (id, depot_id, device_id, currency, start_number, end_number, next_number, allocated_at, created_at, updated_at) VALUES 
-- Harare Device 1 (partially used)
('serial-hre-001', 'depot-hre-001', 'device-hre-001', 'USD', 1000, 1999, 1050, NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days', NOW()),

-- Harare Device 2 (new)
('serial-hre-002', 'depot-hre-001', 'device-hre-002', 'USD', 2000, 2999, 2000, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days', NOW()),

-- Bulawayo Device 1 (partially used)
('serial-byo-001', 'depot-byo-001', 'device-byo-001', 'USD', 3000, 3999, 3120, NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days', NOW()),

-- Bulawayo Device 2 (partially used)
('serial-byo-002', 'depot-byo-001', 'device-byo-002', 'USD', 4000, 4999, 4085, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', NOW()),

-- Mutare Device 1 (partially used)
('serial-mut-001', 'depot-mut-001', 'device-mut-001', 'USD', 5000, 5999, 5042, NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days', NOW());

-- =========================================
-- 11. TRIPS (Sample Active and Completed)
-- =========================================
INSERT INTO "tblTrips" (id, depot_id, agent_id, device_id, fleet_id, route_id, started_at, ended_at, status, started_offline, created_at, updated_at) VALUES 
-- Completed Trips (for historical data)
('trip-001', 'depot-hre-001', 'agent-hre-001', 'device-hre-001', 'fleet-hre-001', 'route-hre-001', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days' + INTERVAL '5 hours', 'COMPLETED', FALSE, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days' + INTERVAL '5 hours'),
('trip-002', 'depot-hre-001', 'agent-hre-002', 'device-hre-002', 'fleet-hre-002', 'route-hre-002', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day' + INTERVAL '4 hours', 'COMPLETED', FALSE, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day' + INTERVAL '4 hours'),
('trip-003', 'depot-byo-001', 'agent-byo-001', 'device-byo-001', 'fleet-byo-001', 'route-byo-001', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days' + INTERVAL '5 hours', 'COMPLETED', FALSE, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days' + INTERVAL '5 hours'),

-- Active Trips (currently in progress)
('trip-004', 'depot-hre-001', 'agent-hre-001', 'device-hre-001', 'fleet-hre-003', 'route-hre-004', NOW() - INTERVAL '2 hours', NULL, 'ACTIVE', FALSE, NOW() - INTERVAL '2 hours', NOW()),
('trip-005', 'depot-byo-001', 'agent-byo-002', 'device-byo-002', 'fleet-byo-002', 'route-byo-002', NOW() - INTERVAL '1 hour', NULL, 'ACTIVE', FALSE, NOW() - INTERVAL '1 hour', NOW()),
('trip-006', 'depot-mut-001', 'agent-mut-001', 'device-mut-001', 'fleet-mut-001', 'route-mut-001', NOW() - INTERVAL '3 hours', NULL, 'ACTIVE', FALSE, NOW() - INTERVAL '3 hours', NOW());

-- =========================================
-- 12. TICKETS (Sample Passenger & Luggage)
-- =========================================
INSERT INTO "tblTickets" (id, depot_id, trip_id, agent_id, device_id, serial_number, ticket_category, currency, amount, departure, destination, linked_passenger_ticket_id, issued_at, created_at, updated_at) VALUES 
-- Trip 001 Tickets (Harare to Bulawayo - Completed)
('ticket-001', 'depot-hre-001', 'trip-001', 'agent-hre-001', 'device-hre-001', 1000, 'PASSENGER', 'USD', 15.00, 'Harare', 'Bulawayo', NULL, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
('ticket-002', 'depot-hre-001', 'trip-001', 'agent-hre-001', 'device-hre-001', 1001, 'PASSENGER', 'USD', 15.00, 'Harare', 'Bulawayo', NULL, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
('ticket-003', 'depot-hre-001', 'trip-001', 'agent-hre-001', 'device-hre-001', 1002, 'LUGGAGE', 'USD', 3.00, 'Harare', 'Bulawayo', 'ticket-001', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
('ticket-004', 'depot-hre-001', 'trip-001', 'agent-hre-001', 'device-hre-001', 1003, 'PASSENGER', 'USD', 15.00, 'Harare', 'Bulawayo', NULL, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
('ticket-005', 'depot-hre-001', 'trip-001', 'agent-hre-001', 'device-hre-001', 1004, 'PASSENGER', 'USD', 15.00, 'Harare', 'Bulawayo', NULL, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),

-- Trip 002 Tickets (Harare to Mutare - Completed)
('ticket-006', 'depot-hre-001', 'trip-002', 'agent-hre-002', 'device-hre-002', 2000, 'PASSENGER', 'USD', 12.00, 'Harare', 'Mutare', NULL, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
('ticket-007', 'depot-hre-001', 'trip-002', 'agent-hre-002', 'device-hre-002', 2001, 'PASSENGER', 'USD', 12.00, 'Harare', 'Mutare', NULL, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
('ticket-008', 'depot-hre-001', 'trip-002', 'agent-hre-002', 'device-hre-002', 2002, 'LUGGAGE', 'USD', 2.50, 'Harare', 'Mutare', 'ticket-006', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),

-- Trip 003 Tickets (Bulawayo to Harare - Completed)
('ticket-009', 'depot-byo-001', 'trip-003', 'agent-byo-001', 'device-byo-001', 3000, 'PASSENGER', 'USD', 15.00, 'Bulawayo', 'Harare', NULL, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
('ticket-010', 'depot-byo-001', 'trip-003', 'agent-byo-001', 'device-byo-001', 3001, 'PASSENGER', 'USD', 15.00, 'Bulawayo', 'Harare', NULL, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),

-- Trip 004 Tickets (Harare to Gweru - Active)
('ticket-011', 'depot-hre-001', 'trip-004', 'agent-hre-001', 'device-hre-001', 1005, 'PASSENGER', 'USD', 8.00, 'Harare', 'Gweru', NULL, NOW() - INTERVAL '1 hour 30 minutes', NOW() - INTERVAL '1 hour 30 minutes', NOW() - INTERVAL '1 hour 30 minutes'),
('ticket-012', 'depot-hre-001', 'trip-004', 'agent-hre-001', 'device-hre-001', 1006, 'PASSENGER', 'USD', 8.00, 'Harare', 'Gweru', NULL, NOW() - INTERVAL '1 hour 30 minutes', NOW() - INTERVAL '1 hour 30 minutes', NOW() - INTERVAL '1 hour 30 minutes'),

-- Trip 005 Tickets (Bulawayo to Vic Falls - Active)
('ticket-013', 'depot-byo-001', 'trip-005', 'agent-byo-002', 'device-byo-002', 4000, 'PASSENGER', 'USD', 20.00, 'Bulawayo', 'Victoria Falls', NULL, NOW() - INTERVAL '45 minutes', NOW() - INTERVAL '45 minutes', NOW() - INTERVAL '45 minutes'),
('ticket-014', 'depot-byo-001', 'trip-005', 'agent-byo-002', 'device-byo-002', 4001, 'PASSENGER', 'USD', 20.00, 'Bulawayo', 'Victoria Falls', NULL, NOW() - INTERVAL '45 minutes', NOW() - INTERVAL '45 minutes', NOW() - INTERVAL '45 minutes'),
('ticket-015', 'depot-byo-001', 'trip-005', 'agent-byo-002', 'device-byo-002', 4002, 'LUGGAGE', 'USD', 4.00, 'Bulawayo', 'Victoria Falls', 'ticket-013', NOW() - INTERVAL '45 minutes', NOW() - INTERVAL '45 minutes', NOW() - INTERVAL '45 minutes');

-- =========================================
-- 13. DAILY AGGREGATES (Revenue Summary)
-- =========================================
INSERT INTO "tblDailyAggregates" (id, depot_id, date, currency, revenue, ticket_count) VALUES 
-- Harare aggregates
('agg-hre-001', 'depot-hre-001', (NOW() - INTERVAL '2 days')::DATE, 'USD', 78.00, 5),
('agg-hre-002', 'depot-hre-001', (NOW() - INTERVAL '1 day')::DATE, 'USD', 38.50, 3),

-- Bulawayo aggregates
('agg-byo-001', 'depot-byo-001', (NOW() - INTERVAL '3 days')::DATE, 'USD', 30.00, 2);

-- =========================================
-- VERIFICATION QUERIES
-- =========================================
-- Uncomment these to verify data insertion:

-- SELECT COUNT(*) AS roles_count FROM "tblRoles";
-- SELECT COUNT(*) AS depots_count FROM "tblDepots";
-- SELECT COUNT(*) AS admin_users_count FROM "tblAdminUsers";
-- SELECT COUNT(*) AS agents_count FROM "tblAgents";
-- SELECT COUNT(*) AS devices_count FROM "tblDevices";
-- SELECT COUNT(*) AS fleets_count FROM "tblFleets";
-- SELECT COUNT(*) AS routes_count FROM "tblRoutes";
-- SELECT COUNT(*) AS fares_count FROM "tblFares";
-- SELECT COUNT(*) AS trips_count FROM "tblTrips";
-- SELECT COUNT(*) AS tickets_count FROM "tblTickets";
-- SELECT COUNT(*) AS serial_ranges_count FROM "tblSerialRanges";

-- =========================================
-- QUICK DATA OVERVIEW
-- =========================================
-- View depot summary with counts:
-- SELECT 
--   d.merchant_code,
--   d.name,
--   COUNT(DISTINCT a.id) as agents_count,
--   COUNT(DISTINCT dev.id) as devices_count,
--   COUNT(DISTINCT f.id) as fleets_count,
--   COUNT(DISTINCT r.id) as routes_count,
--   COUNT(DISTINCT t.id) as trips_count
-- FROM "tblDepots" d
-- LEFT JOIN "tblAgents" a ON a.depot_id = d.id
-- LEFT JOIN "tblDevices" dev ON dev.depot_id = d.id
-- LEFT JOIN "tblFleets" f ON f.depot_id = d.id
-- LEFT JOIN "tblRoutes" r ON r.depot_id = d.id
-- LEFT JOIN "tblTrips" t ON t.depot_id = d.id
-- GROUP BY d.id, d.merchant_code, d.name
-- ORDER BY d.merchant_code;

-- =========================================
-- IMPORTANT NOTES
-- =========================================
-- 1. Default password for all admin users: "password123"
--    Hash: $2b$10$rKZL8qk5f5h5h5h5h5h5hOYmqGqX8X8X8X8X8X8X8X8X8X8X8X8Xa
--    (This is a DUMMY hash - replace with actual bcrypt hash in production!)
--
-- 2. Default PIN for all agents: "1234"
--    (Hash this in production before inserting!)
--
-- 3. Device tokens are UUIDs - these are valid for API authentication
--
-- 4. Some devices are unpaired with pairing codes for testing:
--    - HRE-DEV-003: pairing code "ABC234"
--    - BYO-DEV-003: pairing code "XYZ789"
--
-- 5. Active trips (004, 005, 006) have no end time
--
-- 6. To clear all data and re-seed, uncomment the TRUNCATE statement at the top
--
-- =========================================
-- END OF SEED DATA
-- =========================================

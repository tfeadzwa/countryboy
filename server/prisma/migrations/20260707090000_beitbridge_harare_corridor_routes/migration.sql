-- Beitbridge → Harare corridor routes and fares
-- Source: fare matrix (9 stops along the corridor)
-- Depot: Harare (depot-hre-001) — change depot_id if this corridor belongs elsewhere

-- =========================================
-- ROUTES (36 origin/destination pairs)
-- =========================================
INSERT INTO "tblRoutes" (id, origin, destination, depot_id, is_active, created_at, updated_at) VALUES
-- From Beitbridge
('route-bbh-001', 'Beitbridge', 'Rutenga',     'depot-hre-001', true, NOW(), NOW()),
('route-bbh-002', 'Beitbridge', 'Ngundu',      'depot-hre-001', true, NOW(), NOW()),
('route-bbh-003', 'Beitbridge', 'Chibi Turn',  'depot-hre-001', true, NOW(), NOW()),
('route-bbh-004', 'Beitbridge', 'Masvingo',    'depot-hre-001', true, NOW(), NOW()),
('route-bbh-005', 'Beitbridge', 'Mvuma',       'depot-hre-001', true, NOW(), NOW()),
('route-bbh-006', 'Beitbridge', 'Chivhu',      'depot-hre-001', true, NOW(), NOW()),
('route-bbh-007', 'Beitbridge', 'Beatrice',    'depot-hre-001', true, NOW(), NOW()),
('route-bbh-008', 'Beitbridge', 'Harare',      'depot-hre-001', true, NOW(), NOW()),
-- From Rutenga
('route-bbh-009', 'Rutenga', 'Ngundu',         'depot-hre-001', true, NOW(), NOW()),
('route-bbh-010', 'Rutenga', 'Chibi Turn',     'depot-hre-001', true, NOW(), NOW()),
('route-bbh-011', 'Rutenga', 'Masvingo',       'depot-hre-001', true, NOW(), NOW()),
('route-bbh-012', 'Rutenga', 'Mvuma',          'depot-hre-001', true, NOW(), NOW()),
('route-bbh-013', 'Rutenga', 'Chivhu',         'depot-hre-001', true, NOW(), NOW()),
('route-bbh-014', 'Rutenga', 'Beatrice',       'depot-hre-001', true, NOW(), NOW()),
('route-bbh-015', 'Rutenga', 'Harare',         'depot-hre-001', true, NOW(), NOW()),
-- From Ngundu
('route-bbh-016', 'Ngundu', 'Chibi Turn',      'depot-hre-001', true, NOW(), NOW()),
('route-bbh-017', 'Ngundu', 'Masvingo',        'depot-hre-001', true, NOW(), NOW()),
('route-bbh-018', 'Ngundu', 'Mvuma',           'depot-hre-001', true, NOW(), NOW()),
('route-bbh-019', 'Ngundu', 'Chivhu',          'depot-hre-001', true, NOW(), NOW()),
('route-bbh-020', 'Ngundu', 'Beatrice',        'depot-hre-001', true, NOW(), NOW()),
('route-bbh-021', 'Ngundu', 'Harare',          'depot-hre-001', true, NOW(), NOW()),
-- From Chibi Turn
('route-bbh-022', 'Chibi Turn', 'Masvingo',    'depot-hre-001', true, NOW(), NOW()),
('route-bbh-023', 'Chibi Turn', 'Mvuma',       'depot-hre-001', true, NOW(), NOW()),
('route-bbh-024', 'Chibi Turn', 'Chivhu',      'depot-hre-001', true, NOW(), NOW()),
('route-bbh-025', 'Chibi Turn', 'Beatrice',    'depot-hre-001', true, NOW(), NOW()),
('route-bbh-026', 'Chibi Turn', 'Harare',      'depot-hre-001', true, NOW(), NOW()),
-- From Masvingo
('route-bbh-027', 'Masvingo', 'Mvuma',         'depot-hre-001', true, NOW(), NOW()),
('route-bbh-028', 'Masvingo', 'Chivhu',        'depot-hre-001', true, NOW(), NOW()),
('route-bbh-029', 'Masvingo', 'Beatrice',      'depot-hre-001', true, NOW(), NOW()),
('route-bbh-030', 'Masvingo', 'Harare',        'depot-hre-001', true, NOW(), NOW()),
-- From Mvuma
('route-bbh-031', 'Mvuma', 'Chivhu',           'depot-hre-001', true, NOW(), NOW()),
('route-bbh-032', 'Mvuma', 'Beatrice',         'depot-hre-001', true, NOW(), NOW()),
('route-bbh-033', 'Mvuma', 'Harare',           'depot-hre-001', true, NOW(), NOW()),
-- From Chivhu
('route-bbh-034', 'Chivhu', 'Beatrice',        'depot-hre-001', true, NOW(), NOW()),
('route-bbh-035', 'Chivhu', 'Harare',          'depot-hre-001', true, NOW(), NOW()),
-- From Beatrice
('route-bbh-036', 'Beatrice', 'Harare',        'depot-hre-001', true, NOW(), NOW());

-- =========================================
-- FARES (USD, matching the fare matrix)
-- =========================================
INSERT INTO "tblFares" (id, route_id, depot_id, currency, amount, created_at, updated_at) VALUES
-- From Beitbridge
('fare-bbh-001', 'route-bbh-001', 'depot-hre-001', 'USD',  6.00, NOW(), NOW()),
('fare-bbh-002', 'route-bbh-002', 'depot-hre-001', 'USD',  8.00, NOW(), NOW()),
('fare-bbh-003', 'route-bbh-003', 'depot-hre-001', 'USD', 10.00, NOW(), NOW()),
('fare-bbh-004', 'route-bbh-004', 'depot-hre-001', 'USD', 10.00, NOW(), NOW()),
('fare-bbh-005', 'route-bbh-005', 'depot-hre-001', 'USD', 15.00, NOW(), NOW()),
('fare-bbh-006', 'route-bbh-006', 'depot-hre-001', 'USD', 15.00, NOW(), NOW()),
('fare-bbh-007', 'route-bbh-007', 'depot-hre-001', 'USD', 15.00, NOW(), NOW()),
('fare-bbh-008', 'route-bbh-008', 'depot-hre-001', 'USD', 15.00, NOW(), NOW()),
-- From Rutenga
('fare-bbh-009',  'route-bbh-009',  'depot-hre-001', 'USD',  3.00, NOW(), NOW()),
('fare-bbh-010',  'route-bbh-010',  'depot-hre-001', 'USD',  8.00, NOW(), NOW()),
('fare-bbh-011',  'route-bbh-011',  'depot-hre-001', 'USD', 10.00, NOW(), NOW()),
('fare-bbh-012',  'route-bbh-012',  'depot-hre-001', 'USD', 10.00, NOW(), NOW()),
('fare-bbh-013',  'route-bbh-013',  'depot-hre-001', 'USD', 10.00, NOW(), NOW()),
('fare-bbh-014',  'route-bbh-014',  'depot-hre-001', 'USD', 15.00, NOW(), NOW()),
('fare-bbh-015',  'route-bbh-015',  'depot-hre-001', 'USD', 15.00, NOW(), NOW()),
-- From Ngundu
('fare-bbh-016',  'route-bbh-016',  'depot-hre-001', 'USD',  4.00, NOW(), NOW()),
('fare-bbh-017',  'route-bbh-017',  'depot-hre-001', 'USD',  8.00, NOW(), NOW()),
('fare-bbh-018',  'route-bbh-018',  'depot-hre-001', 'USD', 10.00, NOW(), NOW()),
('fare-bbh-019',  'route-bbh-019',  'depot-hre-001', 'USD', 10.00, NOW(), NOW()),
('fare-bbh-020',  'route-bbh-020',  'depot-hre-001', 'USD', 15.00, NOW(), NOW()),
('fare-bbh-021',  'route-bbh-021',  'depot-hre-001', 'USD', 15.00, NOW(), NOW()),
-- From Chibi Turn
('fare-bbh-022',  'route-bbh-022',  'depot-hre-001', 'USD',  3.00, NOW(), NOW()),
('fare-bbh-023',  'route-bbh-023',  'depot-hre-001', 'USD', 10.00, NOW(), NOW()),
('fare-bbh-024',  'route-bbh-024',  'depot-hre-001', 'USD', 10.00, NOW(), NOW()),
('fare-bbh-025',  'route-bbh-025',  'depot-hre-001', 'USD', 10.00, NOW(), NOW()),
('fare-bbh-026',  'route-bbh-026',  'depot-hre-001', 'USD', 15.00, NOW(), NOW()),
-- From Masvingo
('fare-bbh-027',  'route-bbh-027',  'depot-hre-001', 'USD',  5.00, NOW(), NOW()),
('fare-bbh-028',  'route-bbh-028',  'depot-hre-001', 'USD',  8.00, NOW(), NOW()),
('fare-bbh-029',  'route-bbh-029',  'depot-hre-001', 'USD', 10.00, NOW(), NOW()),
('fare-bbh-030',  'route-bbh-030',  'depot-hre-001', 'USD', 10.00, NOW(), NOW()),
-- From Mvuma
('fare-bbh-031',  'route-bbh-031',  'depot-hre-001', 'USD',  3.00, NOW(), NOW()),
('fare-bbh-032',  'route-bbh-032',  'depot-hre-001', 'USD',  8.00, NOW(), NOW()),
('fare-bbh-033',  'route-bbh-033',  'depot-hre-001', 'USD', 10.00, NOW(), NOW()),
-- From Chivhu
('fare-bbh-034',  'route-bbh-034',  'depot-hre-001', 'USD',  4.00, NOW(), NOW()),
('fare-bbh-035',  'route-bbh-035',  'depot-hre-001', 'USD',  8.00, NOW(), NOW()),
-- From Beatrice
('fare-bbh-036',  'route-bbh-036',  'depot-hre-001', 'USD',  3.00, NOW(), NOW());

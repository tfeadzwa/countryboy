-- Ensure CASHIER role exists for admin console trip closing / batch print.
INSERT INTO "tblRoles" (id, name)
VALUES ('role-cashier-001', 'CASHIER')
ON CONFLICT (name) DO NOTHING;

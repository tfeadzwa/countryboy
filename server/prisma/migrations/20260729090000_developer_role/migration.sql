-- Elevated DEVELOPER role (inherits SUPER_ADMIN privileges; hidden from super admins).
INSERT INTO "tblRoles" (id, name)
VALUES ('role-developer-001', 'DEVELOPER')
ON CONFLICT (name) DO NOTHING;

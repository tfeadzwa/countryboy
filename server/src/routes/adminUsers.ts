import { Router, Response } from 'express';
import bcrypt from '../lib/bcrypt';
import { z } from 'zod';
import prisma from '../utils/prisma';
import { authMiddleware, AuthenticatedRequest } from '../middleware/auth';
import { isDeveloper, requireRole } from '../middleware/rbac';
import { validate } from '../middleware/validate';
import logger, { authLoginLogger } from '../utils/logger';
import { isAdminOnline } from '../constants/presence';

const router = Router();

// SUPER_ADMIN and DEVELOPER (developer inherits SUPER_ADMIN via rbac expansion)
router.use(authMiddleware);
router.use(requireRole('SUPER_ADMIN'));

const PROTECTED_ROLES = new Set(['SUPER_ADMIN', 'DEVELOPER']);

const userHasProtectedRole = (
  roles: { role: { name: string } }[],
): boolean => roles.some((r) => PROTECTED_ROLES.has(r.role.name));

const userHasDeveloperRole = (
  roles: { role: { name: string } }[],
): boolean => roles.some((r) => r.role.name === 'DEVELOPER');

// ---------------------------------------------------------------------------
// Validation schemas
// ---------------------------------------------------------------------------

const createAdminUserSchema = z.object({
  body: z.object({
    username: z
      .string()
      .min(3, 'Username must be at least 3 characters')
      .max(32, 'Username must be at most 32 characters')
      .regex(/^[a-z0-9._-]+$/, 'Username may only contain lowercase letters, numbers, dots, hyphens and underscores'),
    full_name: z.string().min(2, 'Full name is required').max(100),
    email: z.string().email('Invalid email address').optional(),
    role: z.enum(['DEPOT_ADMIN', 'CASHIER', 'MANAGER', 'VIEWER'], {
      errorMap: () => ({
        message: 'Role must be DEPOT_ADMIN, CASHIER, MANAGER or VIEWER',
      }),
    }),
    depot_id: z.string().optional(),
    password: z.string().min(8, 'Password must be at least 8 characters').optional(),
  }),
});

const updateAdminUserSchema = z.object({
  params: z.object({ id: z.string() }),
  body: z.object({
    full_name: z.string().min(2).max(100).optional(),
    email: z.string().email('Invalid email address').optional().nullable(),
    role: z.enum(['DEPOT_ADMIN', 'CASHIER', 'MANAGER', 'VIEWER']).optional(),
    depot_id: z.string().optional().nullable(),
    status: z.enum(['ACTIVE', 'INACTIVE']).optional(),
  }),
});

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const generateTempPassword = (): string => {
  const upper = 'ABCDEFGHJKMNPQRSTUVWXYZ';
  const lower = 'abcdefghjkmnpqrstuvwxyz';
  const digits = '23456789';
  const special = '!@#$';
  const all = upper + lower + digits + special;
  // Guarantee at least one of each required character class
  let pass =
    upper[Math.floor(Math.random() * upper.length)] +
    lower[Math.floor(Math.random() * lower.length)] +
    digits[Math.floor(Math.random() * digits.length)] +
    special[Math.floor(Math.random() * special.length)];
  for (let i = pass.length; i < 12; i++) {
    pass += all[Math.floor(Math.random() * all.length)];
  }
  // Shuffle so the guaranteed chars aren't always at the front
  return pass
    .split('')
    .sort(() => Math.random() - 0.5)
    .join('');
};

const adminUserSelect = {
  id: true,
  username: true,
  full_name: true,
  email: true,
  phone: true,
  depot_id: true,
  status: true,
  last_seen_at: true,
  created_at: true,
  depot: { select: { id: true, name: true, merchant_code: true } },
  roles: { include: { role: { select: { id: true, name: true } } } },
} as const;

const mapAdminUser = (user: {
  id: string;
  username: string;
  full_name: string | null;
  email: string | null;
  phone?: string | null;
  depot_id: string | null;
  status: string;
  last_seen_at: Date | null;
  created_at: Date;
  depot: { id: string; name: string; merchant_code: string } | null;
  roles: { role: { id: string; name: string } }[];
}) => ({
  ...user,
  phone: user.phone ?? null,
  last_seen_at: user.last_seen_at ? user.last_seen_at.toISOString() : null,
  is_online: isAdminOnline({
    status: user.status,
    lastSeenAt: user.last_seen_at,
  }),
});

// ---------------------------------------------------------------------------
// GET /api/admin-users — list all admin users
// ---------------------------------------------------------------------------
router.get('/', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const users = await prisma.tblAdminUsers.findMany({
      select: adminUserSelect,
      orderBy: { created_at: 'asc' },
    });

    // Super admins must not see developer accounts; developers see everyone.
    const requesterIsDeveloper = isDeveloper(req);
    const visible = requesterIsDeveloper
      ? users
      : users.filter((u) => !userHasDeveloperRole(u.roles));

    res.json(visible.map(mapAdminUser));
  } catch (err) {
    logger.error('Failed to list admin users', { err });
    res.status(500).json({ error: 'Failed to load admin users' });
  }
});

// ---------------------------------------------------------------------------
// POST /api/admin-users — create new admin user
// ---------------------------------------------------------------------------
router.post('/', validate(createAdminUserSchema), async (req: AuthenticatedRequest, res: Response) => {
  const { username, full_name, email, role, depot_id, password } = req.body;
  const requesterId = req.user?.id;

  try {
    // Username uniqueness
    const existing = await prisma.tblAdminUsers.findUnique({ where: { username } });
    if (existing) {
      return res.status(409).json({ error: 'Username is already taken' });
    }

    // Email uniqueness
    if (email) {
      const existingEmail = await prisma.tblAdminUsers.findUnique({ where: { email } });
      if (existingEmail) {
        return res.status(409).json({ error: 'Email address is already in use' });
      }
    }

    // Depot existence
    if (depot_id) {
      const depot = await prisma.tblDepots.findUnique({ where: { id: depot_id } });
      if (!depot) return res.status(400).json({ error: 'Specified depot does not exist' });
    }

    // Role lookup
    const roleRecord = await prisma.tblRoles.findUnique({ where: { name: role } });
    if (!roleRecord) {
      return res.status(400).json({ error: `Role '${role}' not found. Make sure roles are seeded.` });
    }

    const tempPassword = password ?? generateTempPassword();
    const password_hash = await bcrypt.hash(tempPassword, 10);

    const newUser = await prisma.tblAdminUsers.create({
      data: {
        username,
        full_name,
        email: email ?? null,
        password_hash,
        depot_id: depot_id ?? null,
        status: 'ACTIVE',
        created_by: requesterId,
        roles: {
          create: { role: { connect: { id: roleRecord.id } } },
        },
      },
      select: adminUserSelect,
    });

    authLoginLogger.info('ADMIN_USER_CREATED', {
      createdById: requesterId,
      newUserId: newUser.id,
      username: newUser.username,
      role,
    });

    // Return the temporary password only when it was auto-generated (never stored in plain text after this)
    res.status(201).json({
      ...mapAdminUser(newUser),
      ...(password === undefined ? { temporaryPassword: tempPassword } : {}),
    });
  } catch (err) {
    logger.error('Failed to create admin user', { err });
    res.status(500).json({ error: 'Failed to create admin user' });
  }
});

// ---------------------------------------------------------------------------
// PUT /api/admin-users/:id — update admin user
// ---------------------------------------------------------------------------
router.put('/:id', validate(updateAdminUserSchema), async (req: AuthenticatedRequest, res: Response) => {
  const { id } = req.params;
  const { full_name, email, role, depot_id, status } = req.body;
  const requesterId = req.user?.id;

  try {
    const existing = await prisma.tblAdminUsers.findUnique({
      where: { id },
      include: { roles: { include: { role: true } } },
    });
    if (!existing) return res.status(404).json({ error: 'Admin user not found' });

    // Super admins cannot view/modify developer accounts.
    if (userHasDeveloperRole(existing.roles) && !isDeveloper(req)) {
      return res.status(404).json({ error: 'Admin user not found' });
    }

    // Protected elevated accounts cannot be edited via this console.
    if (userHasProtectedRole(existing.roles)) {
      return res.status(403).json({
        error: 'Cannot modify a developer or super admin account from this page',
      });
    }

    // Prevent self-deactivation
    if (status === 'INACTIVE' && id === requesterId) {
      return res.status(400).json({ error: 'You cannot deactivate your own account' });
    }

    // Email uniqueness check (skip if unchanged)
    if (email && email !== existing.email) {
      const emailExists = await prisma.tblAdminUsers.findUnique({ where: { email } });
      if (emailExists) return res.status(409).json({ error: 'Email address is already in use' });
    }

    // Depot existence check
    if (depot_id) {
      const depot = await prisma.tblDepots.findUnique({ where: { id: depot_id } });
      if (!depot) return res.status(400).json({ error: 'Specified depot does not exist' });
    }

    // Role change — replace all existing roles
    if (role) {
      const roleRecord = await prisma.tblRoles.findUnique({ where: { name: role } });
      if (!roleRecord) return res.status(400).json({ error: `Role '${role}' not found` });
      await prisma.tblUserRoles.deleteMany({ where: { userId: id } });
      await prisma.tblUserRoles.create({ data: { userId: id, roleId: roleRecord.id } });
    }

    const updateData: Record<string, unknown> = { updated_by: requesterId };
    if (full_name !== undefined) updateData.full_name = full_name;
    if (email !== undefined) updateData.email = email;
    if (depot_id !== undefined) updateData.depot_id = depot_id;
    if (status !== undefined) updateData.status = status;

    const updated = await prisma.tblAdminUsers.update({
      where: { id },
      data: updateData,
      select: adminUserSelect,
    });

    authLoginLogger.info('ADMIN_USER_UPDATED', {
      updatedById: requesterId,
      targetUserId: id,
      changes: { full_name, email, role, depot_id, status },
    });

    res.json(mapAdminUser(updated));
  } catch (err) {
    logger.error('Failed to update admin user', { err });
    res.status(500).json({ error: 'Failed to update admin user' });
  }
});

// ---------------------------------------------------------------------------
// POST /api/admin-users/:id/reset-password — set or generate a new password
// ---------------------------------------------------------------------------
const resetPasswordSchema = z.object({
  params: z.object({ id: z.string() }),
  body: z
    .object({
      password: z.string().min(8, 'Password must be at least 8 characters').optional(),
    })
    .optional()
    .default({}),
});

router.post(
  '/:id/reset-password',
  validate(resetPasswordSchema),
  async (req: AuthenticatedRequest, res: Response) => {
  const { id } = req.params;
  const requesterId = req.user?.id;
  const providedPassword =
    typeof req.body?.password === 'string' ? req.body.password.trim() : '';

  try {
    const existing = await prisma.tblAdminUsers.findUnique({
      where: { id },
      include: { roles: { include: { role: true } } },
    });
    if (!existing) {
      return res.status(404).json({ error: 'Admin user not found' });
    }

    if (userHasDeveloperRole(existing.roles) && !isDeveloper(req)) {
      return res.status(404).json({ error: 'Admin user not found' });
    }

    if (userHasProtectedRole(existing.roles)) {
      return res.status(403).json({
        error: 'Cannot reset password for a developer or super admin account',
      });
    }

    if (id === requesterId) {
      return res.status(400).json({
        error: 'Use Forgot password to reset your own password',
      });
    }

    if (providedPassword && providedPassword.length < 8) {
      return res.status(400).json({ error: 'Password must be at least 8 characters' });
    }

    const temporaryPassword = providedPassword || generateTempPassword();
    const password_hash = await bcrypt.hash(temporaryPassword, 10);

    const updated = await prisma.tblAdminUsers.update({
      where: { id },
      data: {
        password_hash,
        updated_by: requesterId,
      },
      select: adminUserSelect,
    });

    authLoginLogger.info('ADMIN_USER_PASSWORD_RESET', {
      resetById: requesterId,
      targetUserId: id,
      username: updated.username,
      mode: providedPassword ? 'manual' : 'generated',
    });

    res.json({
      ...mapAdminUser(updated),
      temporaryPassword,
    });
  } catch (err) {
    logger.error('Failed to reset admin password', { err });
    res.status(500).json({ error: 'Failed to reset password' });
  }
});

export default router;

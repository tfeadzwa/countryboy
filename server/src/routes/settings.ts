import { Router, Response } from 'express';
import { z } from 'zod';
import bcrypt from '../lib/bcrypt';
import prisma from '../utils/prisma';
import { authMiddleware, AuthenticatedRequest } from '../middleware/auth';
import { requireRole } from '../middleware/rbac';
import { validate } from '../middleware/validate';
import logger from '../utils/logger';
import { TICKET_CURRENCIES } from '../utils/fareCurrency';
import * as settingsService from '../services/settingsService';

const router = Router();

router.use(authMiddleware);

const updateSystemSchema = z.object({
  body: z.object({
    company_name: z.string().min(1).max(120).optional(),
    company_email: z.string().email().optional().nullable(),
    company_phone: z.string().max(40).optional().nullable(),
    support_email: z.string().email().optional().nullable(),
    enabled_currencies: z.array(z.enum(['USD', 'ZWL', 'ZAR'])).min(1).optional(),
    default_currency: z.enum(['USD', 'ZWL', 'ZAR']).optional(),
    timezone: z.string().min(1).max(64).optional(),
  }),
});

const updateProfileSchema = z.object({
  body: z.object({
    full_name: z.string().min(2).max(100).optional(),
    email: z.string().email().optional().nullable(),
    phone: z.string().max(40).optional().nullable(),
  }),
});

const changePasswordSchema = z.object({
  body: z.object({
    current_password: z.string().min(1, 'Current password is required'),
    new_password: z.string().min(8, 'New password must be at least 8 characters'),
  }),
});

const mapProfile = (user: {
  id: string;
  username: string;
  email: string | null;
  phone: string | null;
  full_name: string | null;
  depot_id: string | null;
  status: string;
  depot?: { id: string; name: string; merchant_code: string } | null;
  roles: { role: { name: string } }[];
}) => ({
  id: user.id,
  username: user.username,
  email: user.email,
  phone: user.phone,
  full_name: user.full_name,
  depot_id: user.depot_id,
  depot_name: user.depot?.name ?? null,
  depot_merchant_code: user.depot?.merchant_code ?? null,
  status: user.status,
  roles: user.roles.map((r) => r.role.name),
});

/**
 * GET /api/settings
 * Returns system settings + the signed-in admin profile.
 */
router.get('/', async (req: AuthenticatedRequest, res: Response) => {
  try {
    if (!req.user?.id) {
      return res.status(401).json({ error: 'Authentication required' });
    }

    const [system, user] = await Promise.all([
      settingsService.getSystemSettings(),
      prisma.tblAdminUsers.findUnique({
        where: { id: req.user.id },
        select: {
          id: true,
          username: true,
          email: true,
          phone: true,
          full_name: true,
          depot_id: true,
          status: true,
          depot: { select: { id: true, name: true, merchant_code: true } },
          roles: { include: { role: { select: { name: true } } } },
        },
      }),
    ]);

    if (!user) {
      return res.status(401).json({ error: 'Admin user not found' });
    }

    res.json({
      system,
      profile: mapProfile(user),
      available_currencies: [...TICKET_CURRENCIES],
      // Feature flags currently locked off in the UI.
      features: {
        two_factor_auth: false,
        email_notifications: false,
        sms_notifications: false,
      },
    });
  } catch (err) {
    logger.error('Failed to load settings', { err });
    res.status(500).json({ error: 'Failed to load settings' });
  }
});

/**
 * PUT /api/settings/system — SUPER_ADMIN only
 */
router.put(
  '/system',
  requireRole('SUPER_ADMIN'),
  validate(updateSystemSchema),
  async (req: AuthenticatedRequest, res: Response) => {
    try {
      const updated = await settingsService.updateSystemSettings(
        req.body,
        req.user?.id,
      );
      res.json(updated);
    } catch (err) {
      if (err instanceof Error) {
        return res.status(400).json({ error: err.message });
      }
      logger.error('Failed to update system settings', { err });
      res.status(500).json({ error: 'Failed to update system settings' });
    }
  },
);

/**
 * PUT /api/settings/profile — any signed-in admin
 */
router.put(
  '/profile',
  validate(updateProfileSchema),
  async (req: AuthenticatedRequest, res: Response) => {
    try {
      if (!req.user?.id) {
        return res.status(401).json({ error: 'Authentication required' });
      }

      const { full_name, email, phone } = req.body as {
        full_name?: string;
        email?: string | null;
        phone?: string | null;
      };

      if (email) {
        const taken = await prisma.tblAdminUsers.findFirst({
          where: {
            email,
            NOT: { id: req.user.id },
          },
          select: { id: true },
        });
        if (taken) {
          return res.status(409).json({ error: 'Email address is already in use' });
        }
      }

      const updated = await prisma.tblAdminUsers.update({
        where: { id: req.user.id },
        data: {
          ...(full_name !== undefined ? { full_name: full_name.trim() } : {}),
          ...(email !== undefined
            ? { email: email?.trim() ? email.trim() : null }
            : {}),
          ...(phone !== undefined
            ? { phone: phone?.trim() ? phone.trim() : null }
            : {}),
          updated_by: req.user.id,
        },
        select: {
          id: true,
          username: true,
          email: true,
          phone: true,
          full_name: true,
          depot_id: true,
          status: true,
          depot: { select: { id: true, name: true, merchant_code: true } },
          roles: { include: { role: { select: { name: true } } } },
        },
      });

      res.json(mapProfile(updated));
    } catch (err) {
      logger.error('Failed to update profile settings', { err });
      res.status(500).json({ error: 'Failed to update profile' });
    }
  },
);

/**
 * POST /api/settings/change-password — any signed-in admin
 */
router.post(
  '/change-password',
  validate(changePasswordSchema),
  async (req: AuthenticatedRequest, res: Response) => {
    try {
      if (!req.user?.id) {
        return res.status(401).json({ error: 'Authentication required' });
      }

      const { current_password, new_password } = req.body as {
        current_password: string;
        new_password: string;
      };

      const user = await prisma.tblAdminUsers.findUnique({
        where: { id: req.user.id },
        select: { id: true, password_hash: true },
      });
      if (!user) {
        return res.status(401).json({ error: 'Admin user not found' });
      }

      const match = await bcrypt.compare(current_password, user.password_hash);
      if (!match) {
        return res.status(400).json({ error: 'Current password is incorrect' });
      }

      const password_hash = await bcrypt.hash(new_password, 10);
      await prisma.tblAdminUsers.update({
        where: { id: user.id },
        data: {
          password_hash,
          updated_by: req.user.id,
        },
      });

      res.json({ message: 'Password updated successfully' });
    } catch (err) {
      logger.error('Failed to change password', { err });
      res.status(500).json({ error: 'Failed to change password' });
    }
  },
);

export default router;

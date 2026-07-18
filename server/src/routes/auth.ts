import { Router, Request, Response } from 'express';
import prisma from '../utils/prisma';
import bcrypt from '../lib/bcrypt';
import jwt from 'jsonwebtoken';
import { validate } from '../middleware/validate';
import { forgotPasswordSchema, loginSchema, resetPasswordSchema } from '../validators/schemas';
import { sendPasswordResetEmail } from '../utils/mailer';
import logger, { authLoginLogger } from '../utils/logger';

const router = Router();

const resolveFrontendBaseUrl = (): string => {
  const explicitBaseUrl = process.env.FRONTEND_BASE_URL?.trim();
  if (explicitBaseUrl) {
    return explicitBaseUrl.replace(/\/$/, '');
  }

  const configuredOrigins = (process.env.CORS_ORIGINS || '')
    .split(',')
    .map(origin => origin.trim())
    .filter(Boolean);

  const nonLocalOrigin = configuredOrigins.find(origin => !/localhost|127\.0\.0\.1/i.test(origin));
  return (nonLocalOrigin || configuredOrigins[0] || 'http://localhost:8080').replace(/\/$/, '');
};

interface RefreshTokenPayload {
  agentId: string;
  type: string;
}

interface PasswordResetPayload {
  userId: string;
  type: string;
  pwdv: string;
}

type LoginFailureReason =
  | 'USER_NOT_FOUND'
  | 'USER_INACTIVE'
  | 'PASSWORD_EMPTY'
  | 'INVALID_STORED_PASSWORD_HASH'
  | 'BAD_PASSWORD'
  | 'INTERNAL_ERROR';

const BCRYPT_HASH_PATTERN = /^\$2[aby]\$\d{2}\$.{53}$/;

function describeStoredPasswordHash(hash: string | null | undefined) {
  if (!hash) {
    return { present: false, formatValid: false, prefix: null as string | null, length: 0 };
  }
  return {
    present: true,
    formatValid: BCRYPT_HASH_PATTERN.test(hash),
    prefix: hash.slice(0, 7),
    length: hash.length,
  };
}

function logLoginFailure(
  reason: LoginFailureReason,
  meta: Record<string, unknown>,
) {
  const reasonMessages: Record<LoginFailureReason, string> = {
    USER_NOT_FOUND: 'No admin user matches the identifier (email or username).',
    USER_INACTIVE: 'User exists but account status is not ACTIVE.',
    PASSWORD_EMPTY: 'No password was submitted in the request body.',
    INVALID_STORED_PASSWORD_HASH: 'Stored password_hash is missing or not a valid bcrypt hash — re-seed or reset the password.',
    BAD_PASSWORD: 'Submitted password does not match the stored hash.',
    INTERNAL_ERROR: 'Unexpected server error during login.',
  };

  authLoginLogger.warn('LOGIN_FAILED', {
    reason,
    message: reasonMessages[reason],
    ...meta,
  });
}

router.post('/login', validate(loginSchema), async (req: Request, res: Response) => {
  const requestId = (req as Request & { requestId?: string }).requestId;
  let identifier = '';
  let isEmail = false;
  const ip = req.ip || req.socket.remoteAddress || 'unknown';

  try {
    const { username, password } = req.body;
    identifier = username.trim();
    isEmail = identifier.includes('@');

    authLoginLogger.info('LOGIN_ATTEMPT', {
      requestId,
      identifier,
      lookupField: isEmail ? 'email' : 'username',
      normalizedIdentifier: isEmail ? identifier.toLowerCase() : identifier,
      passwordProvided: Boolean(password),
      passwordLength: typeof password === 'string' ? password.length : 0,
      ip,
      userAgent: req.get('user-agent') || 'unknown',
    });

    if (!password || typeof password !== 'string' || password.length === 0) {
      logLoginFailure('PASSWORD_EMPTY', { requestId, identifier, isEmail, ip });
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const user = await prisma.tblAdminUsers.findFirst({
      where: isEmail
        ? { email: identifier.toLowerCase() }
        : { username: identifier },
      include: { roles: { include: { role: true } } },
    });

    if (!user) {
      logLoginFailure('USER_NOT_FOUND', {
        requestId,
        identifier,
        isEmail,
        lookupField: isEmail ? 'email' : 'username',
        normalizedIdentifier: isEmail ? identifier.toLowerCase() : identifier,
        ip,
      });
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const roleNames = user.roles.map(r => r.role.name);
    const storedHash = describeStoredPasswordHash(user.password_hash);

    authLoginLogger.info('LOGIN_USER_RESOLVED', {
      requestId,
      userId: user.id,
      username: user.username,
      email: (user as { email?: string | null }).email ?? null,
      status: user.status,
      depot_id: user.depot_id,
      roles: roleNames,
      roleCount: roleNames.length,
      storedPasswordHash: storedHash,
    });

    if (user.status !== 'ACTIVE') {
      logLoginFailure('USER_INACTIVE', {
        requestId,
        userId: user.id,
        username: user.username,
        status: user.status,
        roles: roleNames,
        ip,
      });
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    if (!storedHash.present || !storedHash.formatValid) {
      logLoginFailure('INVALID_STORED_PASSWORD_HASH', {
        requestId,
        userId: user.id,
        username: user.username,
        roles: roleNames,
        storedPasswordHash: storedHash,
        ip,
      });
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    authLoginLogger.info('LOGIN_PASSWORD_CHECK', {
      requestId,
      userId: user.id,
      username: user.username,
      submittedPasswordLength: password.length,
      storedPasswordHashPrefix: storedHash.prefix,
    });

    const compareStartedAt = Date.now();
    const match = await bcrypt.compare(password, user.password_hash);
    const compareDurationMs = Date.now() - compareStartedAt;

    if (!match) {
      logLoginFailure('BAD_PASSWORD', {
        requestId,
        userId: user.id,
        username: user.username,
        email: (user as { email?: string | null }).email ?? null,
        roles: roleNames,
        depot_id: user.depot_id,
        submittedPasswordLength: password.length,
        storedPasswordHashPrefix: storedHash.prefix,
        bcryptCompareDurationMs: compareDurationMs,
        ip,
      });
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const token = jwt.sign(
      { userId: user.id, roles: roleNames, depot_id: user.depot_id ?? null },
      process.env.JWT_SECRET as string,
      { expiresIn: '8h' }
    );

    authLoginLogger.info('LOGIN_SUCCESS', {
      requestId,
      userId: user.id,
      username: user.username,
      email: (user as { email?: string | null }).email ?? null,
      depot_id: user.depot_id,
      roles: roleNames,
      bcryptCompareDurationMs: compareDurationMs,
      ip,
    });

    res.json({ token, user: { id: user.id, username: user.username, email: (user as { email?: string | null }).email ?? null, full_name: user.full_name, depot_id: user.depot_id, roles: roleNames } });
  } catch (err: any) {
    logLoginFailure('INTERNAL_ERROR', {
      requestId,
      identifier: identifier || null,
      isEmail,
      ip,
      error: err?.message || String(err),
    });
    authLoginLogger.error('LOGIN_ERROR', {
      requestId,
      error: err?.message || String(err),
      stack: err?.stack,
    });
    return res.status(500).json({ error: 'Login failed' });
  }
});

/**
 * Refresh access token using refresh token
 * 
 * POST /api/auth/refresh
 * Body: { refresh_token: string }
 * 
 * Returns new access token and refresh token
 */
router.post('/refresh', async (req: Request, res: Response) => {
  try {
    const { refresh_token } = req.body;

    if (!refresh_token) {
      return res.status(400).json({ error: 'Refresh token is required' });
    }

    const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'your-refresh-secret';
    const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key';

    // Verify refresh token
    const decoded = jwt.verify(refresh_token, JWT_REFRESH_SECRET) as RefreshTokenPayload;

    if (decoded.type !== 'refresh') {
      return res.status(401).json({ error: 'Invalid token type' });
    }

    // Get agent to verify they still exist and are active
    const agent = await prisma.tblAgents.findUnique({
      where: { id: decoded.agentId },
      include: { depot: true }
    });

    if (!agent || agent.status !== 'ACTIVE') {
      return res.status(401).json({ error: 'Agent not found or inactive' });
    }

    // Generate new tokens
    const newAccessToken = jwt.sign(
      {
        agentId: agent.id,
        depotId: agent.depot_id,
        role: 'AGENT',
        type: 'access'
      },
      JWT_SECRET,
      { expiresIn: '1h' }
    );

    const newRefreshToken = jwt.sign(
      {
        agentId: agent.id,
        type: 'refresh'
      },
      JWT_REFRESH_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      access_token: newAccessToken,
      refresh_token: newRefreshToken,
      message: 'Token refreshed successfully'
    });

  } catch (err: any) {
    if (err.name === 'JsonWebTokenError') {
      return res.status(401).json({ error: 'Invalid refresh token' });
    }
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Refresh token expired' });
    }
    res.status(500).json({ error: 'Failed to refresh token', details: err.message });
  }
});

/**
 * Forgot password
 *
 * POST /api/auth/forgot-password
 * Body: { email: string }
 *
 * Returns accountExists so the client can decide whether to show the success UI.
 */
router.post('/forgot-password', validate(forgotPasswordSchema), async (req: Request, res: Response) => {
  const { email } = req.body as { email: string };
  const identifier = email.trim().toLowerCase();
  const ip = req.ip || req.socket.remoteAddress || 'unknown';

  const unknownAccountResponse = {
    accountExists: false,
    message: 'No account found for that email.'
  };

  const successResponse = {
    accountExists: true,
    message: 'Password reset link sent.'
  };

  authLoginLogger.info('FORGOT_PASSWORD_ATTEMPT', {
    identifier,
    ip,
    userAgent: req.get('user-agent') || 'unknown',
  });

  try {
    const user = await prisma.tblAdminUsers.findUnique({
      where: {
        email: identifier,
      },
    });

    if (!user || user.status !== 'ACTIVE') {
      authLoginLogger.info('FORGOT_PASSWORD_NO_ACTIVE_USER', { identifier, ip });
      return res.status(200).json(unknownAccountResponse);
    }

    const resetSecret = process.env.JWT_RESET_SECRET || process.env.JWT_SECRET;
    if (!resetSecret) {
      logger.error('JWT_RESET_SECRET/JWT_SECRET missing; cannot issue password reset tokens');
      authLoginLogger.error('FORGOT_PASSWORD_RESET_SECRET_MISSING', { userId: user.id, identifier, ip });
      return res.status(500).json({ error: 'Password reset is not configured.' });
    }

    const resetToken = jwt.sign(
      { userId: user.id, type: 'password_reset', pwdv: user.password_hash },
      resetSecret,
      { expiresIn: '30m' }
    );

    const frontendBaseUrl = resolveFrontendBaseUrl();
    const resetLink = `${frontendBaseUrl}/reset-password?token=${encodeURIComponent(resetToken)}`;

    const recipient = (user as { email?: string | null }).email;
    if (!recipient) {
      authLoginLogger.warn('FORGOT_PASSWORD_USER_WITHOUT_EMAIL', {
        userId: user.id,
        username: user.username,
        identifier,
        ip,
      });
      return res.status(500).json({ error: 'Account is missing an email address.' });
    }

    await sendPasswordResetEmail(recipient, resetLink);
    authLoginLogger.info('FORGOT_PASSWORD_EMAIL_SENT', {
      userId: user.id,
      username: user.username,
      recipient,
      frontendBaseUrl,
      ip,
    });

    return res.status(200).json(successResponse);
  } catch (err: any) {
    logger.error('Forgot password failed', { error: err?.message || String(err) });
    authLoginLogger.error('FORGOT_PASSWORD_ERROR', {
      identifier,
      ip,
      error: err?.message || String(err),
    });
    return res.status(500).json({ error: 'Failed to send reset email.' });
  }
});

/**
 * Reset password
 *
 * POST /api/auth/reset-password
 * Body: { token: string, new_password: string }
 */
router.post('/reset-password', validate(resetPasswordSchema), async (req: Request, res: Response) => {
  const { token, new_password } = req.body as { token: string; new_password: string };
  const ip = req.ip || req.socket.remoteAddress || 'unknown';

  authLoginLogger.info('RESET_PASSWORD_ATTEMPT', {
    tokenLength: token?.length || 0,
    ip,
    userAgent: req.get('user-agent') || 'unknown',
  });

  try {
    const resetSecret = process.env.JWT_RESET_SECRET || process.env.JWT_SECRET;
    if (!resetSecret) {
      authLoginLogger.error('RESET_PASSWORD_SECRET_MISSING', { ip });
      return res.status(500).json({ error: 'Password reset is not configured.' });
    }

    const payload = jwt.verify(token, resetSecret) as PasswordResetPayload;

    if (payload.type !== 'password_reset') {
      authLoginLogger.warn('RESET_PASSWORD_INVALID_TOKEN_TYPE', { ip, payloadType: payload.type });
      return res.status(401).json({ error: 'Invalid reset token.' });
    }

    const user = await prisma.tblAdminUsers.findUnique({ where: { id: payload.userId } });
    if (!user || user.status !== 'ACTIVE') {
      authLoginLogger.warn('RESET_PASSWORD_USER_INVALID', {
        userId: payload.userId,
        userFound: Boolean(user),
        userStatus: user?.status || null,
        ip,
      });
      return res.status(401).json({ error: 'Invalid or expired reset token.' });
    }

    // Invalidate stale tokens after password changes.
    if (payload.pwdv !== user.password_hash) {
      authLoginLogger.warn('RESET_PASSWORD_STALE_TOKEN', {
        userId: user.id,
        username: user.username,
        ip,
      });
      return res.status(401).json({ error: 'This reset link is no longer valid.' });
    }

    const password_hash = await bcrypt.hash(new_password, 10);
    await prisma.tblAdminUsers.update({
      where: { id: user.id },
      data: { password_hash },
    });

    authLoginLogger.info('RESET_PASSWORD_SUCCESS', {
      userId: user.id,
      username: user.username,
      ip,
    });

    return res.json({ message: 'Password reset successful. You can now sign in with your new password.' });
  } catch (err: any) {
    if (err?.name === 'TokenExpiredError') {
      authLoginLogger.warn('RESET_PASSWORD_TOKEN_EXPIRED', { ip });
      return res.status(401).json({ error: 'Reset link has expired. Please request a new one.' });
    }
    if (err?.name === 'JsonWebTokenError') {
      authLoginLogger.warn('RESET_PASSWORD_TOKEN_INVALID', { ip, error: err?.message || String(err) });
      return res.status(401).json({ error: 'Invalid reset token.' });
    }
    logger.error('Reset password failed', { error: err?.message || String(err) });
    authLoginLogger.error('RESET_PASSWORD_ERROR', {
      ip,
      error: err?.message || String(err),
    });
    return res.status(500).json({ error: 'Failed to reset password.' });
  }
});

export default router;

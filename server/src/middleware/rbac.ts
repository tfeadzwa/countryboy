import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from './auth';

/** Role names attached to the authenticated user (JWT-shaped or DB-shaped). */
export const getUserRoleNames = (req: AuthenticatedRequest): string[] => {
  return (req.user?.roles ?? [])
    .map((ur: any) => ur?.role?.name)
    .filter((name: unknown): name is string => typeof name === 'string' && name.length > 0);
};

/**
 * DEVELOPER inherits every privilege granted to SUPER_ADMIN.
 * Checks that require SUPER_ADMIN therefore also accept DEVELOPER.
 */
const expandRequiredRoles = (roleNames: string[]): string[] => {
  if (roleNames.includes('SUPER_ADMIN') && !roleNames.includes('DEVELOPER')) {
    return [...roleNames, 'DEVELOPER'];
  }
  return roleNames;
};

export const requireRole = (roleName: string) => {
  const accepted = expandRequiredRoles([roleName]);
  return (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    const user = req.user;
    if (!user) return res.status(401).json({ error: 'Unauthorized' });

    const hasRole = getUserRoleNames(req).some((name) => accepted.includes(name));
    if (!hasRole) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    next();
  };
};

export const requireAnyRole = (roleNames: string[]) => {
  const accepted = expandRequiredRoles(roleNames);
  return (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    const user = req.user;
    if (!user) return res.status(401).json({ error: 'Unauthorized' });

    const hasAnyRole = getUserRoleNames(req).some((name) => accepted.includes(name));
    if (!hasAnyRole) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    next();
  };
};

/** True when the user is a platform developer (above super admin). */
export const isDeveloper = (req: AuthenticatedRequest): boolean => {
  return getUserRoleNames(req).includes('DEVELOPER');
};

/** True for SUPER_ADMIN or DEVELOPER (developer inherits super-admin privileges). */
export const isSuperAdmin = (req: AuthenticatedRequest): boolean => {
  const names = getUserRoleNames(req);
  return names.includes('SUPER_ADMIN') || names.includes('DEVELOPER');
};

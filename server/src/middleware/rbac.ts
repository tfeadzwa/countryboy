import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from './auth';

export const requireRole = (roleName: string) => {
  return (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    const user = req.user;
    if (!user) return res.status(401).json({ error: 'Unauthorized' });

    const hasRole = user.roles?.some((ur: any) => ur.role.name === roleName);
    if (!hasRole) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    next();
  };
};

export const requireAnyRole = (roleNames: string[]) => {
  return (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    const user = req.user;
    if (!user) return res.status(401).json({ error: 'Unauthorized' });

    const hasAnyRole = user.roles?.some((ur: any) => roleNames.includes(ur.role.name));
    if (!hasAnyRole) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    next();
  };
};

export const isSuperAdmin = (req: AuthenticatedRequest) => {
  return req.user && req.user.roles?.some((ur: any) => ur.role.name === 'SUPER_ADMIN');
};

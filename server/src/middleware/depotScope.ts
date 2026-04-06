import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from './auth';
import { isSuperAdmin } from './rbac';

export const depotScopeMiddleware = (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  // if the user record has a depot_id, always seed it (even super admins)
  if (req.user?.depot_id) {
    req.depotId = req.user.depot_id;
  }

  if (isSuperAdmin(req)) {
    // super admin can specify depot context via header or query param
    // Priority: user.depot_id > header > query param
    if (!req.depotId) {
      const headerDepot = req.header("x-depot-id");
      const queryDepot = req.query.depot_id as string;
      req.depotId = headerDepot || queryDepot;
    }
    
    // For POST/PUT/DELETE operations, depot context is required even for SUPER_ADMIN
    const isModifyingOperation = ['POST', 'PUT', 'DELETE'].includes(req.method);
    if (isModifyingOperation && !req.depotId) {
      return res.status(400).json({ 
        error: 'Depot context required. Please specify depot via x-depot-id header or select a depot.' 
      });
    }
    
    return next();
  }
  if (!req.depotId) {
    return res.status(403).json({ error: 'Depot context missing' });
  }
  next();
};

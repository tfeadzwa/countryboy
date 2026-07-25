import { Router } from 'express';
import { authMiddleware } from '../middleware/auth';
import { depotScopeMiddleware } from '../middleware/depotScope';
import { requireAnyRole } from '../middleware/rbac';
import * as tripController from '../controllers/tripController';
import { validate } from '../middleware/validate';
import { startTripSchema, endTripSchema } from '../validators/schemas';

const router = Router();

router.get('/', authMiddleware, depotScopeMiddleware, tripController.list);
router.get('/active', authMiddleware, depotScopeMiddleware, tripController.listActive);
router.post(
  '/',
  authMiddleware,
  depotScopeMiddleware,
  requireAnyRole(['SUPER_ADMIN', 'DEPOT_ADMIN']),
  validate(startTripSchema),
  tripController.start,
);
// Cashiers (and super admins) close trips — conductors only start them on mobile.
router.post(
  '/:id/end',
  authMiddleware,
  depotScopeMiddleware,
  requireAnyRole(['SUPER_ADMIN', 'CASHIER']),
  validate(endTripSchema),
  tripController.end,
);
router.get('/:id', authMiddleware, depotScopeMiddleware, tripController.getOne);
router.get('/:id/totals', authMiddleware, depotScopeMiddleware, tripController.totals);

export default router;

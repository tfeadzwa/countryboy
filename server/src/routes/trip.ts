import { Router } from 'express';
import { authMiddleware } from '../middleware/auth';
import { depotScopeMiddleware } from '../middleware/depotScope';
import { requireRole } from '../middleware/rbac';
import * as tripController from '../controllers/tripController';
import { validate } from '../middleware/validate';
import { startTripSchema, endTripSchema } from '../validators/schemas';

const router = Router();

router.get('/', authMiddleware, depotScopeMiddleware, tripController.list);
router.get('/active', authMiddleware, depotScopeMiddleware, tripController.listActive);
// starting/ending trips are depot-admin actions
router.post('/', authMiddleware, depotScopeMiddleware, requireRole('DEPOT_ADMIN'), validate(startTripSchema), tripController.start);
router.post('/:id/end', authMiddleware, depotScopeMiddleware, requireRole('DEPOT_ADMIN'), validate(endTripSchema), tripController.end);
router.get('/:id', authMiddleware, depotScopeMiddleware, tripController.getOne);
router.get('/:id/totals', authMiddleware, depotScopeMiddleware, tripController.totals);

export default router;

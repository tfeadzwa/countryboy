import { Router } from 'express';
import { authMiddleware } from '../middleware/auth';
import { depotScopeMiddleware } from '../middleware/depotScope';
import { requireAnyRole } from '../middleware/rbac';
import * as fleetController from '../controllers/fleetController';
import { validate } from '../middleware/validate';
import { fleetSchema } from '../validators/schemas';

const router = Router();

router.get('/', authMiddleware, depotScopeMiddleware, fleetController.list);
router.post('/', authMiddleware, depotScopeMiddleware, requireAnyRole(['SUPER_ADMIN', 'DEPOT_ADMIN']), validate(fleetSchema), fleetController.create);
router.get('/:id', authMiddleware, depotScopeMiddleware, fleetController.getOne);
router.put('/:id', authMiddleware, depotScopeMiddleware, requireAnyRole(['SUPER_ADMIN', 'DEPOT_ADMIN']), fleetController.update);

export default router;

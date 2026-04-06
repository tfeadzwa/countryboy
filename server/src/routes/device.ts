import { Router } from 'express';
import { authMiddleware } from '../middleware/auth';
import { depotScopeMiddleware } from '../middleware/depotScope';
import { requireAnyRole } from '../middleware/rbac';
import * as deviceController from '../controllers/deviceController';
import { validate } from '../middleware/validate';
import { deviceSchema } from '../validators/schemas';

const router = Router();

// Public endpoint for device pairing (no auth required for initial setup)
router.post('/pair', deviceController.pair);

router.get('/', authMiddleware, depotScopeMiddleware, deviceController.list);
router.post('/', authMiddleware, depotScopeMiddleware, requireAnyRole(['SUPER_ADMIN', 'DEPOT_ADMIN']), validate(deviceSchema), deviceController.create);
router.get('/:id', authMiddleware, depotScopeMiddleware, deviceController.getOne);
router.put('/:id', authMiddleware, depotScopeMiddleware, requireAnyRole(['SUPER_ADMIN', 'DEPOT_ADMIN']), deviceController.update);
router.post('/:id/unpair', authMiddleware, depotScopeMiddleware, requireAnyRole(['SUPER_ADMIN', 'DEPOT_ADMIN']), deviceController.unpair);

export default router;

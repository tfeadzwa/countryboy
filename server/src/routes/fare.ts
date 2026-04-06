import { Router } from 'express';
import { authMiddleware } from '../middleware/auth';
import { depotScopeMiddleware } from '../middleware/depotScope';
import { requireAnyRole } from '../middleware/rbac';
import * as fareController from '../controllers/fareController';
import { validate } from '../middleware/validate';
import { fareSchema } from '../validators/schemas';

const router = Router();

router.get('/', authMiddleware, depotScopeMiddleware, fareController.list);
router.post('/', authMiddleware, depotScopeMiddleware, requireAnyRole(['SUPER_ADMIN', 'DEPOT_ADMIN']), validate(fareSchema), fareController.create);
router.get('/:id', authMiddleware, depotScopeMiddleware, fareController.getOne);
router.put('/:id', authMiddleware, depotScopeMiddleware, requireAnyRole(['SUPER_ADMIN', 'DEPOT_ADMIN']), fareController.update);

export default router;

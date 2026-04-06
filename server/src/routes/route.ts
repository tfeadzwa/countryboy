import { Router } from 'express';
import { authMiddleware } from '../middleware/auth';
import { depotScopeMiddleware } from '../middleware/depotScope';
import { requireAnyRole } from '../middleware/rbac';
import * as routeController from '../controllers/routeController';
import { validate } from '../middleware/validate';
import { routeSchema } from '../validators/schemas';

const router = Router();

router.get('/', authMiddleware, depotScopeMiddleware, routeController.list);
router.post('/', authMiddleware, depotScopeMiddleware, requireAnyRole(['SUPER_ADMIN', 'DEPOT_ADMIN']), validate(routeSchema), routeController.create);
router.get('/:id', authMiddleware, depotScopeMiddleware, routeController.getOne);
router.put('/:id', authMiddleware, depotScopeMiddleware, requireAnyRole(['SUPER_ADMIN', 'DEPOT_ADMIN']), routeController.update);

export default router;

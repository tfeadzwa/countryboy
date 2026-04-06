import { Router } from 'express';
import { authMiddleware } from '../middleware/auth';
import { depotScopeMiddleware } from '../middleware/depotScope';
import { requireRole } from '../middleware/rbac';
import { createDepot, listDepots, updateDepot } from '../controllers/depotController';
import { validate } from '../middleware/validate';
import { depotSchema, updateDepotSchema } from '../validators/schemas';

const router = Router();

// only super can create and update
router.post('/', authMiddleware, requireRole('SUPER_ADMIN'), validate(depotSchema), createDepot);
router.put('/:id', authMiddleware, requireRole('SUPER_ADMIN'), validate(updateDepotSchema), updateDepot);
router.get('/', authMiddleware, depotScopeMiddleware, listDepots);

export default router;

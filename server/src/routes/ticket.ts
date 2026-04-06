import { Router } from 'express';
import { authMiddleware } from '../middleware/auth';
import { depotScopeMiddleware } from '../middleware/depotScope';
import { requireRole } from '../middleware/rbac';
import * as ticketController from '../controllers/ticketController';
import { validate } from '../middleware/validate';
import { ticketIssueSchema, ticketVoidSchema, ticketSearchSchema } from '../validators/schemas';

const router = Router();

router.get('/', authMiddleware, depotScopeMiddleware, ticketController.list);
router.post('/', authMiddleware, depotScopeMiddleware, validate(ticketIssueSchema), ticketController.issue);
router.post('/:id/void', authMiddleware, depotScopeMiddleware, requireRole('DEPOT_ADMIN'), validate(ticketVoidSchema), ticketController.voidTicket);
router.get('/search', authMiddleware, depotScopeMiddleware, validate(ticketSearchSchema), ticketController.search);

export default router;

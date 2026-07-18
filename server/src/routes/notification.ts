import { Router } from 'express';
import { authMiddleware } from '../middleware/auth';
import { depotScopeMiddleware } from '../middleware/depotScope';
import * as notificationController from '../controllers/notificationController';

const router = Router();

router.get('/', authMiddleware, depotScopeMiddleware, notificationController.list);

export default router;

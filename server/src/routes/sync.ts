import { Router } from 'express';
import { authMiddleware } from '../middleware/auth';
import { depotScopeMiddleware } from '../middleware/depotScope';
import { deviceAuthMiddleware } from '../middleware/deviceAuth';
import { logSyncPushRequest } from '../middleware/logSyncPush';
import { push, pull } from '../controllers/syncController';
import { validate } from '../middleware/validate';
import { syncPushSchema, syncPullSchema } from '../validators/schemas';

const router = Router();

// push sync data (trips/tickets)
router.post(
  '/push',
  authMiddleware,
  depotScopeMiddleware,
  deviceAuthMiddleware,
  logSyncPushRequest,
  validate(syncPushSchema),
  push,
);

// pull updates since timestamp
router.get('/pull', authMiddleware, depotScopeMiddleware, deviceAuthMiddleware, validate(syncPullSchema), pull);

export default router;

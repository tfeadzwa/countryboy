import { Router } from 'express';
import { authMiddleware } from '../middleware/auth';
import { depotScopeMiddleware } from '../middleware/depotScope';
import { requireAnyRole } from '../middleware/rbac';
import { documentUpload } from '../middleware/upload';
import * as driverController from '../controllers/driverController';
import { validate } from '../middleware/validate';
import { driverSchema, driverUpdateSchema } from '../validators/schemas';

const router = Router();

router.get('/', authMiddleware, depotScopeMiddleware, driverController.list);
router.post(
  '/',
  authMiddleware,
  depotScopeMiddleware,
  requireAnyRole(['SUPER_ADMIN', 'DEPOT_ADMIN']),
  validate(driverSchema),
  driverController.create,
);

router.post(
  '/:id/documents/:type',
  authMiddleware,
  depotScopeMiddleware,
  requireAnyRole(['SUPER_ADMIN', 'DEPOT_ADMIN']),
  documentUpload.single('file'),
  driverController.uploadDocument,
);
router.get(
  '/:id/documents/:type/download',
  authMiddleware,
  depotScopeMiddleware,
  driverController.downloadDocument,
);
router.delete(
  '/:id/documents/:type',
  authMiddleware,
  depotScopeMiddleware,
  requireAnyRole(['SUPER_ADMIN', 'DEPOT_ADMIN']),
  driverController.removeDocument,
);

router.get('/:id', authMiddleware, depotScopeMiddleware, driverController.getOne);
router.put(
  '/:id',
  authMiddleware,
  depotScopeMiddleware,
  requireAnyRole(['SUPER_ADMIN', 'DEPOT_ADMIN']),
  validate(driverUpdateSchema),
  driverController.update,
);
router.delete(
  '/:id',
  authMiddleware,
  depotScopeMiddleware,
  requireAnyRole(['SUPER_ADMIN', 'DEPOT_ADMIN']),
  driverController.remove,
);

export default router;

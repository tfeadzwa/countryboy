import { Router } from 'express';
import { authMiddleware } from '../middleware/auth';
import { requireRole } from '../middleware/rbac';
import { appReleaseUpload } from '../middleware/upload';
import * as appReleaseController from '../controllers/appReleaseController';

const router = Router();

/** Super admins + developers may view / download releases. */
const canViewReleases = [authMiddleware, requireRole('SUPER_ADMIN')];
/** Only developers may publish, promote, or delete releases. */
const canPublishReleases = [authMiddleware, requireRole('DEVELOPER')];

router.get('/', ...canViewReleases, appReleaseController.list);
router.get('/current', ...canViewReleases, appReleaseController.getCurrent);
router.post(
  '/',
  ...canPublishReleases,
  appReleaseUpload.single('file'),
  appReleaseController.create,
);
router.get('/:id/download', ...canViewReleases, appReleaseController.download);
router.get('/:id', ...canViewReleases, appReleaseController.getById);
router.put(
  '/:id',
  ...canPublishReleases,
  appReleaseUpload.single('file'),
  appReleaseController.update,
);
router.post('/:id/set-current', ...canPublishReleases, appReleaseController.setCurrent);
router.delete('/:id', ...canPublishReleases, appReleaseController.remove);

export default router;

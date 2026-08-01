import fs from 'fs';
import path from 'path';
import multer from 'multer';
import {
  MAX_APP_RELEASE_BYTES,
  MAX_DOCUMENT_BYTES,
  UPLOAD_ROOT,
  ensureAppReleasesDir,
} from '../utils/fileStorage';

/** In-memory buffer — small driver docs are written to disk in the controller after validation. */
export const documentUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_DOCUMENT_BYTES, files: 1 },
});

/**
 * Stream APK/AAB straight into the releases tree (same filesystem as final storage).
 * Avoids /tmp → uploads/ cross-device copy, which doubles disk I/O on Contabo VPSes.
 */
const appReleaseIncomingDir = path.join(UPLOAD_ROOT, 'releases', '.incoming');
fs.mkdirSync(appReleaseIncomingDir, { recursive: true });

export const appReleaseUpload = multer({
  storage: multer.diskStorage({
    destination: (_req, _file, cb) => {
      void ensureAppReleasesDir()
        .then(() => {
          fs.mkdirSync(appReleaseIncomingDir, { recursive: true });
          cb(null, appReleaseIncomingDir);
        })
        .catch((err) => cb(err as Error, appReleaseIncomingDir));
    },
    filename: (_req, file, cb) => {
      const safe = file.originalname.replace(/[^a-zA-Z0-9._-]/g, '_');
      cb(null, `${Date.now()}-${safe}`);
    },
  }),
  limits: { fileSize: MAX_APP_RELEASE_BYTES, files: 1 },
});

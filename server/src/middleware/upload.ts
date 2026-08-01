import fs from 'fs';
import os from 'os';
import path from 'path';
import multer from 'multer';
import { MAX_APP_RELEASE_BYTES, MAX_DOCUMENT_BYTES } from '../utils/fileStorage';

/** In-memory buffer — small driver docs are written to disk in the controller after validation. */
export const documentUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_DOCUMENT_BYTES, files: 1 },
});

const appReleaseTmpDir = path.join(os.tmpdir(), 'countryboy-app-releases');
fs.mkdirSync(appReleaseTmpDir, { recursive: true });

/**
 * APK/AAB uploads stream to disk (not RAM). Large packages (60–150 MB) would
 * otherwise pin Node memory and feel like a stalled upload behind Nginx.
 */
export const appReleaseUpload = multer({
  storage: multer.diskStorage({
    destination: (_req, _file, cb) => cb(null, appReleaseTmpDir),
    filename: (_req, file, cb) => {
      const safe = file.originalname.replace(/[^a-zA-Z0-9._-]/g, '_');
      cb(null, `${Date.now()}-${safe}`);
    },
  }),
  limits: { fileSize: MAX_APP_RELEASE_BYTES, files: 1 },
});

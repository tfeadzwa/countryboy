import multer from 'multer';
import { MAX_APP_RELEASE_BYTES, MAX_DOCUMENT_BYTES } from '../utils/fileStorage';

/** In-memory buffer — files are written to disk in the controller after validation. */
export const documentUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_DOCUMENT_BYTES, files: 1 },
});

/** Mobile APK/AAB uploads — larger limit; written to disk in the service. */
export const appReleaseUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_APP_RELEASE_BYTES, files: 1 },
});

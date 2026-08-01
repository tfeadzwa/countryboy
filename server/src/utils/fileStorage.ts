import fs from 'fs/promises';
import path from 'path';
import { v4 as uuidv4 } from 'uuid';

export const UPLOAD_ROOT = process.env.UPLOAD_DIR || path.join(process.cwd(), 'uploads');

export const ALLOWED_DOCUMENT_MIMES = new Set([
  'application/pdf',
  'image/jpeg',
  'image/png',
  'image/webp',
]);

export const ALLOWED_DOCUMENT_EXTENSIONS = new Set([
  '.pdf',
  '.jpg',
  '.jpeg',
  '.png',
  '.webp',
]);

export const MAX_DOCUMENT_BYTES = 10 * 1024 * 1024; // 10 MB

const EXT_BY_MIME: Record<string, string> = {
  'application/pdf': '.pdf',
  'image/jpeg': '.jpg',
  'image/png': '.png',
  'image/webp': '.webp',
};

const MIME_BY_EXT: Record<string, string> = {
  '.pdf': 'application/pdf',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png': 'image/png',
  '.webp': 'image/webp',
};

export const MAX_APP_RELEASE_BYTES = 150 * 1024 * 1024; // 150 MB

export const ALLOWED_APP_RELEASE_MIMES = new Set([
  'application/vnd.android.package-archive',
  'application/octet-stream',
  'application/java-archive',
]);

export const ALLOWED_APP_RELEASE_EXTENSIONS = new Set(['.apk', '.aab']);

/** Ensure uploads root and drivers subdirectory exist (call at startup and before writes). */
export async function ensureUploadRoot(): Promise<string> {
  const driversRoot = path.join(UPLOAD_ROOT, 'drivers');
  const releasesRoot = path.join(UPLOAD_ROOT, 'releases');
  await fs.mkdir(driversRoot, { recursive: true });
  await fs.mkdir(releasesRoot, { recursive: true });
  return UPLOAD_ROOT;
}

export function appReleasesDir(): string {
  return path.join(UPLOAD_ROOT, 'releases');
}

export async function ensureAppReleasesDir(): Promise<string> {
  await ensureUploadRoot();
  const dir = appReleasesDir();
  await fs.mkdir(dir, { recursive: true });
  return dir;
}

export function resolveAppReleaseMime(originalName: string, mimetype?: string): string | null {
  const ext = path.extname(originalName).toLowerCase();
  if (!ALLOWED_APP_RELEASE_EXTENSIONS.has(ext)) return null;

  const normalized = mimetype?.split(';')[0]?.trim().toLowerCase();
  if (normalized && ALLOWED_APP_RELEASE_MIMES.has(normalized)) {
    return normalized === 'application/octet-stream'
      ? 'application/vnd.android.package-archive'
      : normalized;
  }

  // Browsers often omit or misreport APK mime — trust extension after allow-list check.
  return 'application/vnd.android.package-archive';
}

export function buildAppReleaseRelativePath(
  versionName: string,
  versionCode: number,
  originalName: string,
): string {
  const ext = path.extname(originalName).toLowerCase() || '.apk';
  const safeVersion = versionName.replace(/[^a-zA-Z0-9._-]/g, '_');
  const fileName = `countryboy-${safeVersion}-${versionCode}-${uuidv4()}${ext}`;
  return path.join('releases', fileName);
}

export function driverDocumentDir(driverId: string): string {
  return path.join(UPLOAD_ROOT, 'drivers', driverId);
}

export async function ensureDriverDocumentDir(driverId: string): Promise<string> {
  await ensureUploadRoot();
  const dir = driverDocumentDir(driverId);
  await fs.mkdir(dir, { recursive: true });
  return dir;
}

export function resolveStoredFile(storedPath: string): string {
  const absolute = path.resolve(UPLOAD_ROOT, storedPath);
  const root = path.resolve(UPLOAD_ROOT);
  if (!absolute.startsWith(root + path.sep) && absolute !== root) {
    throw new Error('Invalid file path');
  }
  return absolute;
}

export function extensionForUpload(originalName: string, mimetype: string): string {
  const ext = path.extname(originalName).toLowerCase();
  if (ALLOWED_DOCUMENT_EXTENSIONS.has(ext)) {
    return ext === '.jpeg' ? '.jpg' : ext;
  }
  return EXT_BY_MIME[mimetype] ?? '.bin';
}

export function resolveUploadMime(originalName: string, mimetype?: string): string | null {
  const normalized = mimetype?.split(';')[0]?.trim().toLowerCase();
  if (normalized && ALLOWED_DOCUMENT_MIMES.has(normalized)) {
    return normalized;
  }

  const ext = path.extname(originalName).toLowerCase();
  const fromExt = MIME_BY_EXT[ext === '.jpeg' ? '.jpg' : ext];
  return fromExt && ALLOWED_DOCUMENT_MIMES.has(fromExt) ? fromExt : null;
}

export function buildStoredRelativePath(
  driverId: string,
  documentType: string,
  originalName: string,
  mimetype: string,
): string {
  const ext = extensionForUpload(originalName, mimetype);
  const fileName = `${documentType}-${uuidv4()}${ext}`;
  return path.join('drivers', driverId, fileName);
}

export async function deleteStoredFile(storedPath: string | null | undefined): Promise<void> {
  if (!storedPath) return;
  try {
    await fs.unlink(resolveStoredFile(storedPath));
  } catch (err) {
    const code = (err as NodeJS.ErrnoException).code;
    if (code !== 'ENOENT') throw err;
  }
}

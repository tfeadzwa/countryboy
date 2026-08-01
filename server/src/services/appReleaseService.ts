import fs from 'fs/promises';
import path from 'path';
import prisma from '../utils/prisma';
import {
  buildAppReleaseRelativePath,
  deleteStoredFile,
  ensureAppReleasesDir,
  resolveAppReleaseMime,
  resolveStoredFile,
  UPLOAD_ROOT,
} from '../utils/fileStorage';

export type AppReleaseInput = {
  version_name: string;
  version_code: number;
  mobile_notes?: string | null;
  admin_notes?: string | null;
  /** @deprecated Prefer mobile_notes / admin_notes */
  release_notes?: string | null;
  set_as_current?: boolean;
};

type ReleaseRow = {
  id: string;
  version_name: string;
  version_code: number;
  platform: string;
  file_path: string;
  file_name: string;
  file_size: number;
  mime_type: string | null;
  release_notes: string | null;
  mobile_notes: string | null;
  admin_notes: string | null;
  is_current: boolean;
  uploaded_by: string | null;
  created_at: Date;
  updated_at: Date;
};

const trimOrNull = (value?: string | null): string | null => {
  const trimmed = value?.trim();
  return trimmed ? trimmed : null;
};

const normalizeNotes = (data: AppReleaseInput) => {
  const mobile_notes = trimOrNull(data.mobile_notes) ?? trimOrNull(data.release_notes);
  const admin_notes = trimOrNull(data.admin_notes);
  // Keep legacy column as a combined preview for older clients.
  const release_notes =
    [mobile_notes, admin_notes].filter(Boolean).join('\n\n') || null;
  return { mobile_notes, admin_notes, release_notes };
};

const formatRelease = (release: ReleaseRow) => {
  const mobile_notes =
    trimOrNull(release.mobile_notes) ?? trimOrNull(release.release_notes);
  const admin_notes = trimOrNull(release.admin_notes);

  return {
    id: release.id,
    version_name: release.version_name,
    version_code: release.version_code,
    platform: release.platform,
    file_name: release.file_name,
    file_size: release.file_size,
    mime_type: release.mime_type,
    release_notes: release.release_notes,
    mobile_notes,
    admin_notes,
    is_current: release.is_current,
    uploaded_by: release.uploaded_by,
    created_at: release.created_at.toISOString(),
    updated_at: release.updated_at.toISOString(),
  };
};

export const listAppReleases = async () => {
  const releases = await prisma.tblAppReleases.findMany({
    orderBy: [{ is_current: 'desc' }, { version_code: 'desc' }, { created_at: 'desc' }],
  });
  return releases.map((r) => formatRelease(r as ReleaseRow));
};

export const getCurrentAppRelease = async () => {
  const release = await prisma.tblAppReleases.findFirst({
    where: { is_current: true, platform: 'android' },
    orderBy: { created_at: 'desc' },
  });
  return release ? formatRelease(release as ReleaseRow) : null;
};

export const getAppRelease = async (id: string) => {
  const release = await prisma.tblAppReleases.findUnique({ where: { id } });
  return release ? formatRelease(release as ReleaseRow) : null;
};

export const createAppRelease = async (
  data: AppReleaseInput,
  file: Express.Multer.File,
  uploadedBy?: string,
) => {
  const versionName = data.version_name.trim();
  const versionCode = Number(data.version_code);

  if (!versionName) {
    throw new Error('Version name is required');
  }
  if (!Number.isInteger(versionCode) || versionCode < 1) {
    throw new Error('Version code must be a positive integer');
  }

  const mime = resolveAppReleaseMime(file.originalname, file.mimetype);
  if (!mime) {
    throw new Error('File type not allowed. Upload an Android APK or AAB.');
  }

  const existing = await prisma.tblAppReleases.findFirst({
    where: {
      platform: 'android',
      version_name: versionName,
      version_code: versionCode,
    },
  });
  if (existing) {
    throw new Error(`Release ${versionName} (${versionCode}) already exists`);
  }

  const notes = normalizeNotes(data);
  const relativePath = buildAppReleaseRelativePath(versionName, versionCode, file.originalname);
  await ensureAppReleasesDir();
  const absolutePath = path.join(UPLOAD_ROOT, relativePath);
  await fs.writeFile(absolutePath, file.buffer);

  const setAsCurrent = data.set_as_current !== false;

  const release = await prisma.$transaction(async (tx) => {
    if (setAsCurrent) {
      await tx.tblAppReleases.updateMany({
        where: { platform: 'android', is_current: true },
        data: { is_current: false },
      });
    }

    return tx.tblAppReleases.create({
      data: {
        version_name: versionName,
        version_code: versionCode,
        platform: 'android',
        file_path: relativePath.replace(/\\/g, '/'),
        file_name: file.originalname,
        file_size: file.size,
        mime_type: mime,
        release_notes: notes.release_notes,
        mobile_notes: notes.mobile_notes,
        admin_notes: notes.admin_notes,
        is_current: setAsCurrent,
        uploaded_by: uploadedBy,
      },
    });
  });

  return formatRelease(release as ReleaseRow);
};

export const updateAppRelease = async (
  id: string,
  data: AppReleaseInput,
  file?: Express.Multer.File,
) => {
  const existing = await prisma.tblAppReleases.findUnique({ where: { id } });
  if (!existing) {
    throw new Error('Release not found');
  }

  const versionName = data.version_name.trim();
  const versionCode = Number(data.version_code);

  if (!versionName) {
    throw new Error('Version name is required');
  }
  if (!Number.isInteger(versionCode) || versionCode < 1) {
    throw new Error('Version code must be a positive integer');
  }

  const conflict = await prisma.tblAppReleases.findFirst({
    where: {
      platform: existing.platform,
      version_name: versionName,
      version_code: versionCode,
      NOT: { id },
    },
  });
  if (conflict) {
    throw new Error(`Release ${versionName} (${versionCode}) already exists`);
  }

  let fileFields: {
    file_path?: string;
    file_name?: string;
    file_size?: number;
    mime_type?: string;
  } = {};
  let previousFilePath: string | null = null;

  if (file) {
    const mime = resolveAppReleaseMime(file.originalname, file.mimetype);
    if (!mime) {
      throw new Error('File type not allowed. Upload an Android APK or AAB.');
    }

    const relativePath = buildAppReleaseRelativePath(versionName, versionCode, file.originalname);
    await ensureAppReleasesDir();
    const absolutePath = path.join(UPLOAD_ROOT, relativePath);
    await fs.writeFile(absolutePath, file.buffer);

    previousFilePath = existing.file_path;
    fileFields = {
      file_path: relativePath.replace(/\\/g, '/'),
      file_name: file.originalname,
      file_size: file.size,
      mime_type: mime,
    };
  }

  const notes = normalizeNotes(data);
  const setAsCurrent = data.set_as_current === true;

  try {
    const release = await prisma.$transaction(async (tx) => {
      if (setAsCurrent) {
        await tx.tblAppReleases.updateMany({
          where: { platform: existing.platform, is_current: true },
          data: { is_current: false },
        });
      }

      return tx.tblAppReleases.update({
        where: { id },
        data: {
          version_name: versionName,
          version_code: versionCode,
          release_notes: notes.release_notes,
          mobile_notes: notes.mobile_notes,
          admin_notes: notes.admin_notes,
          ...(setAsCurrent ? { is_current: true } : {}),
          ...fileFields,
        },
      });
    });

    if (previousFilePath && previousFilePath !== release.file_path) {
      await deleteStoredFile(previousFilePath);
    }

    return formatRelease(release as ReleaseRow);
  } catch (err) {
    if (file && fileFields.file_path) {
      await deleteStoredFile(fileFields.file_path);
    }
    throw err;
  }
};

export const setCurrentAppRelease = async (id: string) => {
  const existing = await prisma.tblAppReleases.findUnique({ where: { id } });
  if (!existing) {
    throw new Error('Release not found');
  }

  const release = await prisma.$transaction(async (tx) => {
    await tx.tblAppReleases.updateMany({
      where: { platform: existing.platform, is_current: true },
      data: { is_current: false },
    });
    return tx.tblAppReleases.update({
      where: { id },
      data: { is_current: true },
    });
  });

  return formatRelease(release as ReleaseRow);
};

export const getAppReleaseForDownload = async (id: string) => {
  const release = await prisma.tblAppReleases.findUnique({ where: { id } });
  if (!release) {
    throw new Error('Release not found');
  }

  const absolutePath = resolveStoredFile(release.file_path);
  return {
    absolutePath,
    fileName: release.file_name,
    mimeType: release.mime_type ?? 'application/vnd.android.package-archive',
  };
};

export const deleteAppRelease = async (id: string) => {
  const existing = await prisma.tblAppReleases.findUnique({ where: { id } });
  if (!existing) {
    throw new Error('Release not found');
  }

  await prisma.tblAppReleases.delete({ where: { id } });
  await deleteStoredFile(existing.file_path);

  if (existing.is_current) {
    const newest = await prisma.tblAppReleases.findFirst({
      where: { platform: existing.platform },
      orderBy: [{ version_code: 'desc' }, { created_at: 'desc' }],
    });
    if (newest) {
      await prisma.tblAppReleases.update({
        where: { id: newest.id },
        data: { is_current: true },
      });
    }
  }
};

import { Response } from 'express';
import { AuthenticatedRequest } from '../middleware/auth';
import * as appReleaseService from '../services/appReleaseService';
import { formatPrismaError } from '../utils/prismaErrors';

const parseSetAsCurrent = (raw: unknown, defaultWhenMissing: boolean) => {
  if (raw === undefined || raw === '') return defaultWhenMissing;
  return raw === true || raw === 'true' || raw === '1';
};

const parseNotesBody = (body: Record<string, unknown>) => ({
  mobile_notes: (body?.mobile_notes as string | null | undefined) ?? null,
  admin_notes: (body?.admin_notes as string | null | undefined) ?? null,
  release_notes: (body?.release_notes as string | null | undefined) ?? null,
});

export const list = async (_req: AuthenticatedRequest, res: Response) => {
  try {
    const releases = await appReleaseService.listAppReleases();
    res.json(releases);
  } catch (err) {
    res.status(500).json({ error: 'Unable to list app releases', details: err });
  }
};

export const getCurrent = async (_req: AuthenticatedRequest, res: Response) => {
  try {
    const release = await appReleaseService.getCurrentAppRelease();
    if (!release) {
      return res.status(404).json({ error: 'No current app release published' });
    }
    res.json(release);
  } catch (err) {
    res.status(500).json({ error: 'Unable to fetch current release', details: err });
  }
};

export const getById = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const release = await appReleaseService.getAppRelease(req.params.id);
    if (!release) {
      return res.status(404).json({ error: 'Release not found' });
    }
    res.json(release);
  } catch (err) {
    res.status(500).json({ error: 'Unable to fetch release', details: err });
  }
};

export const create = async (req: AuthenticatedRequest, res: Response) => {
  const file = req.file;
  if (!file) {
    return res.status(400).json({ error: 'No APK/AAB file uploaded' });
  }

  const version_name = String(req.body?.version_name ?? '');
  const version_code = Number(req.body?.version_code);
  const notes = parseNotesBody(req.body ?? {});
  const set_as_current = parseSetAsCurrent(req.body?.set_as_current, true);

  try {
    const release = await appReleaseService.createAppRelease(
      {
        version_name,
        version_code,
        ...notes,
        set_as_current,
      },
      file,
      req.user?.id,
    );
    res.status(201).json(release);
  } catch (err) {
    if (err instanceof Error) {
      if (
        err.message.includes('required') ||
        err.message.includes('not allowed') ||
        err.message.includes('already exists') ||
        err.message.includes('positive')
      ) {
        return res.status(400).json({ error: err.message });
      }
    }
    const friendly = formatPrismaError(err);
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(400).json({ error: 'Could not publish app release', details: err });
  }
};

export const download = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { absolutePath, fileName } = await appReleaseService.getAppReleaseForDownload(
      req.params.id,
    );
    res.download(absolutePath, fileName);
  } catch (err) {
    if (err instanceof Error && err.message === 'Release not found') {
      return res.status(404).json({ error: err.message });
    }
    res.status(500).json({ error: 'Could not download release', details: err });
  }
};

export const update = async (req: AuthenticatedRequest, res: Response) => {
  const version_name = String(req.body?.version_name ?? '');
  const version_code = Number(req.body?.version_code);
  const notes = parseNotesBody(req.body ?? {});
  const set_as_current = parseSetAsCurrent(req.body?.set_as_current, false);

  try {
    const release = await appReleaseService.updateAppRelease(
      req.params.id,
      {
        version_name,
        version_code,
        ...notes,
        set_as_current,
      },
      req.file,
    );
    res.json(release);
  } catch (err) {
    if (err instanceof Error && err.message === 'Release not found') {
      return res.status(404).json({ error: err.message });
    }
    if (err instanceof Error) {
      if (
        err.message.includes('required') ||
        err.message.includes('not allowed') ||
        err.message.includes('already exists') ||
        err.message.includes('positive')
      ) {
        return res.status(400).json({ error: err.message });
      }
    }
    const friendly = formatPrismaError(err);
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(400).json({ error: 'Could not update app release', details: err });
  }
};

export const setCurrent = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const release = await appReleaseService.setCurrentAppRelease(req.params.id);
    res.json(release);
  } catch (err) {
    if (err instanceof Error && err.message === 'Release not found') {
      return res.status(404).json({ error: err.message });
    }
    res.status(400).json({ error: 'Could not set current release', details: err });
  }
};

export const remove = async (req: AuthenticatedRequest, res: Response) => {
  try {
    await appReleaseService.deleteAppRelease(req.params.id);
    res.json({ message: 'Release deleted successfully' });
  } catch (err) {
    if (err instanceof Error && err.message === 'Release not found') {
      return res.status(404).json({ error: err.message });
    }
    res.status(400).json({ error: 'Could not delete release', details: err });
  }
};

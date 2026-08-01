import apiClient from './axios';

export interface AppRelease {
  id: string;
  version_name: string;
  version_code: number;
  platform: string;
  file_name: string;
  file_size: number;
  mime_type?: string | null;
  /** @deprecated Prefer mobile_notes / admin_notes */
  release_notes?: string | null;
  mobile_notes?: string | null;
  admin_notes?: string | null;
  is_current: boolean;
  uploaded_by?: string | null;
  created_at: string;
  updated_at: string;
}

export type UploadProgressHandler = (percent: number) => void;

export interface PublishAppReleaseRequest {
  version_name: string;
  version_code: number;
  mobile_notes?: string;
  admin_notes?: string;
  set_as_current?: boolean;
  file: File;
  onUploadProgress?: UploadProgressHandler;
}

export interface UpdateAppReleaseRequest {
  version_name: string;
  version_code: number;
  mobile_notes?: string;
  admin_notes?: string;
  set_as_current?: boolean;
  /** Optional — omit to keep the existing package. */
  file?: File;
  onUploadProgress?: UploadProgressHandler;
}

export const getMobileNotes = (release: AppRelease): string =>
  release.mobile_notes?.trim() || release.release_notes?.trim() || '';

export const getAdminNotes = (release: AppRelease): string =>
  release.admin_notes?.trim() || '';

export const hasReleaseNotes = (release: AppRelease): boolean =>
  Boolean(getMobileNotes(release) || getAdminNotes(release));

class AppReleaseService {
  async list(): Promise<AppRelease[]> {
    const response = await apiClient.get<AppRelease[]>('/app-releases');
    return response.data;
  }

  async getById(id: string): Promise<AppRelease> {
    const response = await apiClient.get<AppRelease>(`/app-releases/${id}`);
    return response.data;
  }

  async getCurrent(): Promise<AppRelease | null> {
    try {
      const response = await apiClient.get<AppRelease>('/app-releases/current');
      return response.data;
    } catch (err) {
      if (err instanceof Error && /not found|404/i.test(err.message)) {
        return null;
      }
      throw err;
    }
  }

  async publish(data: PublishAppReleaseRequest): Promise<AppRelease> {
    const form = new FormData();
    form.append('file', data.file);
    form.append('version_name', data.version_name);
    form.append('version_code', String(data.version_code));
    form.append('mobile_notes', data.mobile_notes ?? '');
    form.append('admin_notes', data.admin_notes ?? '');
    form.append('set_as_current', data.set_as_current === false ? 'false' : 'true');

    const response = await apiClient.post<AppRelease>('/app-releases', form, {
      timeout: 600000,
      onUploadProgress: (event) => {
        if (!data.onUploadProgress) return;
        if (!event.total) {
          data.onUploadProgress(0);
          return;
        }
        data.onUploadProgress(Math.min(100, Math.round((event.loaded * 100) / event.total)));
      },
    });
    return response.data;
  }

  async update(id: string, data: UpdateAppReleaseRequest): Promise<AppRelease> {
    const form = new FormData();
    if (data.file) {
      form.append('file', data.file);
    }
    form.append('version_name', data.version_name);
    form.append('version_code', String(data.version_code));
    form.append('mobile_notes', data.mobile_notes ?? '');
    form.append('admin_notes', data.admin_notes ?? '');
    form.append('set_as_current', data.set_as_current ? 'true' : 'false');

    const response = await apiClient.put<AppRelease>(`/app-releases/${id}`, form, {
      timeout: 600000,
      onUploadProgress: data.file
        ? (event) => {
            if (!data.onUploadProgress) return;
            if (!event.total) {
              data.onUploadProgress(0);
              return;
            }
            data.onUploadProgress(Math.min(100, Math.round((event.loaded * 100) / event.total)));
          }
        : undefined,
    });
    return response.data;
  }

  async download(id: string): Promise<Blob> {
    const response = await apiClient.get<Blob>(`/app-releases/${id}/download`, {
      responseType: 'blob',
      timeout: 180000,
    });
    return response.data;
  }

  async setCurrent(id: string): Promise<AppRelease> {
    const response = await apiClient.post<AppRelease>(`/app-releases/${id}/set-current`);
    return response.data;
  }

  async remove(id: string): Promise<void> {
    await apiClient.delete(`/app-releases/${id}`);
  }
}

export const appReleaseService = new AppReleaseService();

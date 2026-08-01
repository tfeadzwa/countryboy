import apiClient from './axios';
import type { Driver, DriverDocumentKey, DriverStatus } from '@/types';
import type { PaginatedResult } from '@/types/pagination';
import { DEFAULT_PAGE_SIZE, normalizePaginatedResult } from '@/types/pagination';

export interface CreateDriverRequest {
  full_name: string;
  phone?: string | null;
  licence_number?: string | null;
  defensive_driving_certificate_number?: string | null;
  status?: DriverStatus;
}

export interface UpdateDriverRequest {
  full_name?: string;
  phone?: string | null;
  licence_number?: string | null;
  defensive_driving_certificate_number?: string | null;
  status?: DriverStatus;
  depot_id?: string;
  drivers_licence_expiry?: string | null;
  medical_certificate_expiry?: string | null;
  defensive_driving_certificate_expiry?: string | null;
}

class DriverService {
  async getAll(): Promise<Driver[]> {
    const response = await apiClient.get<Driver[]>('/drivers');
    return response.data;
  }

  async listPaginated(page = 1, pageSize = DEFAULT_PAGE_SIZE): Promise<PaginatedResult<Driver>> {
    const response = await apiClient.get<PaginatedResult<Driver> | Driver[]>('/drivers', {
      params: { page, limit: pageSize },
    });
    return normalizePaginatedResult(response.data, page, pageSize);
  }

  async getOne(id: string): Promise<Driver> {
    const response = await apiClient.get<Driver>(`/drivers/${id}`);
    return response.data;
  }

  async create(data: CreateDriverRequest, depotId?: string): Promise<Driver> {
    const config = depotId ? { headers: { 'x-depot-id': depotId } } : {};
    const response = await apiClient.post<Driver>('/drivers', data, config);
    return response.data;
  }

  async update(id: string, data: UpdateDriverRequest, depotId?: string): Promise<Driver> {
    const config = depotId ? { headers: { 'x-depot-id': depotId } } : {};
    const response = await apiClient.put<Driver>(`/drivers/${id}`, data, config);
    return response.data;
  }

  async remove(id: string, depotId?: string): Promise<void> {
    const config = depotId ? { headers: { 'x-depot-id': depotId } } : {};
    await apiClient.delete(`/drivers/${id}`, config);
  }

  async uploadDocument(
    id: string,
    type: DriverDocumentKey,
    file: File,
    expiryDate: string | null,
    depotId?: string,
  ): Promise<Driver> {
    const form = new FormData();
    form.append('file', file);
    if (expiryDate) {
      form.append('expiry_date', expiryDate);
    } else {
      form.append('expiry_date', '');
    }

    const response = await apiClient.post<Driver>(`/drivers/${id}/documents/${type}`, form, {
      headers: depotId ? { 'x-depot-id': depotId } : {},
    });
    return response.data;
  }

  async downloadDocument(id: string, type: DriverDocumentKey, depotId?: string): Promise<Blob> {
    const response = await apiClient.get<Blob>(`/drivers/${id}/documents/${type}/download`, {
      responseType: 'blob',
      headers: depotId ? { 'x-depot-id': depotId } : {},
    });
    return response.data;
  }

  async removeDocument(id: string, type: DriverDocumentKey, depotId?: string): Promise<Driver> {
    const config = depotId ? { headers: { 'x-depot-id': depotId } } : {};
    const response = await apiClient.delete<Driver>(`/drivers/${id}/documents/${type}`, config);
    return response.data;
  }
}

export const driverService = new DriverService();

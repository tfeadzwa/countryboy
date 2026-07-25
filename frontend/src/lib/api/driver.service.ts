import apiClient from './axios';
import type { Driver, DriverStatus } from '@/types';
import type { PaginatedResult } from '@/types/pagination';
import { DEFAULT_PAGE_SIZE, normalizePaginatedResult } from '@/types/pagination';

export interface CreateDriverRequest {
  full_name: string;
  phone?: string | null;
  licence_number?: string | null;
  status?: DriverStatus;
}

export interface UpdateDriverRequest {
  full_name?: string;
  phone?: string | null;
  licence_number?: string | null;
  status?: DriverStatus;
  depot_id?: string;
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
}

export const driverService = new DriverService();

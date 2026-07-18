import apiClient from './axios';
import { Fleet } from '@/types';
import type { PaginatedResult } from '@/types/pagination';
import { DEFAULT_PAGE_SIZE } from '@/types/pagination';

export interface FleetComplianceDates {
  licence_disc_expiry: string;
  cof_expiry: string;
  passenger_liability_expiry: string;
  route_authority_expiry: string;
  ppa_expiry: string;
}

export interface CreateFleetRequest extends FleetComplianceDates {
  number: string;
  status?: 'ACTIVE' | 'MAINTENANCE' | 'OUT_OF_SERVICE' | 'RETIRED';
  capacity?: number;
}

export interface UpdateFleetRequest extends FleetComplianceDates {
  number?: string;
  status?: 'ACTIVE' | 'MAINTENANCE' | 'OUT_OF_SERVICE' | 'RETIRED';
  capacity?: number;
}

class FleetService {
  async getAll(): Promise<Fleet[]> {
    const response = await apiClient.get<Fleet[]>('/fleets');
    return response.data;
  }

  async listPaginated(page = 1, pageSize = DEFAULT_PAGE_SIZE): Promise<PaginatedResult<Fleet>> {
    const response = await apiClient.get<PaginatedResult<Fleet>>('/fleets', {
      params: { page, limit: pageSize },
    });
    return response.data;
  }

  async getOne(id: string): Promise<Fleet> {
    const response = await apiClient.get<Fleet>(`/fleets/${id}`);
    return response.data;
  }

  async create(data: CreateFleetRequest, depotId?: string): Promise<Fleet> {
    const config = depotId
      ? { headers: { 'x-depot-id': depotId } }
      : {};
    const response = await apiClient.post<Fleet>('/fleets', data, config);
    return response.data;
  }

  async update(id: string, data: UpdateFleetRequest, depotId?: string): Promise<Fleet> {
    const config = depotId
      ? { headers: { 'x-depot-id': depotId } }
      : {};
    const response = await apiClient.put<Fleet>(`/fleets/${id}`, data, config);
    return response.data;
  }

  async delete(id: string, depotId?: string): Promise<void> {
    const config = depotId ? { headers: { 'x-depot-id': depotId } } : {};
    await apiClient.delete(`/fleets/${id}`, config);
  }
}

export const fleetService = new FleetService();

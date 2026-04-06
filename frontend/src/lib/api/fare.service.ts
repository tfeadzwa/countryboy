import apiClient from './axios';
import { Fare } from '@/types';

export interface CreateFareRequest {
  route_id: string;
  currency: string;
  amount: number;
}

export interface UpdateFareRequest {
  currency?: string;
  amount?: number;
}

class FareService {
  /**
   * Get all fares (filtered by depot scope automatically on backend)
   */
  async getAll(): Promise<Fare[]> {
    const response = await apiClient.get<Fare[]>('/fares');
    return response.data;
  }

  /**
   * Get a single fare by ID
   */
  async getOne(id: string): Promise<Fare> {
    const response = await apiClient.get<Fare>(`/fares/${id}`);
    return response.data;
  }

  /**
   * Create a new fare
   * Requires DEPOT_ADMIN or SUPER_ADMIN role
   * @param data - Fare data
   * @param depotId - Required for SUPER_ADMIN to specify which depot the fare belongs to
   */
  async create(data: CreateFareRequest, depotId?: string): Promise<Fare> {
    const config = depotId ? {
      headers: { 'x-depot-id': depotId }
    } : {};
    const response = await apiClient.post<Fare>('/fares', data, config);
    return response.data;
  }

  /**
   * Update an existing fare
   * Requires DEPOT_ADMIN or SUPER_ADMIN role
   * @param id - Fare ID
   * @param data - Fare data to update
   * @param depotId - Required for SUPER_ADMIN to specify depot context
   */
  async update(id: string, data: UpdateFareRequest, depotId?: string): Promise<Fare> {
    const config = depotId ? {
      headers: { 'x-depot-id': depotId }
    } : {};
    const response = await apiClient.put<Fare>(`/fares/${id}`, data, config);
    return response.data;
  }
}

export const fareService = new FareService();

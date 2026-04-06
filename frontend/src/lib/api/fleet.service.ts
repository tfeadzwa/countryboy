import apiClient from './axios';
import { Fleet } from '@/types';

export interface CreateFleetRequest {
  number: string;
  status?: 'ACTIVE' | 'MAINTENANCE' | 'OUT_OF_SERVICE' | 'RETIRED';
  capacity?: number;
}

export interface UpdateFleetRequest {
  number?: string;
  status?: 'ACTIVE' | 'MAINTENANCE' | 'OUT_OF_SERVICE' | 'RETIRED';
  capacity?: number;
}

class FleetService {
  /**
   * Get all fleets (filtered by depot scope automatically on backend)
   */
  async getAll(): Promise<Fleet[]> {
    const response = await apiClient.get<Fleet[]>('/fleets');
    return response.data;
  }

  /**
   * Get a single fleet by ID
   */
  async getOne(id: string): Promise<Fleet> {
    const response = await apiClient.get<Fleet>(`/fleets/${id}`);
    return response.data;
  }

  /**
   * Create a new fleet
   * Requires DEPOT_ADMIN or SUPER_ADMIN role
   * @param data - Fleet data
   * @param depotId - Required for SUPER_ADMIN to specify which depot the fleet belongs to
   */
  async create(data: CreateFleetRequest, depotId?: string): Promise<Fleet> {
    const config = depotId ? {
      headers: { 'x-depot-id': depotId }
    } : {};
    const response = await apiClient.post<Fleet>('/fleets', data, config);
    return response.data;
  }

  /**
   * Update an existing fleet
   * Requires DEPOT_ADMIN or SUPER_ADMIN role
   * @param id - Fleet ID
   * @param data - Fleet data to update
   * @param depotId - Required for SUPER_ADMIN to specify depot context
   */
  async update(id: string, data: UpdateFleetRequest, depotId?: string): Promise<Fleet> {
    const config = depotId ? {
      headers: { 'x-depot-id': depotId }
    } : {};
    const response = await apiClient.put<Fleet>(`/fleets/${id}`, data, config);
    return response.data;
  }
}

export const fleetService = new FleetService();

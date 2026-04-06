import apiClient from './axios';
import { Depot } from '@/types';

export interface CreateDepotRequest {
  merchant_code: string;
  name: string;
  location?: string;
}

export interface DepotListResponse {
  depots: Depot[];
  count: number;
}

class DepotService {
  /**
   * Get all depots
   */
  async getAll(): Promise<Depot[]> {
    const response = await apiClient.get<Depot[]>('/depots');
    return response.data;
  }

  /**
   * Create a new depot
   */
  async create(data: CreateDepotRequest): Promise<Depot> {
    const response = await apiClient.post<Depot>('/depots', data);
    return response.data;
  }

  /**
   * Update an existing depot
   */
  async update(id: string | number, data: CreateDepotRequest): Promise<Depot> {
    const response = await apiClient.put<Depot>(`/depots/${id}`, data);
    return response.data;
  }
}

export const depotService = new DepotService();

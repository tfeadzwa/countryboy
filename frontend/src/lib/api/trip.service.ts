import apiClient from './axios';
import { Trip } from '@/types';

export interface TripFilters {
  status?: string;
  agent_id?: string;
  fleet_id?: string;
  date_from?: string;
  date_to?: string;
}

class TripService {
  /**
   * Get all trips (filtered by depot scope automatically on backend)
   */
  async getAll(filters?: TripFilters): Promise<Trip[]> {
    const response = await apiClient.get<Trip[]>('/trips', { params: filters });
    return response.data;
  }

  /**
   * Get active trips only
   */
  async getActive(): Promise<Trip[]> {
    const response = await apiClient.get<Trip[]>('/trips/active');
    return response.data;
  }

  /**
   * Get a single trip by ID
   */
  async getOne(id: string): Promise<Trip> {
    const response = await apiClient.get<Trip>(`/trips/${id}`);
    return response.data;
  }

  /**
   * Get trip totals (ticket count and revenue)
   */
  async getTotals(id: string): Promise<{ ticketCount: number; total: number }> {
    const response = await apiClient.get(`/trips/${id}/totals`);
    return response.data;
  }

  /**
   * Start a new trip (requires DEPOT_ADMIN role)
   */
  async start(data: {
    agent_id: string;
    fleet_id: string;
    route_id?: string;
    device_id?: string;
    started_offline?: boolean;
  }): Promise<Trip> {
    const response = await apiClient.post<Trip>('/trips', data);
    return response.data;
  }

  /**
   * End a trip (requires DEPOT_ADMIN role)
   */
  async end(id: string): Promise<Trip> {
    const response = await apiClient.post<Trip>(`/trips/${id}/end`);
    return response.data;
  }
}

export const tripService = new TripService();

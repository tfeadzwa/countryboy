import apiClient from './axios';
import { Trip, TripDetail } from '@/types';

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
   * Get a single trip by ID with full detail payload
   */
  async getOne(id: string): Promise<TripDetail> {
    const response = await apiClient.get<TripDetail>(`/trips/${id}`);
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
   * End a trip (requires SUPER_ADMIN or CASHIER).
   * @param depotId - Required for SUPER_ADMIN (use the trip's depot_id).
   * @param options.force - Super admin only: end while conductor is offline.
   * @param options.closingMileage - Required closing odometer reading (km).
   */
  async end(
    id: string,
    depotId?: string,
    options?: { force?: boolean; closingMileage: number },
  ): Promise<Trip> {
    const config = depotId ? { headers: { 'x-depot-id': depotId } } : {};
    const body: { closing_mileage: number; force?: boolean } = {
      closing_mileage: options!.closingMileage,
    };
    if (options?.force) body.force = true;
    const response = await apiClient.post<Trip>(`/trips/${id}/end`, body, config);
    return response.data;
  }
}

export const tripService = new TripService();

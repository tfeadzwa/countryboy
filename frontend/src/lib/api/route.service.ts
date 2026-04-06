import apiClient from './axios';
import { RouteInfo } from '@/types';

export interface CreateRouteRequest {
  origin: string;
  destination: string;
  is_active?: boolean;
  distance_km?: number;
}

export interface UpdateRouteRequest {
  origin?: string;
  destination?: string;
  is_active?: boolean;
  distance_km?: number;
}

class RouteService {
  /**
   * Get all routes (filtered by depot scope automatically on backend)
   */
  async getAll(): Promise<RouteInfo[]> {
    const response = await apiClient.get<RouteInfo[]>('/routes');
    return response.data;
  }

  /**
   * Get a single route by ID
   */
  async getOne(id: string): Promise<RouteInfo> {
    const response = await apiClient.get<RouteInfo>(`/routes/${id}`);
    return response.data;
  }

  /**
   * Create a new route
   * Requires DEPOT_ADMIN or SUPER_ADMIN role
   * @param data - Route data
   * @param depotId - Required for SUPER_ADMIN to specify which depot the route belongs to
   */
  async create(data: CreateRouteRequest, depotId?: string): Promise<RouteInfo> {
    const config = depotId ? {
      headers: { 'x-depot-id': depotId }
    } : {};
    const response = await apiClient.post<RouteInfo>('/routes', data, config);
    return response.data;
  }

  /**
   * Update an existing route
   * Requires DEPOT_ADMIN or SUPER_ADMIN role
   * @param id - Route ID
   * @param data - Route data to update
   * @param depotId - Required for SUPER_ADMIN to specify depot context
   */
  async update(id: string, data: UpdateRouteRequest, depotId?: string): Promise<RouteInfo> {
    const config = depotId ? {
      headers: { 'x-depot-id': depotId }
    } : {};
    const response = await apiClient.put<RouteInfo>(`/routes/${id}`, data, config);
    return response.data;
  }
}

export const routeService = new RouteService();

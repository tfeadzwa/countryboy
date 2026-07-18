import apiClient from './axios';
import { RouteInfo } from '@/types';
import type { PaginatedResult } from '@/types/pagination';
import { DEFAULT_PAGE_SIZE } from '@/types/pagination';

export interface CreateRouteRequest {
  origin: string;
  destination: string;
  parent_route_ids?: string[];
  /** @deprecated Prefer parent_route_ids */
  parent_route_id?: string;
  child_route_ids?: string[];
  is_active?: boolean;
  distance_km?: number;
}

export interface UpdateRouteRequest {
  origin?: string;
  destination?: string;
  parent_route_ids?: string[];
  /** @deprecated Prefer parent_route_ids */
  parent_route_id?: string | null;
  child_route_ids?: string[];
  is_active?: boolean;
  distance_km?: number;
}

class RouteService {
  async getAll(): Promise<RouteInfo[]> {
    const response = await apiClient.get<RouteInfo[]>('/routes');
    return response.data;
  }

  async listPaginated(page = 1, pageSize = DEFAULT_PAGE_SIZE): Promise<PaginatedResult<RouteInfo>> {
    const response = await apiClient.get<PaginatedResult<RouteInfo>>('/routes', {
      params: { page, limit: pageSize },
    });
    return response.data;
  }

  async getOne(id: string): Promise<RouteInfo> {
    const response = await apiClient.get<RouteInfo>(`/routes/${id}`);
    return response.data;
  }

  async getChildren(id: string): Promise<RouteInfo[]> {
    const response = await apiClient.get<RouteInfo[]>(`/routes/${id}/children`);
    return response.data;
  }

  async create(data: CreateRouteRequest, depotId?: string): Promise<RouteInfo> {
    const config = depotId ? {
      headers: { 'x-depot-id': depotId }
    } : {};
    const response = await apiClient.post<RouteInfo>('/routes', data, config);
    return response.data;
  }

  async update(id: string, data: UpdateRouteRequest, depotId?: string): Promise<RouteInfo> {
    const config = depotId ? {
      headers: { 'x-depot-id': depotId }
    } : {};
    const response = await apiClient.put<RouteInfo>(`/routes/${id}`, data, config);
    return response.data;
  }

  async delete(id: string, depotId?: string): Promise<void> {
    const config = depotId ? { headers: { 'x-depot-id': depotId } } : {};
    await apiClient.delete(`/routes/${id}`, config);
  }
}

export const routeService = new RouteService();

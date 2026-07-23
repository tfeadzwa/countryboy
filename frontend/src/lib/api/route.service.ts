import apiClient from './axios';
import { RouteInfo } from '@/types';
import type { PaginatedResult } from '@/types/pagination';
import { DEFAULT_PAGE_SIZE, normalizePaginatedResult } from '@/types/pagination';

export interface CorridorSummary {
  id: string;
  key: string;
  origin: string;
  destination: string;
  trip_count: number;
  active_trip_count: number;
  ticket_count: number;
  child_route_count?: number;
  last_trip_at: string | null;
  fleets: string[];
}

export interface CorridorDetail {
  id: string;
  origin: string;
  destination: string;
  label: string;
  depot: { id: string; name: string };
  is_active: boolean;
  created_at: string;
  summary: {
    trip_count: number;
    active_trip_count: number;
    ticket_count: number;
    child_route_count: number;
    fleets: string[];
    revenue_by_currency: Record<string, number>;
  };
  child_routes: Array<{
    id: string;
    origin: string;
    destination: string;
    label: string;
    is_active: boolean;
    ticket_count: number;
    revenue: number;
  }>;
  recent_trips: Array<{
    id: string;
    status: string;
    started_at: string;
    ended_at: string | null;
    fleet_number: string | null;
    agent_name: string | null;
    ticket_count: number;
    segments: string[];
  }>;
}

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
  async getCorridors(): Promise<CorridorSummary[]> {
    const response = await apiClient.get<CorridorSummary[]>('/routes/corridors');
    return response.data;
  }

  async getCorridor(id: string): Promise<CorridorDetail> {
    const response = await apiClient.get<CorridorDetail>(`/routes/corridors/${id}`);
    return response.data;
  }

  async getAll(): Promise<RouteInfo[]> {
    const response = await apiClient.get<RouteInfo[] | PaginatedResult<RouteInfo>>('/routes');
    const data = response.data;
    return Array.isArray(data) ? data : (data?.items ?? []);
  }

  async listPaginated(page = 1, pageSize = DEFAULT_PAGE_SIZE): Promise<PaginatedResult<RouteInfo>> {
    const response = await apiClient.get<PaginatedResult<RouteInfo> | RouteInfo[]>('/routes', {
      params: { page, limit: pageSize },
    });
    return normalizePaginatedResult(response.data, page, pageSize);
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
    const config = depotId
      ? {
          headers: { 'x-depot-id': depotId },
        }
      : {};
    const response = await apiClient.post<RouteInfo>('/routes', data, config);
    return response.data;
  }

  async update(id: string, data: UpdateRouteRequest, depotId?: string): Promise<RouteInfo> {
    const config = depotId
      ? {
          headers: { 'x-depot-id': depotId },
        }
      : {};
    const response = await apiClient.put<RouteInfo>(`/routes/${id}`, data, config);
    return response.data;
  }

  async delete(id: string, depotId?: string): Promise<void> {
    const config = depotId ? { headers: { 'x-depot-id': depotId } } : {};
    await apiClient.delete(`/routes/${id}`, config);
  }
}

export const routeService = new RouteService();

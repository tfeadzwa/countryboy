import axios from './axios';

export interface DashboardOverview {
  revenueToday: number;
  ticketCountToday: number;
  activeTrips: number;
  activeAgents: number;
}

export interface TimeSeriesData {
  date: string;
  usd: number;
  zwl: number;
  zar: number;
}

export interface CurrencyBreakdown {
  usd: number;
  zwl: number;
  zar: number;
}

export interface AgentMetric {
  agent_id: string;
  agent_name: string;
  revenue: number;
  ticket_count: number;
}

export interface FleetUtilization {
  total: number;
  active: number;
  maintenance: number;
  out_of_service: number;
  retired: number;
  active_trips: number;
}

export interface RouteMetric {
  route_id: string;
  route_label: string;
  ticket_count: number;
  revenue: number;
}

export interface VoidRateMetric {
  total_tickets: number;
  voided_tickets: number;
  void_rate: number;
}

export interface DepotMetric {
  depot_id: string;
  depot_name: string;
  revenue: number;
  tickets: number;
  active_agents: number;
  active_trips: number;
}

class MetricsService {
  private baseUrl = '/admin/metrics';

  async getOverview(from?: string, to?: string): Promise<DashboardOverview> {
    const params: Record<string, string> = {};
    if (from) params.from = from;
    if (to) params.to = to;
    
    const { data } = await axios.get(`${this.baseUrl}/overview`, { params });
    return data;
  }

  async getRevenueTimeseries(from?: string, to?: string): Promise<TimeSeriesData[]> {
    const params: Record<string, string> = {};
    if (from) params.from = from;
    if (to) params.to = to;
    
    const { data } = await axios.get(`${this.baseUrl}/revenue-timeseries`, { params });
    return data;
  }

  async getRevenueByCurrency(from?: string, to?: string): Promise<CurrencyBreakdown> {
    const params: Record<string, string> = {};
    if (from) params.from = from;
    if (to) params.to = to;
    
    const { data } = await axios.get(`${this.baseUrl}/revenue-by-currency`, { params });
    return data;
  }

  async getAgentPerformance(from?: string, to?: string, limit?: number): Promise<AgentMetric[]> {
    const params: Record<string, string> = {};
    if (from) params.from = from;
    if (to) params.to = to;
    if (limit) params.limit = limit.toString();
    
    const { data } = await axios.get(`${this.baseUrl}/agent-performance`, { params });
    return data;
  }

  async getFleetUtilization(): Promise<FleetUtilization> {
    const { data } = await axios.get(`${this.baseUrl}/fleet-utilization`);
    return data;
  }

  async getRoutePerformance(from?: string, to?: string, limit?: number): Promise<RouteMetric[]> {
    const params: Record<string, string> = {};
    if (from) params.from = from;
    if (to) params.to = to;
    if (limit) params.limit = limit.toString();
    
    const { data } = await axios.get(`${this.baseUrl}/route-performance`, { params });
    return data;
  }

  async getVoidRate(from?: string, to?: string): Promise<VoidRateMetric> {
    const params: Record<string, string> = {};
    if (from) params.from = from;
    if (to) params.to = to;
    
    const { data } = await axios.get(`${this.baseUrl}/void-rate`, { params });
    return data;
  }

  async getDepotComparison(): Promise<DepotMetric[]> {
    const { data } = await axios.get(`${this.baseUrl}/depot-comparison`);
    return data;
  }
}

export const metricsService = new MetricsService();

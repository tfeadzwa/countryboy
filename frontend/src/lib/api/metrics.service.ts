import axios from './axios';

export interface CurrencyBreakdown {
  usd: number;
  zwl: number;
  zar: number;
}

export interface ActiveTripSnapshot {
  id: string;
  origin: string;
  destination: string;
  route_label: string;
  agent_name: string | null;
  agent_code: string | null;
  fleet_number: string | null;
  fleet_registration_number: string | null;
  driver_name: string | null;
  started_at: string;
  started_offline: boolean;
  ticket_count: number;
  device_online: boolean;
}

export interface DashboardOverview {
  revenueToday: number;
  revenueTodayByCurrency: CurrencyBreakdown;
  ticketCountToday: number;
  activeTrips: number;
  activeAgents: number;
  devicesPaired: number;
  devicesOnline: number;
  devicesUnpaired: number;
  conductorsOnline: number;
  conductorsSignedIn: number;
  unprintedTickets: number;
  activeTripList: ActiveTripSnapshot[];
}

export interface TimeSeriesData {
  date: string;
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

  async getOverview(): Promise<DashboardOverview> {
    const { data } = await axios.get(`${this.baseUrl}/overview`);
    return {
      revenueToday: Number(data?.revenueToday ?? 0),
      revenueTodayByCurrency: {
        usd: Number(data?.revenueTodayByCurrency?.usd ?? 0),
        zwl: Number(data?.revenueTodayByCurrency?.zwl ?? 0),
        zar: Number(data?.revenueTodayByCurrency?.zar ?? 0),
      },
      ticketCountToday: Number(data?.ticketCountToday ?? 0),
      activeTrips: Number(data?.activeTrips ?? 0),
      activeAgents: Number(data?.activeAgents ?? 0),
      devicesPaired: Number(data?.devicesPaired ?? 0),
      devicesOnline: Number(data?.devicesOnline ?? 0),
      devicesUnpaired: Number(data?.devicesUnpaired ?? 0),
      conductorsOnline: Number(data?.conductorsOnline ?? 0),
      conductorsSignedIn: Number(data?.conductorsSignedIn ?? 0),
      unprintedTickets: Number(data?.unprintedTickets ?? 0),
      activeTripList: Array.isArray(data?.activeTripList) ? data.activeTripList : [],
    };
  }

  async getRevenueTimeseries(from?: string, to?: string): Promise<TimeSeriesData[]> {
    const params: Record<string, string> = {};
    if (from) params.from = from;
    if (to) params.to = to;

    const { data } = await axios.get(`${this.baseUrl}/revenue-timeseries`, { params });
    return Array.isArray(data) ? data : [];
  }

  async getRevenueByCurrency(from?: string, to?: string): Promise<CurrencyBreakdown> {
    const params: Record<string, string> = {};
    if (from) params.from = from;
    if (to) params.to = to;

    const { data } = await axios.get(`${this.baseUrl}/revenue-by-currency`, { params });
    return {
      usd: Number(data?.usd ?? 0),
      zwl: Number(data?.zwl ?? 0),
      zar: Number(data?.zar ?? 0),
    };
  }

  async getAgentPerformance(from?: string, to?: string, limit?: number): Promise<AgentMetric[]> {
    const params: Record<string, string> = {};
    if (from) params.from = from;
    if (to) params.to = to;
    if (limit) params.limit = limit.toString();

    const { data } = await axios.get(`${this.baseUrl}/agent-performance`, { params });
    return Array.isArray(data) ? data : [];
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
    return Array.isArray(data) ? data : [];
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
    return Array.isArray(data) ? data : [];
  }
}

export const metricsService = new MetricsService();

import { useState, useEffect } from "react";
import { motion } from "framer-motion";
import StatCard from "@/components/StatCard";
import { Ticket, DollarSign, Bus, Users, TrendingUp, ArrowUpRight, Clock, MapPin, CircleDot, Loader2, RefreshCw, Calendar } from "lucide-react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import ErrorAlert from "@/components/ErrorAlert";
import {
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip as RechartsTooltip,
  ResponsiveContainer, PieChart, Pie, Cell, AreaChart, Area,
} from "recharts";
import { 
  metricsService,
  type DashboardOverview, 
  type TimeSeriesData, 
  type CurrencyBreakdown 
} from "@/lib/api/metrics.service";
import { ticketService } from "@/lib/api/ticket.service";
import type { Ticket as TicketType } from "@/types";
import { 
  type AgentMetric, 
  type FleetUtilization, 
  type RouteMetric, 
  type VoidRateMetric 
} from "@/lib/api/metrics.service";

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: { staggerChildren: 0.06 },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 12 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.4, ease: [0.25, 0.46, 0.45, 0.94] as [number, number, number, number] } },
};

const CustomTooltip = ({ active, payload, label }: any) => {
  if (active && payload && payload.length) {
    return (
      <div className="bg-card border border-border rounded-lg px-3 py-2 shadow-lg">
        <p className="text-[11px] text-muted-foreground font-medium mb-1">{label}</p>
        {payload.map((entry: any, i: number) => (
          <p key={i} className="text-sm font-display font-bold text-foreground">
            ${entry.value.toLocaleString()}
          </p>
        ))}
      </div>
    );
  }
  return null;
};

const Dashboard = () => {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [overview, setOverview] = useState<DashboardOverview | null>(null);
  const [timeseries, setTimeseries] = useState<TimeSeriesData[]>([]);
  const [currency, setCurrency] = useState<CurrencyBreakdown | null>(null);
  const [recentTickets, setRecentTickets] = useState<TicketType[]>([]);
  const [agentPerformance, setAgentPerformance] = useState<AgentMetric[]>([]);
  const [fleetUtilization, setFleetUtilization] = useState<FleetUtilization | null>(null);
  const [routePerformance, setRoutePerformance] = useState<RouteMetric[]>([]);
  const [voidRate, setVoidRate] = useState<VoidRateMetric | null>(null);
  const [lastUpdated, setLastUpdated] = useState<Date>(new Date());
  
  // Date filters - default to last 7 days
  const [dateFrom, setDateFrom] = useState<string>(() => {
    const date = new Date();
    date.setDate(date.getDate() - 7);
    return date.toISOString().split('T')[0];
  });
  const [dateTo, setDateTo] = useState<string>(() => {
    return new Date().toISOString().split('T')[0];
  });

  const loadDashboardData = async () => {
    try {
      setLoading(true);
      setError(null);

      // Load all metrics in parallel
      const [
        overviewData, 
        timeseriesData, 
        currencyData, 
        ticketsData,
        agentsData,
        fleetData,
        routesData,
        voidData
      ] = await Promise.all([
        metricsService.getOverview(),
        metricsService.getRevenueTimeseries(dateFrom, dateTo),
        metricsService.getRevenueByCurrency(dateFrom, dateTo),
        ticketService.getAll(),
        metricsService.getAgentPerformance(dateFrom, dateTo, 5),
        metricsService.getFleetUtilization(),
        metricsService.getRoutePerformance(dateFrom, dateTo, 5),
        metricsService.getVoidRate(dateFrom, dateTo),
      ]);

      setOverview(overviewData);
      setTimeseries(timeseriesData);
      setCurrency(currencyData);
      setRecentTickets(ticketsData.slice(0, 5));
      setAgentPerformance(agentsData);
      setFleetUtilization(fleetData);
      setRoutePerformance(routesData);
      setVoidRate(voidData);
      setLastUpdated(new Date());
    } catch (err: any) {
      setError(err?.message || "Failed to load dashboard data");
      console.error("Dashboard load error:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadDashboardData();
  }, [dateFrom, dateTo]);

  // Calculate trends from timeseries
  const calculateTrends = () => {
    if (timeseries.length < 2) return { revenueTrend: 0, ticketTrend: 0 };
    
    const today = timeseries[timeseries.length - 1];
    const yesterday = timeseries[timeseries.length - 2];
    
    const todayRevenue = today.usd + today.zwl + today.zar;
    const yesterdayRevenue = yesterday.usd + yesterday.zwl + yesterday.zar;
    
    const revenueTrend = yesterdayRevenue > 0 
      ? Math.round(((todayRevenue - yesterdayRevenue) / yesterdayRevenue) * 100)
      : 0;
    
    // For ticket trend, we'll use overview data as approximation
    const ticketTrend = 0; // TODO: Calculate from timeseries if we track ticket counts per day
    
    return { revenueTrend, ticketTrend };
  };

  const { revenueTrend, ticketTrend } = calculateTrends();

  // Prepare currency data for pie chart
  const currencyData = currency ? [
    { name: "USD", value: currency.usd, color: "hsl(210, 20%, 28%)" },
    { name: "ZWL", value: currency.zwl, color: "hsl(160, 55%, 40%)" },
    { name: "ZAR", value: currency.zar, color: "hsl(205, 70%, 50%)" },
  ] : [];

  // Prepare chart data
  const chartData = timeseries.map(d => ({
    date: d.date.slice(5), // Show MM-DD
    usd: d.usd,
    zwl: d.zwl,
    zar: d.zar,
  }));

  // Prepare recent activity
  const recentActivity = recentTickets.map(t => ({
    id: t.id,
    serial: t.serial_number ?? "—",
    route: t.route_label || `${t.departure || "—"} → ${t.destination || "—"}`,
    amount: `${t.currency} ${t.amount}`,
    agent: t.agent_name || "—",
    time: new Date(t.issued_at).toLocaleTimeString("en", { hour: "2-digit", minute: "2-digit" }),
    isVoided: t.is_voided || false,
    category: t.ticket_category,
  }));

  const hour = new Date().getHours();
  const greeting = hour < 12 ? "Good morning" : hour < 17 ? "Good afternoon" : "Good evening";

  const setQuickFilter = (days: number) => {
    const to = new Date();
    const from = new Date();
    from.setDate(from.getDate() - days);
    setDateFrom(from.toISOString().split('T')[0]);
    setDateTo(to.toISOString().split('T')[0]);
  };

  if (loading && !overview) {
    return (
      <div className="flex items-center justify-center h-96">
        <div className="text-center">
          <Loader2 className="h-8 w-8 animate-spin text-primary mx-auto mb-2" />
          <p className="text-sm text-muted-foreground">Loading dashboard...</p>
        </div>
      </div>
    );
  }

  return (
    <motion.div
      variants={containerVariants}
      initial="hidden"
      animate="visible"
      className="space-y-6"
    >
      {error && <ErrorAlert error={error} />}

      {/* Header with Date Filter */}
      <motion.div variants={itemVariants} className="flex flex-col lg:flex-row lg:items-end lg:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-display font-bold text-foreground tracking-tight">
            {greeting} 👋
          </h1>
          <p className="text-sm text-muted-foreground mt-0.5">
            Here's what's happening across your operations.
          </p>
        </div>
        <div className="flex flex-col sm:flex-row items-start sm:items-center gap-2">
          <div className="flex items-center gap-2 text-[11px] text-muted-foreground font-medium">
            <Clock className="h-3.5 w-3.5" />
            Updated {lastUpdated.toLocaleTimeString("en", { hour: "2-digit", minute: "2-digit" })}
          </div>
          <div className="flex items-center gap-2">
            <Button
              onClick={() => setQuickFilter(1)}
              variant={dateFrom === new Date(Date.now() - 86400000).toISOString().split('T')[0] ? "default" : "outline"}
              size="sm"
              className="h-8 text-xs"
            >
              Today
            </Button>
            <Button
              onClick={() => setQuickFilter(7)}
              variant="outline"
              size="sm"
              className="h-8 text-xs"
            >
              7 Days
            </Button>
            <Button
              onClick={() => setQuickFilter(30)}
              variant="outline"
              size="sm"
              className="h-8 text-xs"
            >
              30 Days
            </Button>
          </div>
          <div className="flex items-center gap-2">
            <Input
              type="date"
              value={dateFrom}
              onChange={(e) => setDateFrom(e.target.value)}
              className="h-8 text-xs w-36"
            />
            <span className="text-xs text-muted-foreground">to</span>
            <Input
              type="date"
              value={dateTo}
              onChange={(e) => setDateTo(e.target.value)}
              className="h-8 text-xs w-36"
            />
            <Button
              onClick={loadDashboardData}
              variant="outline"
              size="sm"
              className="h-8"
              disabled={loading}
            >
              {loading ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <RefreshCw className="h-3.5 w-3.5" />}
            </Button>
          </div>
        </div>
      </motion.div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard
          label="Today's Revenue"
          value={currency ? `$${currency.usd.toLocaleString()}` : "$0"}
          icon={DollarSign}
          variant="blue"
          subtitle={currency ? `ZWL ${currency.zwl.toLocaleString()} · ZAR ${currency.zar.toLocaleString()}` : "—"}
          trend={revenueTrend !== 0 ? { value: revenueTrend, label: "vs yesterday" } : undefined}
        />
        <StatCard
          label="Tickets Sold"
          value={overview?.ticketCountToday || 0}
          icon={Ticket}
          variant="teal"
          trend={ticketTrend !== 0 ? { value: ticketTrend, label: "vs yesterday" } : undefined}
        />
        <StatCard 
          label="Active Trips" 
          value={overview?.activeTrips || 0} 
          icon={Bus} 
          variant="amber" 
        />
        <StatCard 
          label="Active Agents" 
          value={overview?.activeAgents || 0} 
          icon={Users} 
          variant="green" 
        />
      </div>

      {/* Charts Row */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
        {/* Revenue Chart */}
        <motion.div variants={itemVariants} className="lg:col-span-2">
          <Card className="shadow-sm border-border/60">
            <CardHeader className="pb-2">
              <div className="flex items-center justify-between">
                <CardTitle className="text-sm font-display font-semibold flex items-center gap-2 text-foreground">
                  <div className="h-7 w-7 rounded-lg bg-secondary/10 flex items-center justify-center">
                    <TrendingUp className="h-3.5 w-3.5 text-secondary" />
                  </div>
                  Revenue Overview
                </CardTitle>
                <Badge variant="outline" className="text-[10px] font-medium text-muted-foreground">
                  {timeseries.length} days
                </Badge>
              </div>
            </CardHeader>
            <CardContent className="pt-2">
              {chartData.length > 0 ? (
                <ResponsiveContainer width="100%" height={260}>
                  <AreaChart data={chartData}>
                    <defs>
                      <linearGradient id="revenueGradient" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stopColor="hsl(210, 20%, 28%)" stopOpacity={0.15} />
                        <stop offset="100%" stopColor="hsl(210, 20%, 28%)" stopOpacity={0} />
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" stroke="hsl(0 0% 88%)" vertical={false} />
                    <XAxis dataKey="date" tick={{ fontSize: 11, fill: "hsl(0 0% 40%)" }} axisLine={false} tickLine={false} />
                    <YAxis tick={{ fontSize: 11, fill: "hsl(0 0% 40%)" }} axisLine={false} tickLine={false} tickFormatter={v => `$${v}`} />
                    <RechartsTooltip content={<CustomTooltip />} />
                    <Area
                      type="monotone"
                      dataKey="usd"
                      stroke="hsl(210, 20%, 28%)"
                      strokeWidth={2.5}
                      fill="url(#revenueGradient)"
                      dot={{ r: 4, fill: "hsl(210, 20%, 28%)", strokeWidth: 2, stroke: "hsl(0, 0%, 100%)" }}
                      activeDot={{ r: 6, fill: "hsl(210, 20%, 28%)", strokeWidth: 2, stroke: "hsl(0, 0%, 100%)" }}
                    />
                  </AreaChart>
                </ResponsiveContainer>
              ) : (
                <div className="h-[260px] flex items-center justify-center text-sm text-muted-foreground">
                  No revenue data available
                </div>
              )}
            </CardContent>
          </Card>
        </motion.div>

        {/* Currency Breakdown */}
        <motion.div variants={itemVariants}>
          <Card className="shadow-sm border-border/60 h-full">
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-display font-semibold flex items-center gap-2 text-foreground">
                <div className="h-7 w-7 rounded-lg bg-primary/10 flex items-center justify-center">
                  <CircleDot className="h-3.5 w-3.5 text-primary" />
                </div>
                Currency Split
              </CardTitle>
            </CardHeader>
            <CardContent className="flex flex-col items-center pt-0">
              {currencyData.length > 0 && currencyData.some(c => c.value > 0) ? (
                <>
                  <ResponsiveContainer width="100%" height={160}>
                    <PieChart>
                      <Pie
                        data={currencyData}
                        cx="50%"
                        cy="50%"
                        innerRadius={45}
                        outerRadius={70}
                        paddingAngle={3}
                        dataKey="value"
                        strokeWidth={0}
                      >
                        {currencyData.map((entry, i) => (
                          <Cell key={i} fill={entry.color} />
                        ))}
                      </Pie>
                    </PieChart>
                  </ResponsiveContainer>
                  <div className="w-full space-y-2.5 mt-2">
                    {currencyData.map((c) => (
                      <div key={c.name} className="flex items-center justify-between text-sm">
                        <div className="flex items-center gap-2">
                          <div className="h-2.5 w-2.5 rounded-full" style={{ backgroundColor: c.color }} />
                          <span className="text-xs font-medium text-muted-foreground">{c.name}</span>
                        </div>
                        <span className="text-xs font-display font-bold text-foreground">{c.value.toLocaleString()}</span>
                      </div>
                    ))}
                  </div>
                </>
              ) : (
                <div className="h-full flex items-center justify-center text-sm text-muted-foreground py-8">
                  No currency data available
                </div>
              )}
            </CardContent>
          </Card>
        </motion.div>
      </div>

      {/* Recent Tickets */}
      <motion.div variants={itemVariants}>
        <Card className="shadow-sm border-border/60">
          <CardHeader className="pb-3">
            <div className="flex items-center justify-between">
              <CardTitle className="text-sm font-display font-semibold flex items-center gap-2 text-foreground">
                <div className="h-7 w-7 rounded-lg bg-accent/10 flex items-center justify-center">
                  <Ticket className="h-3.5 w-3.5 text-accent" />
                </div>
                Recent Tickets
                {voidRate && voidRate.total_tickets > 0 && (
                  <Badge
                    variant={voidRate.void_rate > 10 ? "destructive" : voidRate.void_rate > 5 ? "secondary" : "outline"}
                    className="ml-2 text-[9px] px-2 py-0 h-4"
                  >
                    {voidRate.void_rate}% void rate
                  </Badge>
                )}
              </CardTitle>
              <button className="text-[11px] font-medium text-accent hover:text-accent/80 transition-colors flex items-center gap-0.5">
                View all <ArrowUpRight className="h-3 w-3" />
              </button>
            </div>
          </CardHeader>
          <CardContent className="p-0">
            {recentActivity.length > 0 ? (
              <div className="divide-y divide-border/50">
                {recentActivity.map((item) => (
                  <div key={item.id} className="flex items-center gap-4 px-6 py-3 hover:bg-muted/30 transition-colors">
                    <div className={`h-8 w-8 rounded-lg flex items-center justify-center shrink-0 ${
                      item.isVoided ? "bg-destructive/10" : item.category === "LUGGAGE" ? "bg-warning/10" : "bg-primary/10"
                    }`}>
                      {item.category === "LUGGAGE" ? (
                        <MapPin className={`h-3.5 w-3.5 ${item.isVoided ? "text-destructive" : "text-warning"}`} />
                      ) : (
                        <Ticket className={`h-3.5 w-3.5 ${item.isVoided ? "text-destructive" : "text-primary"}`} />
                      )}
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2">
                        <p className="text-xs font-medium text-foreground truncate">{item.route}</p>
                        {item.isVoided && (
                          <Badge variant="destructive" className="text-[9px] px-1.5 py-0 h-4">VOID</Badge>
                        )}
                      </div>
                      <p className="text-[11px] text-muted-foreground">{item.agent} · {item.serial}</p>
                    </div>
                    <div className="text-right shrink-0">
                      <p className={`text-xs font-display font-bold ${item.isVoided ? "text-destructive line-through" : "text-foreground"}`}>
                        {item.amount}
                      </p>
                      <p className="text-[10px] text-muted-foreground">{item.time}</p>
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="px-6 py-12 text-center text-sm text-muted-foreground">
                No recent tickets found
              </div>
            )}
          </CardContent>
        </Card>
      </motion.div>

      {/* Agent Performance & Fleet/Route Sections */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">
        {/* Top Agents */}
        <motion.div variants={itemVariants}>
          <Card className="shadow-sm border-border/60 h-full">
            <CardHeader className="pb-3">
              <CardTitle className="text-sm font-display font-semibold flex items-center gap-2 text-foreground">
                <div className="h-7 w-7 rounded-lg bg-success/10 flex items-center justify-center">
                  <Users className="h-3.5 w-3.5 text-success" />
                </div>
                Top Agents
              </CardTitle>
            </CardHeader>
            <CardContent className="p-0">
              {agentPerformance.length > 0 ? (
                <div className="divide-y divide-border/50">
                  {agentPerformance.map((agent, idx) => (
                    <div key={agent.agent_id} className="flex items-center gap-3 px-6 py-3 hover:bg-muted/30 transition-colors">
                      <div className="h-6 w-6 rounded-full bg-primary/10 flex items-center justify-center shrink-0">
                        <span className="text-[10px] font-bold text-primary">#{idx + 1}</span>
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-xs font-medium text-foreground truncate">{agent.agent_name}</p>
                        <p className="text-[10px] text-muted-foreground">{agent.ticket_count} tickets</p>
                      </div>
                      <p className="text-xs font-display font-bold text-foreground shrink-0">
                        ${agent.revenue.toLocaleString()}
                      </p>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="px-6 py-12 text-center text-sm text-muted-foreground">
                  No agent data available
                </div>
              )}
            </CardContent>
          </Card>
        </motion.div>

        {/* Fleet Utilization */}
        <motion.div variants={itemVariants}>
          <Card className="shadow-sm border-border/60 h-full">
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-display font-semibold flex items-center gap-2 text-foreground">
                <div className="h-7 w-7 rounded-lg bg-amber/10 flex items-center justify-center">
                  <Bus className="h-3.5 w-3.5 text-amber" />
                </div>
                Fleet Status
              </CardTitle>
            </CardHeader>
            <CardContent>
              {fleetUtilization ? (
                <div className="space-y-3">
                  <div className="grid grid-cols-2 gap-3">
                    <div className="p-3 rounded-lg bg-success/10 border border-success/20">
                      <p className="text-lg font-display font-bold text-foreground">{fleetUtilization.active}</p>
                      <p className="text-[10px] text-muted-foreground">Active</p>
                    </div>
                    <div className="p-3 rounded-lg bg-amber/10 border border-amber/20">
                      <p className="text-lg font-display font-bold text-foreground">{fleetUtilization.maintenance}</p>
                      <p className="text-[10px] text-muted-foreground">Maintenance</p>
                    </div>
                    <div className="p-3 rounded-lg bg-destructive/10 border border-destructive/20">
                      <p className="text-lg font-display font-bold text-foreground">{fleetUtilization.out_of_service}</p>
                      <p className="text-[10px] text-muted-foreground">Out of Service</p>
                    </div>
                    <div className="p-3 rounded-lg bg-muted border border-border">
                      <p className="text-lg font-display font-bold text-foreground">{fleetUtilization.retired}</p>
                      <p className="text-[10px] text-muted-foreground">Retired</p>
                    </div>
                  </div>
                  <div className="pt-2 border-t border-border/50">
                    <p className="text-xs text-muted-foreground">
                      {fleetUtilization.active_trips} of {fleetUtilization.total} fleets currently on trips
                    </p>
                  </div>
                </div>
              ) : (
                <div className="py-8 text-center text-sm text-muted-foreground">
                  No fleet data available
                </div>
              )}
            </CardContent>
          </Card>
        </motion.div>

        {/* Top Routes */}
        <motion.div variants={itemVariants}>
          <Card className="shadow-sm border-border/60 h-full">
            <CardHeader className="pb-3">
              <CardTitle className="text-sm font-display font-semibold flex items-center gap-2 text-foreground">
                <div className="h-7 w-7 rounded-lg bg-primary/10 flex items-center justify-center">
                  <MapPin className="h-3.5 w-3.5 text-primary" />
                </div>
                Top Routes
              </CardTitle>
            </CardHeader>
            <CardContent className="p-0">
              {routePerformance.length > 0 ? (
                <div className="divide-y divide-border/50">
                  {routePerformance.map((route, idx) => (
                    <div key={route.route_id} className="flex items-center gap-3 px-6 py-3 hover:bg-muted/30 transition-colors">
                      <div className="h-6 w-6 rounded-full bg-primary/10 flex items-center justify-center shrink-0">
                        <span className="text-[10px] font-bold text-primary">#{idx + 1}</span>
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-xs font-medium text-foreground truncate">{route.route_label}</p>
                        <p className="text-[10px] text-muted-foreground">{route.ticket_count} tickets</p>
                      </div>
                      <p className="text-xs font-display font-bold text-foreground shrink-0">
                        ${route.revenue.toLocaleString()}
                      </p>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="px-6 py-12 text-center text-sm text-muted-foreground">
                  No route data available
                </div>
              )}
            </CardContent>
          </Card>
        </motion.div>
      </div>
    </motion.div>
  );
};

export default Dashboard;

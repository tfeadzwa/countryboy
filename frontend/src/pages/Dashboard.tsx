import { useCallback, useEffect, useMemo, useState, type ReactNode } from "react";
import { Link } from "react-router-dom";
import { motion } from "framer-motion";
import { format, formatDistanceToNowStrict, parseISO } from "date-fns";
import {
  ArrowUpRight,
  Bus,
  Clock,
  Loader2,
  MapPin,
  Printer,
  RefreshCw,
  Smartphone,
  Ticket,
  TrendingUp,
  UserRound,
  Users,
  Wallet,
} from "lucide-react";
import {
  Area,
  AreaChart,
  CartesianGrid,
  Cell,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip as RechartsTooltip,
  XAxis,
  YAxis,
} from "recharts";
import StatCard from "@/components/StatCard";
import ErrorAlert from "@/components/ErrorAlert";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { useAuth } from "@/contexts/AuthContext";
import { isSuperAdmin } from "@/lib/permissions";
import {
  metricsService,
  type ActiveTripSnapshot,
  type AgentMetric,
  type CurrencyBreakdown,
  type DashboardOverview,
  type DepotMetric,
  type FleetUtilization,
  type RouteMetric,
  type TimeSeriesData,
  type VoidRateMetric,
} from "@/lib/api/metrics.service";
import { ticketService } from "@/lib/api/ticket.service";
import type { Ticket as TicketType } from "@/types";

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: { staggerChildren: 0.05 },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 10 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.35, ease: [0.25, 0.46, 0.45, 0.94] as [number, number, number, number] },
  },
};

const CURRENCY_COLORS = {
  usd: "hsl(220, 15%, 28%)",
  zwl: "hsl(142, 55%, 38%)",
  zar: "hsl(38, 82%, 50%)",
};

const todayIso = () => new Date().toISOString().split("T")[0];

const daysAgoIso = (days: number) => {
  const d = new Date();
  d.setDate(d.getDate() - (days - 1));
  return d.toISOString().split("T")[0];
};

const formatMoney = (currency: string, amount: number) =>
  `${currency} ${amount.toLocaleString(undefined, {
    minimumFractionDigits: 0,
    maximumFractionDigits: 2,
  })}`;

const categoryLabel = (category: string) => {
  switch (category) {
    case "PASSENGER":
      return "Passenger";
    case "LUGGAGE":
      return "Luggage";
    case "PASSENGER_WITH_LUGGAGE":
      return "Pax + bag";
    default:
      return category.replace(/_/g, " ");
  }
};

const SectionTitle = ({
  icon: Icon,
  title,
  action,
  tone = "primary",
}: {
  icon: typeof Ticket;
  title: string;
  action?: ReactNode;
  tone?: "primary" | "accent" | "success" | "secondary";
}) => {
  const tones = {
    primary: "bg-primary/10 text-primary",
    accent: "bg-accent/15 text-accent-foreground",
    success: "bg-success/10 text-success",
    secondary: "bg-secondary/10 text-secondary",
  };
  return (
    <div className="flex items-center justify-between gap-3">
      <CardTitle className="text-sm font-display font-semibold flex items-center gap-2 text-foreground">
        <div className={`h-7 w-7 rounded-lg flex items-center justify-center ${tones[tone]}`}>
          <Icon className="h-3.5 w-3.5" />
        </div>
        {title}
      </CardTitle>
      {action}
    </div>
  );
};

const OpsPill = ({
  label,
  value,
  hint,
  tone = "default",
  to,
}: {
  label: string;
  value: number | string;
  hint?: string;
  tone?: "default" | "live" | "warn" | "muted";
  to?: string;
}) => {
  const tones = {
    default: "border-border/70 bg-card",
    live: "border-emerald-500/25 bg-emerald-500/[0.06]",
    warn: "border-amber-500/30 bg-amber-500/[0.08]",
    muted: "border-border/60 bg-muted/40",
  };
  const body = (
    <div className={`rounded-xl border px-4 py-3 ${tones[tone]} transition-colors ${to ? "hover:border-primary/40" : ""}`}>
      <p className="text-[10px] font-semibold uppercase tracking-wider text-muted-foreground">{label}</p>
      <p className="mt-1 text-2xl font-display font-bold tracking-tight text-foreground">{value}</p>
      {hint && <p className="mt-1 text-[11px] text-muted-foreground">{hint}</p>}
    </div>
  );
  return to ? <Link to={to}>{body}</Link> : body;
};

const RevenueTooltip = ({ active, payload, label }: any) => {
  if (!active || !payload?.length) return null;
  return (
    <div className="rounded-lg border border-border bg-card px-3 py-2 shadow-lg">
      <p className="mb-1.5 text-[11px] font-medium text-muted-foreground">{label}</p>
      {payload.map((entry: any) => (
        <p key={entry.dataKey} className="text-xs font-semibold text-foreground">
          <span className="inline-block w-8 uppercase text-muted-foreground">{entry.dataKey}</span>
          {Number(entry.value).toLocaleString()}
        </p>
      ))}
    </div>
  );
};

const Dashboard = () => {
  const { user } = useAuth();
  const userIsSuperAdmin = user ? isSuperAdmin(user.roles || []) : false;

  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [overview, setOverview] = useState<DashboardOverview | null>(null);
  const [timeseries, setTimeseries] = useState<TimeSeriesData[]>([]);
  const [currency, setCurrency] = useState<CurrencyBreakdown | null>(null);
  const [recentTickets, setRecentTickets] = useState<TicketType[]>([]);
  const [agentPerformance, setAgentPerformance] = useState<AgentMetric[]>([]);
  const [fleetUtilization, setFleetUtilization] = useState<FleetUtilization | null>(null);
  const [routePerformance, setRoutePerformance] = useState<RouteMetric[]>([]);
  const [voidRate, setVoidRate] = useState<VoidRateMetric | null>(null);
  const [depotComparison, setDepotComparison] = useState<DepotMetric[]>([]);
  const [lastUpdated, setLastUpdated] = useState<Date>(new Date());

  const [dateFrom, setDateFrom] = useState(daysAgoIso(7));
  const [dateTo, setDateTo] = useState(todayIso());
  const [preset, setPreset] = useState<"1" | "7" | "30" | "custom">("7");

  const loadDashboardData = useCallback(async (opts?: { soft?: boolean }) => {
    try {
      if (opts?.soft) setRefreshing(true);
      else setLoading(true);
      setError(null);

      const [
        overviewData,
        timeseriesData,
        currencyData,
        ticketsData,
        agentsData,
        fleetData,
        routesData,
        voidData,
        depotsData,
      ] = await Promise.all([
        metricsService.getOverview(),
        metricsService.getRevenueTimeseries(dateFrom, dateTo),
        metricsService.getRevenueByCurrency(dateFrom, dateTo),
        ticketService.getAll(),
        metricsService.getAgentPerformance(dateFrom, dateTo, 5),
        metricsService.getFleetUtilization(),
        metricsService.getRoutePerformance(dateFrom, dateTo, 5),
        metricsService.getVoidRate(dateFrom, dateTo),
        userIsSuperAdmin ? metricsService.getDepotComparison() : Promise.resolve([] as DepotMetric[]),
      ]);

      setOverview(overviewData);
      setTimeseries(Array.isArray(timeseriesData) ? timeseriesData : []);
      setCurrency(currencyData);
      setRecentTickets(Array.isArray(ticketsData) ? ticketsData.slice(0, 6) : []);
      setAgentPerformance(Array.isArray(agentsData) ? agentsData : []);
      setFleetUtilization(fleetData ?? null);
      setRoutePerformance(Array.isArray(routesData) ? routesData : []);
      setVoidRate(voidData ?? null);
      setDepotComparison(Array.isArray(depotsData) ? depotsData : []);
      setLastUpdated(new Date());
    } catch (err: any) {
      setError(err?.message || "Failed to load dashboard data");
      console.error("Dashboard load error:", err);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, [dateFrom, dateTo, userIsSuperAdmin]);

  useEffect(() => {
    loadDashboardData();
  }, [loadDashboardData]);

  const setQuickFilter = (days: 1 | 7 | 30) => {
    setPreset(String(days) as "1" | "7" | "30");
    setDateFrom(daysAgoIso(days));
    setDateTo(todayIso());
  };

  const periodLabel = useMemo(() => {
    if (preset === "1") return "Today";
    if (preset === "7") return "Last 7 days";
    if (preset === "30") return "Last 30 days";
    return `${dateFrom} → ${dateTo}`;
  }, [preset, dateFrom, dateTo]);

  const chartData = timeseries.map((d) => ({
    date: d.date.slice(5),
    usd: d.usd,
    zwl: d.zwl,
    zar: d.zar,
  }));

  const currencyPie = currency
    ? [
        { name: "USD", value: currency.usd, color: CURRENCY_COLORS.usd },
        { name: "ZWL", value: currency.zwl, color: CURRENCY_COLORS.zwl },
        { name: "ZAR", value: currency.zar, color: CURRENCY_COLORS.zar },
      ].filter((c) => c.value > 0)
    : [];

  const revenueTrend = useMemo(() => {
    if (timeseries.length < 2) return 0;
    const last = timeseries[timeseries.length - 1];
    const prev = timeseries[timeseries.length - 2];
    const a = last.usd + last.zwl + last.zar;
    const b = prev.usd + prev.zwl + prev.zar;
    if (b <= 0) return 0;
    return Math.round(((a - b) / b) * 100);
  }, [timeseries]);

  if (loading && !overview) {
    return (
      <div className="flex h-96 items-center justify-center">
        <div className="text-center">
          <Loader2 className="mx-auto mb-2 h-8 w-8 animate-spin text-primary" />
          <p className="text-sm text-muted-foreground">Loading operations…</p>
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

      {/* Header */}
      <motion.div
        variants={itemVariants}
        className="flex flex-col gap-4 xl:flex-row xl:items-center xl:justify-between"
      >
        <div className="min-w-0">
          <p className="text-[11px] font-semibold uppercase tracking-[0.14em] text-muted-foreground">
            Operations
          </p>
          <h1 className="mt-1 font-display text-2xl font-bold tracking-tight text-foreground">
            Dashboard
          </h1>
          <p className="mt-0.5 text-sm text-muted-foreground">
            Live trips, devices, and period performance across the depot.
          </p>
          <p className="mt-1.5 inline-flex items-center gap-1.5 text-[11px] text-muted-foreground">
            <Clock className="h-3.5 w-3.5" />
            Updated {format(lastUpdated, "HH:mm:ss")}
          </p>
        </div>

        <div className="flex w-full flex-wrap items-center gap-2 xl:w-auto xl:justify-end xl:pl-6">
          <div className="flex items-center gap-1.5">
            {([1, 7, 30] as const).map((days) => (
              <Button
                key={days}
                type="button"
                size="sm"
                variant={preset === String(days) ? "default" : "outline"}
                className="h-8 text-xs"
                onClick={() => setQuickFilter(days)}
              >
                {days === 1 ? "Today" : `${days}d`}
              </Button>
            ))}
          </div>
          <div className="flex flex-1 items-center gap-2 sm:flex-initial xl:ml-1">
            <Input
              type="date"
              value={dateFrom}
              onChange={(e) => {
                setPreset("custom");
                setDateFrom(e.target.value);
              }}
              className="h-8 min-w-0 flex-1 text-xs sm:w-[9.5rem] sm:flex-none"
            />
            <span className="shrink-0 text-xs text-muted-foreground">to</span>
            <Input
              type="date"
              value={dateTo}
              onChange={(e) => {
                setPreset("custom");
                setDateTo(e.target.value);
              }}
              className="h-8 min-w-0 flex-1 text-xs sm:w-[9.5rem] sm:flex-none"
            />
            <Button
              type="button"
              variant="outline"
              size="sm"
              className="h-8 shrink-0"
              disabled={loading || refreshing}
              onClick={() => loadDashboardData({ soft: true })}
            >
              {refreshing ? (
                <Loader2 className="h-3.5 w-3.5 animate-spin" />
              ) : (
                <RefreshCw className="h-3.5 w-3.5" />
              )}
            </Button>
          </div>
        </div>
      </motion.div>

      {/* Live ops */}
      <motion.div variants={itemVariants}>
        <div className="mb-3 flex items-center justify-between">
          <h2 className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
            Right now
          </h2>
          <Badge variant="outline" className="text-[10px] font-medium">
            Live
          </Badge>
        </div>
        <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
          <OpsPill
            label="Active trips"
            value={overview?.activeTrips ?? 0}
            hint="Corridors in progress"
            tone="live"
            to="/trips"
          />
          <OpsPill
            label="Conductors online"
            value={overview?.conductorsOnline ?? 0}
            hint={`${overview?.conductorsSignedIn ?? 0} signed in`}
            tone={(overview?.conductorsOnline ?? 0) > 0 ? "live" : "muted"}
            to="/agents"
          />
          <OpsPill
            label="Devices online"
            value={overview?.devicesOnline ?? 0}
            hint={`${overview?.devicesPaired ?? 0} paired · ${overview?.devicesUnpaired ?? 0} unpaired`}
            tone={(overview?.devicesOnline ?? 0) > 0 ? "live" : "muted"}
            to="/devices"
          />
          <OpsPill
            label="Unprinted tickets"
            value={overview?.unprintedTickets ?? 0}
            hint="Awaiting thermal print"
            tone={(overview?.unprintedTickets ?? 0) > 0 ? "warn" : "default"}
            to="/tickets"
          />
        </div>
      </motion.div>

      {/* Period stats */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          label={`${periodLabel} · USD`}
          value={currency ? formatMoney("USD", currency.usd) : "USD 0"}
          icon={Wallet}
          variant="blue"
          subtitle={currency ? `ZWL ${currency.zwl.toLocaleString()} · ZAR ${currency.zar.toLocaleString()}` : "—"}
          trend={revenueTrend !== 0 ? { value: revenueTrend, label: "vs prior day" } : undefined}
        />
        <StatCard
          label="Tickets today"
          value={overview?.ticketCountToday ?? 0}
          icon={Ticket}
          variant="teal"
          subtitle={
            voidRate
              ? `${voidRate.voided_tickets} voided in period · ${voidRate.void_rate}%`
              : undefined
          }
        />
        <StatCard
          label="Active conductors"
          value={overview?.activeAgents ?? 0}
          icon={Users}
          variant="green"
          subtitle={`${overview?.conductorsOnline ?? 0} online now`}
        />
        <StatCard
          label="Fleets on trips"
          value={fleetUtilization?.active_trips ?? overview?.activeTrips ?? 0}
          icon={Bus}
          variant="amber"
          subtitle={
            fleetUtilization
              ? `${fleetUtilization.active} active · ${fleetUtilization.maintenance} maintenance`
              : undefined
          }
        />
      </div>

      {/* Active trips + today's revenue */}
      <div className="grid grid-cols-1 gap-5 lg:grid-cols-5">
        <motion.div variants={itemVariants} className="lg:col-span-3">
          <Card className="h-full border-border/60 shadow-sm">
            <CardHeader className="pb-3">
              <SectionTitle
                icon={Bus}
                title="Active trips"
                tone="accent"
                action={
                  <Link
                    to="/trips"
                    className="inline-flex items-center gap-0.5 text-[11px] font-medium text-primary hover:text-primary/80"
                  >
                    View trips <ArrowUpRight className="h-3 w-3" />
                  </Link>
                }
              />
            </CardHeader>
            <CardContent className="p-0">
              {(overview?.activeTripList?.length ?? 0) > 0 ? (
                <div className="divide-y divide-border/50">
                  {overview!.activeTripList.map((trip: ActiveTripSnapshot) => (
                    <Link
                      key={trip.id}
                      to={`/trips/${trip.id}`}
                      className="flex items-start gap-3 px-6 py-3.5 transition-colors hover:bg-muted/30"
                    >
                      <div className="mt-0.5 flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-amber-500/10">
                        <MapPin className="h-4 w-4 text-amber-700" />
                      </div>
                      <div className="min-w-0 flex-1">
                        <div className="flex flex-wrap items-center gap-2">
                          <p className="truncate text-sm font-semibold text-foreground">
                            {trip.route_label}
                          </p>
                          <span
                            className={`inline-flex rounded-full px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide ring-1 ring-inset ${
                              trip.device_online
                                ? "bg-emerald-500/10 text-emerald-700 ring-emerald-500/20"
                                : "bg-slate-500/10 text-slate-600 ring-slate-500/15"
                            }`}
                          >
                            {trip.device_online ? "Device online" : "Device offline"}
                          </span>
                          {trip.started_offline && (
                            <span className="inline-flex rounded-full bg-amber-500/15 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-amber-800 ring-1 ring-inset ring-amber-500/30">
                              Offline start
                            </span>
                          )}
                        </div>
                        <p className="mt-0.5 truncate text-[11px] text-muted-foreground">
                          {trip.agent_name || "—"}
                          {trip.agent_code ? ` · ${trip.agent_code}` : ""}
                          {trip.fleet_number ? ` · Fleet ${trip.fleet_number}` : ""}
                          {trip.driver_name ? ` · ${trip.driver_name}` : ""}
                        </p>
                      </div>
                      <div className="shrink-0 text-right">
                        <p className="text-xs font-display font-bold text-foreground">
                          {trip.ticket_count} tix
                        </p>
                        <p className="text-[10px] text-muted-foreground">
                          {formatDistanceToNowStrict(parseISO(trip.started_at), { addSuffix: true })}
                        </p>
                      </div>
                    </Link>
                  ))}
                </div>
              ) : (
                <div className="px-6 py-14 text-center">
                  <Bus className="mx-auto mb-2 h-8 w-8 text-muted-foreground/40" />
                  <p className="text-sm text-muted-foreground">No trips running right now</p>
                </div>
              )}
            </CardContent>
          </Card>
        </motion.div>

        <motion.div variants={itemVariants} className="lg:col-span-2">
          <Card className="relative h-full overflow-hidden border-border/60 shadow-sm">
            <div className="pointer-events-none absolute inset-x-0 top-0 h-28 bg-gradient-to-b from-primary/[0.07] to-transparent" />
            <CardHeader className="relative pb-2">
              <SectionTitle icon={Wallet} title="Today’s takings" tone="primary" />
            </CardHeader>
            <CardContent className="relative space-y-4">
              <div>
                <p className="text-[11px] font-medium uppercase tracking-wider text-muted-foreground">
                  Valid tickets issued today
                </p>
                <p className="mt-1 font-display text-3xl font-bold tracking-tight text-foreground">
                  {overview?.ticketCountToday ?? 0}
                </p>
              </div>
              <div className="space-y-2.5 rounded-xl border border-border/60 bg-muted/20 p-3.5">
                {(
                  [
                    ["USD", overview?.revenueTodayByCurrency?.usd ?? 0],
                    ["ZWL", overview?.revenueTodayByCurrency?.zwl ?? 0],
                    ["ZAR", overview?.revenueTodayByCurrency?.zar ?? 0],
                  ] as const
                ).map(([code, amount]) => (
                  <div key={code} className="flex items-center justify-between text-sm">
                    <span className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">
                      {code}
                    </span>
                    <span className="font-display text-sm font-bold text-foreground">
                      {amount.toLocaleString(undefined, {
                        minimumFractionDigits: 2,
                        maximumFractionDigits: 2,
                      })}
                    </span>
                  </div>
                ))}
              </div>
              <p className="text-[11px] text-muted-foreground">
                Period filter applies to charts and rankings below — live counts stay today.
              </p>
            </CardContent>
          </Card>
        </motion.div>
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 gap-5 lg:grid-cols-3">
        <motion.div variants={itemVariants} className="lg:col-span-2">
          <Card className="border-border/60 shadow-sm">
            <CardHeader className="pb-2">
              <div className="flex items-center justify-between gap-2">
                <SectionTitle icon={TrendingUp} title="Revenue over time" tone="secondary" />
                <Badge variant="outline" className="text-[10px] font-medium text-muted-foreground">
                  {periodLabel}
                </Badge>
              </div>
              <div className="mt-2 flex flex-wrap gap-3 text-[10px] font-medium uppercase tracking-wide text-muted-foreground">
                <span className="inline-flex items-center gap-1.5">
                  <span className="h-2 w-2 rounded-full" style={{ background: CURRENCY_COLORS.usd }} />
                  USD
                </span>
                <span className="inline-flex items-center gap-1.5">
                  <span className="h-2 w-2 rounded-full" style={{ background: CURRENCY_COLORS.zwl }} />
                  ZWL
                </span>
                <span className="inline-flex items-center gap-1.5">
                  <span className="h-2 w-2 rounded-full" style={{ background: CURRENCY_COLORS.zar }} />
                  ZAR
                </span>
              </div>
            </CardHeader>
            <CardContent className="pt-2">
              {chartData.length > 0 ? (
                <ResponsiveContainer width="100%" height={260}>
                  <AreaChart data={chartData}>
                    <defs>
                      <linearGradient id="usdFill" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stopColor={CURRENCY_COLORS.usd} stopOpacity={0.18} />
                        <stop offset="100%" stopColor={CURRENCY_COLORS.usd} stopOpacity={0} />
                      </linearGradient>
                      <linearGradient id="zwlFill" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stopColor={CURRENCY_COLORS.zwl} stopOpacity={0.14} />
                        <stop offset="100%" stopColor={CURRENCY_COLORS.zwl} stopOpacity={0} />
                      </linearGradient>
                      <linearGradient id="zarFill" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stopColor={CURRENCY_COLORS.zar} stopOpacity={0.16} />
                        <stop offset="100%" stopColor={CURRENCY_COLORS.zar} stopOpacity={0} />
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" stroke="hsl(30 12% 87%)" vertical={false} />
                    <XAxis
                      dataKey="date"
                      tick={{ fontSize: 11, fill: "hsl(220 10% 44%)" }}
                      axisLine={false}
                      tickLine={false}
                    />
                    <YAxis
                      tick={{ fontSize: 11, fill: "hsl(220 10% 44%)" }}
                      axisLine={false}
                      tickLine={false}
                    />
                    <RechartsTooltip content={<RevenueTooltip />} />
                    <Area
                      type="monotone"
                      dataKey="usd"
                      stroke={CURRENCY_COLORS.usd}
                      strokeWidth={2}
                      fill="url(#usdFill)"
                      dot={false}
                    />
                    <Area
                      type="monotone"
                      dataKey="zwl"
                      stroke={CURRENCY_COLORS.zwl}
                      strokeWidth={2}
                      fill="url(#zwlFill)"
                      dot={false}
                    />
                    <Area
                      type="monotone"
                      dataKey="zar"
                      stroke={CURRENCY_COLORS.zar}
                      strokeWidth={2}
                      fill="url(#zarFill)"
                      dot={false}
                    />
                  </AreaChart>
                </ResponsiveContainer>
              ) : (
                <div className="flex h-[260px] items-center justify-center text-sm text-muted-foreground">
                  No revenue in this period
                </div>
              )}
            </CardContent>
          </Card>
        </motion.div>

        <motion.div variants={itemVariants}>
          <Card className="h-full border-border/60 shadow-sm">
            <CardHeader className="pb-2">
              <SectionTitle icon={Wallet} title="Currency split" />
              <p className="mt-1 text-[11px] text-muted-foreground">{periodLabel}</p>
            </CardHeader>
            <CardContent className="flex flex-col items-center pt-0">
              {currencyPie.length > 0 ? (
                <>
                  <ResponsiveContainer width="100%" height={160}>
                    <PieChart>
                      <Pie
                        data={currencyPie}
                        cx="50%"
                        cy="50%"
                        innerRadius={46}
                        outerRadius={70}
                        paddingAngle={3}
                        dataKey="value"
                        strokeWidth={0}
                      >
                        {currencyPie.map((entry) => (
                          <Cell key={entry.name} fill={entry.color} />
                        ))}
                      </Pie>
                    </PieChart>
                  </ResponsiveContainer>
                  <div className="mt-2 w-full space-y-2.5">
                    {currencyPie.map((c) => (
                      <div key={c.name} className="flex items-center justify-between text-sm">
                        <div className="flex items-center gap-2">
                          <div className="h-2.5 w-2.5 rounded-full" style={{ backgroundColor: c.color }} />
                          <span className="text-xs font-medium text-muted-foreground">{c.name}</span>
                        </div>
                        <span className="font-display text-xs font-bold text-foreground">
                          {c.value.toLocaleString()}
                        </span>
                      </div>
                    ))}
                  </div>
                </>
              ) : (
                <div className="flex h-40 items-center justify-center text-sm text-muted-foreground">
                  No currency totals yet
                </div>
              )}
            </CardContent>
          </Card>
        </motion.div>
      </div>

      {/* Recent tickets */}
      <motion.div variants={itemVariants}>
        <Card className="border-border/60 shadow-sm">
          <CardHeader className="pb-3">
            <SectionTitle
              icon={Ticket}
              title="Recent tickets"
              tone="accent"
              action={
                <div className="flex items-center gap-2">
                  {voidRate && voidRate.total_tickets > 0 && (
                    <Badge
                      variant={
                        voidRate.void_rate > 10
                          ? "destructive"
                          : voidRate.void_rate > 5
                            ? "secondary"
                            : "outline"
                      }
                      className="text-[9px]"
                    >
                      {voidRate.void_rate}% void · {periodLabel}
                    </Badge>
                  )}
                  <Link
                    to="/tickets"
                    className="inline-flex items-center gap-0.5 text-[11px] font-medium text-primary hover:text-primary/80"
                  >
                    View all <ArrowUpRight className="h-3 w-3" />
                  </Link>
                </div>
              }
            />
          </CardHeader>
          <CardContent className="p-0">
            {recentTickets.length > 0 ? (
              <div className="divide-y divide-border/50">
                {recentTickets.map((ticket) => {
                  const voided = Boolean(ticket.is_voided);
                  const route =
                    ticket.route_label ||
                    `${ticket.departure || "—"} → ${ticket.destination || "—"}`;
                  return (
                    <Link
                      key={ticket.id}
                      to={ticket.trip_id ? `/trips/${ticket.trip_id}` : "/tickets"}
                      className="flex items-center gap-4 px-6 py-3 transition-colors hover:bg-muted/30"
                    >
                      <div
                        className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-lg ${
                          voided
                            ? "bg-destructive/10"
                            : ticket.ticket_category === "LUGGAGE"
                              ? "bg-warning/10"
                              : "bg-primary/10"
                        }`}
                      >
                        {ticket.printed === false && !voided ? (
                          <Printer className="h-3.5 w-3.5 text-amber-700" />
                        ) : (
                          <Ticket
                            className={`h-3.5 w-3.5 ${
                              voided
                                ? "text-destructive"
                                : ticket.ticket_category === "LUGGAGE"
                                  ? "text-warning"
                                  : "text-primary"
                            }`}
                          />
                        )}
                      </div>
                      <div className="min-w-0 flex-1">
                        <div className="flex flex-wrap items-center gap-2">
                          <p className="truncate text-xs font-medium text-foreground">{route}</p>
                          <span className="text-[10px] text-muted-foreground">
                            {categoryLabel(ticket.ticket_category)}
                          </span>
                          {voided && (
                            <Badge variant="destructive" className="h-4 px-1.5 text-[9px]">
                              VOID
                            </Badge>
                          )}
                          {ticket.printed === false && !voided && (
                            <Badge variant="outline" className="h-4 px-1.5 text-[9px] text-amber-800">
                              Unprinted
                            </Badge>
                          )}
                        </div>
                        <p className="text-[11px] text-muted-foreground">
                          {ticket.agent_name || "—"} · #{ticket.serial_number ?? "—"}
                        </p>
                      </div>
                      <div className="shrink-0 text-right">
                        <p
                          className={`font-display text-xs font-bold ${
                            voided ? "text-destructive line-through" : "text-foreground"
                          }`}
                        >
                          {ticket.currency} {Number(ticket.amount).toLocaleString()}
                        </p>
                        <p className="text-[10px] text-muted-foreground">
                          {format(new Date(ticket.issued_at), "dd MMM · HH:mm")}
                        </p>
                      </div>
                    </Link>
                  );
                })}
              </div>
            ) : (
              <div className="px-6 py-12 text-center text-sm text-muted-foreground">
                No recent tickets
              </div>
            )}
          </CardContent>
        </Card>
      </motion.div>

      {/* Rankings + fleet */}
      <div className="grid grid-cols-1 gap-5 lg:grid-cols-3">
        <motion.div variants={itemVariants}>
          <Card className="h-full border-border/60 shadow-sm">
            <CardHeader className="pb-3">
              <SectionTitle icon={UserRound} title="Top conductors" tone="success" />
              <p className="mt-1 text-[11px] text-muted-foreground">{periodLabel}</p>
            </CardHeader>
            <CardContent className="p-0">
              {agentPerformance.length > 0 ? (
                <div className="divide-y divide-border/50">
                  {agentPerformance.map((agent, idx) => (
                    <div
                      key={agent.agent_id}
                      className="flex items-center gap-3 px-6 py-3 hover:bg-muted/30"
                    >
                      <div className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-primary/10">
                        <span className="text-[10px] font-bold text-primary">#{idx + 1}</span>
                      </div>
                      <div className="min-w-0 flex-1">
                        <p className="truncate text-xs font-medium text-foreground">
                          {agent.agent_name}
                        </p>
                        <p className="text-[10px] text-muted-foreground">
                          {agent.ticket_count} tickets
                        </p>
                      </div>
                      <p className="shrink-0 font-display text-xs font-bold text-foreground">
                        {agent.revenue.toLocaleString()}
                      </p>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="px-6 py-12 text-center text-sm text-muted-foreground">
                  No conductor sales in this period
                </div>
              )}
            </CardContent>
          </Card>
        </motion.div>

        <motion.div variants={itemVariants}>
          <Card className="h-full border-border/60 shadow-sm">
            <CardHeader className="pb-2">
              <SectionTitle icon={Bus} title="Fleet status" tone="accent" />
            </CardHeader>
            <CardContent>
              {fleetUtilization ? (
                <div className="space-y-3">
                  <div className="grid grid-cols-2 gap-2.5">
                    <div className="rounded-lg border border-success/20 bg-success/10 p-3">
                      <p className="font-display text-lg font-bold text-foreground">
                        {fleetUtilization.active}
                      </p>
                      <p className="text-[10px] text-muted-foreground">Active</p>
                    </div>
                    <div className="rounded-lg border border-amber-500/25 bg-amber-500/10 p-3">
                      <p className="font-display text-lg font-bold text-foreground">
                        {fleetUtilization.maintenance}
                      </p>
                      <p className="text-[10px] text-muted-foreground">Maintenance</p>
                    </div>
                    <div className="rounded-lg border border-destructive/20 bg-destructive/10 p-3">
                      <p className="font-display text-lg font-bold text-foreground">
                        {fleetUtilization.out_of_service}
                      </p>
                      <p className="text-[10px] text-muted-foreground">Out of service</p>
                    </div>
                    <div className="rounded-lg border border-border bg-muted p-3">
                      <p className="font-display text-lg font-bold text-foreground">
                        {fleetUtilization.retired}
                      </p>
                      <p className="text-[10px] text-muted-foreground">Retired</p>
                    </div>
                  </div>
                  <p className="border-t border-border/50 pt-2 text-xs text-muted-foreground">
                    {fleetUtilization.active_trips} of {fleetUtilization.total} fleets on trips
                  </p>
                  <Link
                    to="/fleets"
                    className="inline-flex items-center gap-0.5 text-[11px] font-medium text-primary hover:text-primary/80"
                  >
                    Manage fleets <ArrowUpRight className="h-3 w-3" />
                  </Link>
                </div>
              ) : (
                <div className="py-8 text-center text-sm text-muted-foreground">No fleet data</div>
              )}
            </CardContent>
          </Card>
        </motion.div>

        <motion.div variants={itemVariants}>
          <Card className="h-full border-border/60 shadow-sm">
            <CardHeader className="pb-3">
              <SectionTitle icon={MapPin} title="Top corridors" />
              <p className="mt-1 text-[11px] text-muted-foreground">{periodLabel}</p>
            </CardHeader>
            <CardContent className="p-0">
              {routePerformance.length > 0 ? (
                <div className="divide-y divide-border/50">
                  {routePerformance.map((route, idx) => (
                    <div
                      key={`${route.route_id}-${idx}`}
                      className="flex items-center gap-3 px-6 py-3 hover:bg-muted/30"
                    >
                      <div className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-primary/10">
                        <span className="text-[10px] font-bold text-primary">#{idx + 1}</span>
                      </div>
                      <div className="min-w-0 flex-1">
                        <p className="truncate text-xs font-medium text-foreground">
                          {route.route_label}
                        </p>
                        <p className="text-[10px] text-muted-foreground">
                          {route.ticket_count} tickets
                        </p>
                      </div>
                      <p className="shrink-0 font-display text-xs font-bold text-foreground">
                        {route.revenue.toLocaleString()}
                      </p>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="px-6 py-12 text-center text-sm text-muted-foreground">
                  No corridor sales in this period
                </div>
              )}
            </CardContent>
          </Card>
        </motion.div>
      </div>

      {/* Depot comparison — super admin */}
      {userIsSuperAdmin && depotComparison.length > 0 && (
        <motion.div variants={itemVariants}>
          <Card className="border-border/60 shadow-sm">
            <CardHeader className="pb-3">
              <SectionTitle icon={Smartphone} title="Depot comparison" tone="secondary" />
              <p className="mt-1 text-[11px] text-muted-foreground">
                All-time ticket totals by depot (voids excluded)
              </p>
            </CardHeader>
            <CardContent className="p-0">
              <div className="divide-y divide-border/50">
                {depotComparison.map((depot) => (
                  <div
                    key={depot.depot_id}
                    className="flex flex-wrap items-center gap-3 px-6 py-3.5 sm:flex-nowrap"
                  >
                    <div className="min-w-0 flex-1">
                      <p className="truncate text-sm font-semibold text-foreground">
                        {depot.depot_name}
                      </p>
                      <p className="text-[11px] text-muted-foreground">
                        {depot.active_trips} active trips · {depot.active_agents} conductors
                      </p>
                    </div>
                    <div className="text-right">
                      <p className="font-display text-sm font-bold text-foreground">
                        {depot.revenue.toLocaleString()}
                      </p>
                      <p className="text-[10px] text-muted-foreground">{depot.tickets} tickets</p>
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </motion.div>
      )}
    </motion.div>
  );
};

export default Dashboard;

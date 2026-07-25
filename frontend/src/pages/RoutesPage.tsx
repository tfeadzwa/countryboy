import { useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import {
  formatDistanceToNow,
  isThisMonth,
  isThisWeek,
  isToday,
} from "date-fns";
import {
  ArrowRight,
  Bus,
  GitBranch,
  Loader2,
  MapPin,
  Route as RouteIcon,
  Search,
  Ticket,
} from "lucide-react";
import PageHeader from "@/components/PageHeader";
import ErrorAlert from "@/components/ErrorAlert";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { routeService, type CorridorSummary } from "@/lib/api/route.service";

type TimeGroupKey = "live" | "today" | "this_week" | "this_month" | "older" | "none";

const TIME_GROUP_LABELS: Record<TimeGroupKey, string> = {
  live: "Live now",
  today: "Active today",
  this_week: "This week",
  this_month: "This month",
  older: "Earlier",
  none: "No recent trips",
};

const TIME_GROUP_ORDER: TimeGroupKey[] = [
  "live",
  "today",
  "this_week",
  "this_month",
  "older",
  "none",
];

const toTimestamp = (value?: string | null) => {
  if (!value) return 0;
  const time = new Date(value).getTime();
  return Number.isNaN(time) ? 0 : time;
};

const compareByLastTrip = (a: CorridorSummary, b: CorridorSummary) => {
  const timeDiff = toTimestamp(b.last_trip_at) - toTimestamp(a.last_trip_at);
  if (timeDiff !== 0) return timeDiff;
  return b.trip_count - a.trip_count;
};

const timeGroupFor = (corridor: CorridorSummary): TimeGroupKey => {
  if (corridor.active_trip_count > 0) return "live";
  if (!corridor.last_trip_at) return "none";

  const at = new Date(corridor.last_trip_at);
  if (Number.isNaN(at.getTime())) return "none";
  if (isToday(at)) return "today";
  if (isThisWeek(at, { weekStartsOn: 1 })) return "this_week";
  if (isThisMonth(at)) return "this_month";
  return "older";
};

const RoutesPage = () => {
  const navigate = useNavigate();
  const [corridors, setCorridors] = useState<CorridorSummary[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [search, setSearch] = useState("");

  useEffect(() => {
    let cancelled = false;
    (async () => {
      setLoading(true);
      setError(null);
      try {
        const data = await routeService.getCorridors();
        if (!cancelled) setCorridors(data);
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : "Failed to load routes");
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  const filtered = useMemo(() => {
    const q = search.trim().toLowerCase();
    const matched = !q
      ? corridors
      : corridors.filter((c) => {
          const hay = [
            c.origin,
            c.destination,
            `${c.origin} ${c.destination}`,
            ...c.fleets,
          ]
            .join(" ")
            .toLowerCase();
          return hay.includes(q);
        });

    return [...matched].sort((a, b) => {
      const aLive = a.active_trip_count > 0 ? 0 : 1;
      const bLive = b.active_trip_count > 0 ? 0 : 1;
      if (aLive !== bLive) return aLive - bLive;
      return compareByLastTrip(a, b);
    });
  }, [corridors, search]);

  const grouped = useMemo(() => {
    const buckets = new Map<TimeGroupKey, CorridorSummary[]>();
    for (const key of TIME_GROUP_ORDER) buckets.set(key, []);

    for (const corridor of filtered) {
      buckets.get(timeGroupFor(corridor))!.push(corridor);
    }

    for (const key of TIME_GROUP_ORDER) {
      buckets.get(key)!.sort(compareByLastTrip);
    }

    return TIME_GROUP_ORDER
      .map((key) => ({ key, label: TIME_GROUP_LABELS[key], items: buckets.get(key)! }))
      .filter((group) => group.items.length > 0);
  }, [filtered]);

  const totals = useMemo(() => {
    return {
      corridors: corridors.length,
      trips: corridors.reduce((sum, c) => sum + c.trip_count, 0),
      active: corridors.reduce((sum, c) => sum + c.active_trip_count, 0),
      tickets: corridors.reduce((sum, c) => sum + c.ticket_count, 0),
      children: corridors.reduce((sum, c) => sum + (c.child_route_count ?? 0), 0),
    };
  }, [corridors]);

  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.35 }}
    >
      <PageHeader
        title="Routes"
        description="Live map of where conductors have been running — built from real trips. Main corridors come from trip starts; ticket journeys appear as linked child routes."
      />

      <div className="mb-6 grid gap-3 sm:grid-cols-2 lg:grid-cols-5">
        {[
          { label: "Main routes", value: totals.corridors, icon: MapPin },
          { label: "Child routes", value: totals.children, icon: GitBranch },
          { label: "Trips run", value: totals.trips, icon: RouteIcon },
          { label: "Active now", value: totals.active, icon: Bus },
          { label: "Tickets", value: totals.tickets, icon: Ticket },
        ].map((stat) => (
          <div
            key={stat.label}
            className="rounded-2xl border border-border/70 bg-gradient-to-br from-background to-muted/40 px-4 py-4"
          >
            <div className="flex items-center justify-between">
              <p className="text-xs font-semibold uppercase tracking-[0.14em] text-muted-foreground">
                {stat.label}
              </p>
              <stat.icon className="h-4 w-4 text-muted-foreground" />
            </div>
            <p className="mt-2 text-3xl font-semibold tracking-tight tabular-nums">
              {stat.value}
            </p>
          </div>
        ))}
      </div>

      <div className="mb-4 rounded-xl border border-border/80 bg-muted/30 px-4 py-3 text-sm text-muted-foreground">
        Starting a trip creates the <span className="font-medium text-foreground">main route</span>.
        Issuing a ticket with a different origin/destination adds a{" "}
        <span className="font-medium text-foreground">child route</span> under that main corridor.
        Click a card to explore segments and recent activity.
      </div>

      <ErrorAlert error={error} />

      {loading ? (
        <div className="flex items-center justify-center py-16">
          <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
        </div>
      ) : corridors.length === 0 ? (
        <div className="rounded-2xl border border-dashed border-border px-6 py-16 text-center">
          <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-muted">
            <RouteIcon className="h-7 w-7 text-muted-foreground" />
          </div>
          <h3 className="text-lg font-semibold">No routes yet</h3>
          <p className="mx-auto mt-2 max-w-md text-sm text-muted-foreground">
            When conductors start trips on the mobile app, main corridors appear here.
            Ticket journeys then show up as linked child routes.
          </p>
        </div>
      ) : (
        <>
          <div className="mb-4 flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
            <div className="relative w-full sm:max-w-md">
              <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Search origin, destination, or bus…"
                className="pl-9"
                aria-label="Search routes"
              />
            </div>
            <p className="text-xs text-muted-foreground sm:text-right">
              {search.trim()
                ? `${filtered.length} match${filtered.length === 1 ? "" : "es"}`
                : `${corridors.length} main route${corridors.length === 1 ? "" : "s"}`}
            </p>
          </div>

          {filtered.length === 0 ? (
            <div className="py-12 text-center text-muted-foreground">
              No routes match “{search.trim()}”.
            </div>
          ) : (
            <div className="space-y-8">
              {grouped.map((group) => (
                <section key={group.key} className="space-y-3">
                  <div className="flex items-center justify-between gap-3">
                    <h2 className="text-xs font-semibold uppercase tracking-[0.14em] text-muted-foreground">
                      {group.label}
                    </h2>
                    <span className="text-xs tabular-nums text-muted-foreground">
                      {group.items.length}
                    </span>
                  </div>
                  <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
                    {group.items.map((corridor, index) => (
                      <motion.button
                        key={corridor.id || corridor.key}
                        type="button"
                        initial={{ opacity: 0, y: 12 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ delay: Math.min(index * 0.03, 0.3) }}
                        onClick={() => navigate(`/routes/${corridor.id}`)}
                        className="group relative overflow-hidden rounded-2xl border border-border bg-card p-5 text-left shadow-sm transition hover:-translate-y-0.5 hover:border-primary/40 hover:shadow-md focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary"
                      >
                        <div className="pointer-events-none absolute inset-x-0 top-0 h-1 bg-gradient-to-r from-primary/80 via-amber-500/70 to-transparent" />
                        <div className="flex items-start justify-between gap-3">
                          <div className="min-w-0">
                            <div className="flex items-center gap-2 text-base font-semibold">
                              <span className="truncate">{corridor.origin}</span>
                              <ArrowRight className="h-4 w-4 shrink-0 text-muted-foreground" />
                              <span className="truncate">{corridor.destination}</span>
                            </div>
                            <p className="mt-1 text-xs text-muted-foreground">
                              {corridor.last_trip_at
                                ? `Last trip ${formatDistanceToNow(new Date(corridor.last_trip_at), { addSuffix: true })}`
                                : "No recent trip"}
                            </p>
                          </div>
                          <div className="flex shrink-0 flex-col items-end gap-1">
                            {corridor.active_trip_count > 0 && (
                              <Badge className="bg-emerald-600/90 hover:bg-emerald-600/90">
                                {corridor.active_trip_count} live
                              </Badge>
                            )}
                            <Badge variant="outline" className="gap-1 text-xs">
                              <GitBranch className="h-3 w-3" />
                              {corridor.child_route_count ?? 0}
                            </Badge>
                          </div>
                        </div>

                        <div className="mt-5 grid grid-cols-3 gap-2">
                          <div className="rounded-xl bg-muted/50 px-3 py-2">
                            <p className="text-[10px] uppercase tracking-wider text-muted-foreground">
                              Trips
                            </p>
                            <p className="text-lg font-semibold tabular-nums">
                              {corridor.trip_count}
                            </p>
                          </div>
                          <div className="rounded-xl bg-muted/50 px-3 py-2">
                            <p className="text-[10px] uppercase tracking-wider text-muted-foreground">
                              Tickets
                            </p>
                            <p className="text-lg font-semibold tabular-nums">
                              {corridor.ticket_count}
                            </p>
                          </div>
                          <div className="rounded-xl bg-muted/50 px-3 py-2">
                            <p className="text-[10px] uppercase tracking-wider text-muted-foreground">
                              Buses
                            </p>
                            <p className="text-lg font-semibold tabular-nums">
                              {corridor.fleets.length}
                            </p>
                          </div>
                        </div>

                        <div className="mt-4 flex items-center justify-between text-xs text-muted-foreground">
                          <span>
                            {corridor.fleets.slice(0, 3).join(", ") || "No buses yet"}
                            {corridor.fleets.length > 3 ? ` +${corridor.fleets.length - 3}` : ""}
                          </span>
                          <span className="font-medium text-primary opacity-0 transition group-hover:opacity-100">
                            View details →
                          </span>
                        </div>
                      </motion.button>
                    ))}
                  </div>
                </section>
              ))}
            </div>
          )}
        </>
      )}
    </motion.div>
  );
};

export default RoutesPage;

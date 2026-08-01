import { useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { motion } from "framer-motion";
import { format, formatDistanceToNow } from "date-fns";
import {
  ArrowLeft,
  ArrowRight,
  Bus,
  GitBranch,
  Loader2,
  MapPin,
  Ticket,
  Users,
} from "lucide-react";
import ErrorAlert from "@/components/ErrorAlert";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { routeService, type CorridorDetail } from "@/lib/api/route.service";

const moneyBits = (revenue: Record<string, number>) => {
  const entries = Object.entries(revenue);
  if (entries.length === 0) return "—";
  return entries
    .map(([currency, amount]) => `${currency} ${amount.toFixed(0)}`)
    .join(" · ");
};

const RouteDetailPage = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [detail, setDetail] = useState<CorridorDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!id) return;
    let cancelled = false;
    (async () => {
      setLoading(true);
      setError(null);
      try {
        const data = await routeService.getCorridor(id);
        if (!cancelled) setDetail(data);
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : "Failed to load route");
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [id]);

  if (loading) {
    return (
      <div className="flex min-h-[50vh] items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
      </div>
    );
  }

  if (error || !detail) {
    return (
      <div className="space-y-4">
        <Button variant="ghost" className="gap-2 px-0" onClick={() => navigate("/routes")}>
          <ArrowLeft className="h-4 w-4" /> Back to routes
        </Button>
        <ErrorAlert error={error ?? "Route not found"} />
      </div>
    );
  }

  const summary = detail.summary;

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.35 }}
      className="space-y-6"
    >
      <div className="flex flex-wrap items-center justify-between gap-3">
        <Button variant="ghost" className="gap-2 px-0" asChild>
          <Link to="/routes">
            <ArrowLeft className="h-4 w-4" /> All routes
          </Link>
        </Button>
        {summary.active_trip_count > 0 && (
          <Badge className="bg-emerald-600/90 hover:bg-emerald-600/90">
            {summary.active_trip_count} trip{summary.active_trip_count === 1 ? "" : "s"} live
          </Badge>
        )}
      </div>

      <section className="relative overflow-hidden rounded-3xl border border-border bg-gradient-to-br from-[hsl(30_30%_98%)] via-background to-[hsl(8_55%_96%)] px-6 py-8 shadow-sm">
        <div className="pointer-events-none absolute -right-10 -top-10 h-40 w-40 rounded-full bg-primary/10 blur-2xl" />
        <div className="pointer-events-none absolute -bottom-16 left-10 h-36 w-36 rounded-full bg-amber-400/10 blur-2xl" />
        <p className="text-xs font-semibold uppercase tracking-[0.18em] text-muted-foreground">
          Main corridor
        </p>
        <div className="mt-3 flex flex-wrap items-center gap-3">
          <h1
            className="text-3xl font-bold tracking-tight sm:text-4xl"
            style={{ fontFamily: "var(--font-display)" }}
          >
            {detail.origin}
          </h1>
          <ArrowRight className="h-6 w-6 text-primary" />
          <h1
            className="text-3xl font-bold tracking-tight sm:text-4xl"
            style={{ fontFamily: "var(--font-display)" }}
          >
            {detail.destination}
          </h1>
        </div>
        <p className="mt-3 max-w-2xl text-sm text-muted-foreground">
          Created when conductors start trips on this corridor. Ticket journeys below are
          linked child routes — still normal routes, nested under this parent.
        </p>
        <div className="mt-5 flex flex-wrap gap-2 text-xs text-muted-foreground">
          <span className="rounded-full border border-border bg-background/80 px-3 py-1">
            Depot: {detail.depot.name}
          </span>
          <span className="rounded-full border border-border bg-background/80 px-3 py-1">
            First seen {format(new Date(detail.created_at), "dd MMM yyyy")}
          </span>
        </div>
      </section>

      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        {[
          { label: "Trips", value: summary.trip_count, icon: MapPin },
          { label: "Child routes", value: summary.child_route_count, icon: GitBranch },
          { label: "Tickets", value: summary.ticket_count, icon: Ticket },
          { label: "Buses", value: summary.fleets.length, icon: Bus },
        ].map((stat) => (
          <div
            key={stat.label}
            className="rounded-2xl border border-border/70 bg-card px-4 py-4"
          >
            <div className="flex items-center justify-between">
              <p className="text-xs font-semibold uppercase tracking-[0.14em] text-muted-foreground">
                {stat.label}
              </p>
              <stat.icon className="h-4 w-4 text-muted-foreground" />
            </div>
            <p className="mt-2 text-3xl font-semibold tabular-nums">{stat.value}</p>
          </div>
        ))}
      </div>

      <div className="rounded-2xl border border-border bg-muted/20 px-4 py-3 text-sm text-muted-foreground">
        Revenue on this corridor:{" "}
        <span className="font-medium text-foreground">
          {moneyBits(summary.revenue_by_currency)}
        </span>
        {summary.fleets.length > 0 && (
          <>
            {" "}
            · Buses:{" "}
            <span className="font-mono text-foreground">{summary.fleets.join(", ")}</span>
          </>
        )}
      </div>

      <section className="space-y-3">
        <div className="flex items-end justify-between gap-3">
          <div>
            <h2 className="text-lg font-semibold">Child routes</h2>
            <p className="text-sm text-muted-foreground">
              Segments conductors used when issuing tickets under this main corridor.
            </p>
          </div>
          <Badge variant="outline">{detail.child_routes.length}</Badge>
        </div>

        {detail.child_routes.length === 0 ? (
          <div className="rounded-2xl border border-dashed border-border px-5 py-10 text-center text-sm text-muted-foreground">
            No child routes yet. They appear when tickets use a different origin/destination
            than the trip corridor.
          </div>
        ) : (
          <div className="grid gap-3 md:grid-cols-2">
            {detail.child_routes.map((child, index) => (
              <motion.div
                key={child.id}
                initial={{ opacity: 0, y: 8 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: Math.min(index * 0.04, 0.28) }}
                className="rounded-2xl border border-border bg-card p-4 shadow-sm"
              >
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0">
                    <div className="flex items-center gap-2 font-semibold">
                      <span className="truncate">{child.origin}</span>
                      <ArrowRight className="h-3.5 w-3.5 shrink-0 text-muted-foreground" />
                      <span className="truncate">{child.destination}</span>
                    </div>
                    <p className="mt-1 text-xs text-muted-foreground">Linked segment route</p>
                  </div>
                  <Badge variant="secondary" className="shrink-0">
                    {child.ticket_count} ticket{child.ticket_count === 1 ? "" : "s"}
                  </Badge>
                </div>
                <div className="mt-3 flex items-center justify-between text-xs text-muted-foreground">
                  <span>Revenue touch</span>
                  <span className="font-medium tabular-nums text-foreground">
                    {child.revenue > 0 ? child.revenue.toFixed(0) : "—"}
                  </span>
                </div>
              </motion.div>
            ))}
          </div>
        )}
      </section>

      <section className="space-y-3">
        <div>
          <h2 className="text-lg font-semibold">Recent trips</h2>
          <p className="text-sm text-muted-foreground">
            Latest conductor runs on this main corridor.
          </p>
        </div>

        {detail.recent_trips.length === 0 ? (
          <div className="rounded-2xl border border-dashed border-border px-5 py-10 text-center text-sm text-muted-foreground">
            No trips recorded on this route yet.
          </div>
        ) : (
          <div className="overflow-hidden rounded-2xl border border-border">
            <div className="divide-y divide-border">
              {detail.recent_trips.map((trip) => (
                <div
                  key={trip.id}
                  className="flex flex-col gap-3 bg-card px-4 py-4 sm:flex-row sm:items-center sm:justify-between"
                >
                  <div className="min-w-0 space-y-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <Badge
                        variant={trip.status === "ACTIVE" ? "default" : "outline"}
                        className={
                          trip.status === "ACTIVE"
                            ? "bg-emerald-600/90 hover:bg-emerald-600/90"
                            : ""
                        }
                      >
                        {trip.status}
                      </Badge>
                      <span className="text-sm font-medium">
                        {trip.fleet_number ? `Bus ${trip.fleet_number}` : "Bus —"}
                      </span>
                      <span className="text-xs text-muted-foreground">
                        {formatDistanceToNow(new Date(trip.started_at), { addSuffix: true })}
                      </span>
                    </div>
                    <div className="flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
                      <span className="inline-flex items-center gap-1">
                        <Users className="h-3.5 w-3.5" />
                        {trip.agent_name ?? "Conductor"}
                      </span>
                      <span>·</span>
                      <span>
                        {trip.ticket_count} ticket{trip.ticket_count === 1 ? "" : "s"}
                      </span>
                    </div>
                    {trip.segments.length > 0 && (
                      <div className="flex flex-wrap gap-1.5 pt-1">
                        {trip.segments.slice(0, 4).map((segment) => (
                          <Badge key={segment} variant="outline" className="text-[11px]">
                            {segment}
                          </Badge>
                        ))}
                        {trip.segments.length > 4 && (
                          <Badge variant="outline" className="text-[11px]">
                            +{trip.segments.length - 4}
                          </Badge>
                        )}
                      </div>
                    )}
                  </div>
                  <div className="flex shrink-0 flex-col gap-2 sm:items-end">
                    <div className="text-xs text-muted-foreground sm:text-right">
                      Started {format(new Date(trip.started_at), "dd MMM · HH:mm")}
                    </div>
                    <Button
                      variant="outline"
                      size="sm"
                      className="gap-1.5 self-start sm:self-end"
                      onClick={() => navigate(`/trips/${trip.id}`)}
                    >
                      View Trip
                      <ArrowRight className="h-3.5 w-3.5" />
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </section>
    </motion.div>
  );
};

export default RouteDetailPage;

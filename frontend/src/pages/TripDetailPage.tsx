import { useEffect, useMemo, useState, type ReactNode } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { motion } from "framer-motion";
import { format, formatDistanceStrict } from "date-fns";
import {
  ArrowLeft,
  ArrowRight,
  Bus,
  Clock,
  Gauge,
  Loader2,
  MapPin,
  Printer,
  Smartphone,
  Square,
  Ticket,
  UserRound,
  Users,
  Wallet,
} from "lucide-react";
import ErrorAlert from "@/components/ErrorAlert";
import EndTripConfirmDialog from "@/components/EndTripConfirmDialog";
import TicketReceiptPrintDialog from "@/components/TicketReceiptPrintDialog";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/contexts/AuthContext";
import { useToast } from "@/hooks/use-toast";
import { tripService } from "@/lib/api/trip.service";
import { canEndTrips, canPrintTicketBatches } from "@/lib/permissions";
import type { TripDetail, TripDetailTicket } from "@/types";

const statusConfig: Record<string, { class: string; label: string }> = {
  ACTIVE: { class: "bg-amber-500/15 text-amber-800 border border-amber-500/30", label: "In progress" },
  ENDED: { class: "bg-muted text-muted-foreground border border-border", label: "Ended" },
  COMPLETED: { class: "bg-muted text-muted-foreground border border-border", label: "Ended" },
  CANCELLED: { class: "bg-destructive/10 text-destructive border border-destructive/20", label: "Cancelled" },
};

const categoryLabel = (category: string) => {
  switch (category) {
    case "PASSENGER":
      return "Passenger";
    case "LUGGAGE":
      return "Luggage";
    case "PASSENGER_WITH_LUGGAGE":
      return "Passenger + luggage";
    default:
      return category.replace(/_/g, " ");
  }
};

const moneyBits = (revenue?: Record<string, number> | null, fallback?: number) => {
  const entries = Object.entries(revenue ?? {});
  if (entries.length === 0) {
    return fallback != null ? `USD ${fallback.toFixed(2)}` : "—";
  }
  return entries
    .map(([currency, amount]) => `${currency} ${amount.toFixed(2)}`)
    .join(" · ");
};

const formatWhen = (value?: string | null) => {
  if (!value) return "—";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "—";
  return format(date, "dd MMM yyyy · HH:mm");
};

const durationLabel = (trip: TripDetail) => {
  if (trip.duration_ms == null || trip.duration_ms < 0) return "—";
  try {
    const end = trip.ended_at ? new Date(trip.ended_at) : new Date();
    return formatDistanceStrict(new Date(trip.started_at), end);
  } catch {
    return "—";
  }
};

const StatusPill = ({
  label,
  tone,
}: {
  label: string;
  tone: "online" | "offline" | "amber" | "muted" | "success";
}) => {
  const tones: Record<typeof tone, string> = {
    online: "bg-emerald-500/10 text-emerald-700 ring-emerald-500/20",
    offline: "bg-slate-500/10 text-slate-600 ring-slate-500/15",
    amber: "bg-amber-500/15 text-amber-800 ring-amber-500/30",
    muted: "bg-muted text-muted-foreground ring-border",
    success: "bg-success/10 text-success ring-success/20",
  };
  return (
    <span
      className={`inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide ring-1 ring-inset ${tones[tone]}`}
    >
      {label}
    </span>
  );
};

const isActiveTrip = (trip: TripDetail) => trip.status === "ACTIVE";

const conductorPresencePill = (trip: TripDetail) => {
  if (!isActiveTrip(trip)) return null;
  const presence = trip.conductor_presence;
  if (presence === "online" || trip.conductor_is_online) {
    return <StatusPill label="Online" tone="online" />;
  }
  if (presence === "offline") {
    return <StatusPill label="Offline" tone="offline" />;
  }
  return <StatusPill label="Signed out" tone="muted" />;
};

const driverDutyPill = (trip: TripDetail) => {
  if (!isActiveTrip(trip) || !trip.driver_id) return null;
  if (trip.driver_duty_status === "on_trip") {
    return <StatusPill label="On trip" tone="amber" />;
  }
  if (trip.driver_duty_status === "available") {
    return <StatusPill label="Available" tone="success" />;
  }
  if (trip.driver_duty_status === "off_duty") {
    return <StatusPill label="Off duty" tone="muted" />;
  }
  if (trip.driver_status) {
    return <StatusPill label={trip.driver_status} tone="muted" />;
  }
  return null;
};

const fleetStatusPill = (trip: TripDetail) => {
  if (!trip.fleet_status) return null;
  const active = trip.fleet_status === "ACTIVE";
  return (
    <StatusPill
      label={trip.fleet_status}
      tone={active ? "success" : "muted"}
    />
  );
};

const devicePresencePill = (trip: TripDetail) => {
  if (!isActiveTrip(trip)) return null;
  if (trip.device_presence === "online") {
    return <StatusPill label="Online" tone="online" />;
  }
  if (trip.device_presence === "offline") {
    return <StatusPill label="Offline" tone="offline" />;
  }
  if (trip.device_presence === "unpaired") {
    return <StatusPill label="Unpaired" tone="muted" />;
  }
  return null;
};

const InfoCell = ({
  label,
  value,
  icon: Icon,
  mono,
  hint,
}: {
  label: string;
  value: ReactNode;
  icon?: typeof MapPin;
  mono?: boolean;
  hint?: string;
}) => (
  <div className="rounded-xl border border-border/80 bg-muted/20 p-3.5">
    <div className="mb-1.5 flex items-center gap-1.5 text-[11px] font-medium uppercase tracking-wide text-muted-foreground">
      {Icon && <Icon className="h-3.5 w-3.5" />}
      {label}
    </div>
    <div className={`text-sm font-semibold leading-snug ${mono ? "font-mono" : ""}`}>{value}</div>
    {hint && <p className="mt-1 text-xs text-muted-foreground">{hint}</p>}
  </div>
);

const TicketRow = ({
  ticket,
  canPrint,
  onPrint,
}: {
  ticket: TripDetailTicket;
  canPrint: boolean;
  onPrint: (ticket: TripDetailTicket) => void;
}) => (
  <div
    className={`rounded-xl border p-3.5 transition-colors ${
      ticket.is_voided
        ? "border-destructive/20 bg-destructive/5 opacity-80"
        : "border-border/80 bg-background/80"
    }`}
  >
    <div className="flex flex-wrap items-start justify-between gap-2">
      <div className="min-w-0">
        <div className="flex flex-wrap items-center gap-2">
          <p className="font-mono text-sm font-semibold">
            {ticket.serial_number != null ? `#${ticket.serial_number}` : ticket.id.slice(0, 8)}
          </p>
          <Badge variant="outline" className="text-[10px]">
            {categoryLabel(ticket.ticket_category)}
          </Badge>
          {ticket.is_voided && (
            <Badge className="bg-destructive/10 text-destructive border border-destructive/20 text-[10px]">
              Voided
            </Badge>
          )}
        </div>
        <p className="mt-1 text-sm font-medium">
          {ticket.passenger_name || "Walk-up passenger"}
          {ticket.passenger_phone ? (
            <span className="font-normal text-muted-foreground"> · {ticket.passenger_phone}</span>
          ) : null}
        </p>
        {(ticket.departure || ticket.destination) && (
          <p className="mt-0.5 text-xs text-muted-foreground">
            {(ticket.departure || "—") + " → " + (ticket.destination || "—")}
          </p>
        )}
        {ticket.luggage_description && (
          <p className="mt-1 text-xs text-muted-foreground">Luggage: {ticket.luggage_description}</p>
        )}
      </div>
      <div className="flex shrink-0 flex-col items-end gap-2">
        <div className="text-right">
          <p className="font-semibold tabular-nums">
            {ticket.currency} {Number(ticket.amount).toFixed(2)}
          </p>
          <p className="text-[11px] text-muted-foreground mt-0.5">{formatWhen(ticket.issued_at)}</p>
        </div>
        {canPrint && !ticket.is_voided && (
          <Button
            variant="outline"
            size="sm"
            className="h-8 gap-1.5 px-2.5"
            onClick={() => onPrint(ticket)}
          >
            <Printer className="h-3.5 w-3.5" />
            Print
          </Button>
        )}
      </div>
    </div>
    {ticket.is_voided && ticket.voids?.[0]?.reason && (
      <p className="mt-2 text-xs text-destructive">Void reason: {ticket.voids[0].reason}</p>
    )}
  </div>
);

const TripDetailPage = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { user } = useAuth();
  const { toast } = useToast();
  const canEnd = canEndTrips(user?.roles || []);
  const canPrint = canPrintTicketBatches(user?.roles || []);
  const [trip, setTrip] = useState<TripDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [ending, setEnding] = useState(false);
  const [endConfirmOpen, setEndConfirmOpen] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [printTicket, setPrintTicket] = useState<TripDetailTicket | null>(null);

  const loadTrip = async (tripId: string, opts?: { silent?: boolean }) => {
    if (!opts?.silent) {
      setLoading(true);
      setError(null);
    }
    try {
      const data = await tripService.getOne(tripId);
      setTrip(data);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load trip");
    } finally {
      if (!opts?.silent) setLoading(false);
    }
  };

  useEffect(() => {
    if (!id) return;
    let cancelled = false;
    (async () => {
      setLoading(true);
      setError(null);
      try {
        const data = await tripService.getOne(id);
        if (!cancelled) setTrip(data);
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : "Failed to load trip");
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [id]);

  const handleEndTrip = async () => {
    if (!trip || !canEnd || trip.status !== "ACTIVE") return;

    setEnding(true);
    try {
      await tripService.end(trip.id, trip.depot_id);
      setEndConfirmOpen(false);
      toast({
        title: "Trip ended",
        description: `${trip.fleet_number || "Trip"} closed successfully.`,
      });
      await loadTrip(trip.id, { silent: true });
    } catch (err) {
      toast({
        title: "Could not end trip",
        description: err instanceof Error ? err.message : "Try again",
        variant: "destructive",
      });
    } finally {
      setEnding(false);
    }
  };

  const tickets = useMemo(() => trip?.tickets ?? [], [trip]);
  const activeTickets = useMemo(() => tickets.filter((t) => !t.is_voided), [tickets]);
  const voidedTickets = useMemo(() => tickets.filter((t) => t.is_voided), [tickets]);
  const ticketCount = trip?.ticket_count ?? activeTickets.length;
  const avgFare = useMemo(() => {
    if (!trip || ticketCount <= 0) return null;
    const entries = Object.entries(trip.revenue_by_currency ?? {});
    if (entries.length === 1) {
      const [currency, amount] = entries[0];
      return `${currency} ${(amount / ticketCount).toFixed(2)}`;
    }
    if (trip.total_revenue != null) {
      return `USD ${(Number(trip.total_revenue) / ticketCount).toFixed(2)}`;
    }
    return null;
  }, [trip, ticketCount]);

  if (loading) {
    return (
      <div className="flex min-h-[50vh] items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
      </div>
    );
  }

  if (error || !trip) {
    return (
      <div className="space-y-4">
        <Button variant="ghost" className="gap-2 px-0" onClick={() => navigate(-1)}>
          <ArrowLeft className="h-4 w-4" /> Back
        </Button>
        <ErrorAlert error={error ?? "Trip not found"} />
      </div>
    );
  }

  const status = statusConfig[trip.status] ?? statusConfig.ENDED;
  const origin = trip.origin || "—";
  const destination = trip.destination || "—";

  return (
    <motion.div
      initial={{ opacity: 0, y: 10 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.35 }}
      className="space-y-6"
    >
      <div className="flex flex-wrap items-center justify-between gap-3">
        <Button variant="ghost" className="gap-2 px-0" onClick={() => navigate(-1)}>
          <ArrowLeft className="h-4 w-4" /> Back
        </Button>
        <div className="flex flex-wrap items-center gap-2">
          <Button variant="outline" size="sm" asChild>
            <Link to="/trips">All trips</Link>
          </Button>
          {canEnd && trip.status === "ACTIVE" && (
            <Button
              variant="outline"
              size="sm"
              className="gap-1.5 border-destructive/30 text-destructive hover:bg-destructive/10 hover:text-destructive"
              disabled={ending}
              onClick={() => setEndConfirmOpen(true)}
            >
              <Square className="h-3.5 w-3.5" />
              End trip
            </Button>
          )}
          <Badge className={`text-xs ${status.class}`}>{status.label}</Badge>
        </div>
      </div>

      <section className="relative overflow-hidden rounded-3xl border border-border bg-gradient-to-br from-[hsl(28_40%_98%)] via-background to-[hsl(210_45%_96%)] px-6 py-8 shadow-sm">
        <div className="pointer-events-none absolute -right-10 -top-10 h-40 w-40 rounded-full bg-amber-400/15 blur-2xl" />
        <div className="pointer-events-none absolute -bottom-16 left-10 h-36 w-36 rounded-full bg-sky-400/10 blur-2xl" />
        <p className="text-xs font-semibold uppercase tracking-[0.18em] text-muted-foreground">
          Trip corridor
        </p>
        <div className="mt-3 flex flex-wrap items-center gap-3">
          <h1
            className="text-3xl font-bold tracking-tight sm:text-4xl"
            style={{ fontFamily: "var(--font-display)" }}
          >
            {origin}
          </h1>
          <ArrowRight className="h-6 w-6 text-amber-700/80" />
          <h1
            className="text-3xl font-bold tracking-tight sm:text-4xl"
            style={{ fontFamily: "var(--font-display)" }}
          >
            {destination}
          </h1>
        </div>
        <div className="mt-4 flex flex-wrap gap-x-5 gap-y-2 text-sm text-muted-foreground">
          <span className="inline-flex items-center gap-1.5">
            <Bus className="h-4 w-4" />
            Bus {trip.fleet_number || "—"}
          </span>
          <span className="inline-flex items-center gap-1.5">
            <MapPin className="h-4 w-4" />
            {trip.depot_name || "Depot"}
            {trip.depot_merchant_code ? ` (${trip.depot_merchant_code})` : ""}
          </span>
          <span className="inline-flex items-center gap-1.5">
            <Clock className="h-4 w-4" />
            Started {formatWhen(trip.started_at)}
            <span className="text-border">·</span>
            {trip.ended_at ? `Ended ${formatWhen(trip.ended_at)}` : "Trip in progress"}
          </span>
          {trip.started_offline && (  
            <Badge variant="outline" className="text-[10px]">
              Started offline
            </Badge>
          )}
        </div>
      </section>

      <section className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        <InfoCell
          label="Tickets sold"
          icon={Ticket}
          value={trip.ticket_count ?? activeTickets.length}
          hint={
            trip.voided_ticket_count
              ? `${trip.voided_ticket_count} voided`
              : "Excludes voided tickets"
          }
        />
        <InfoCell
          label="Revenue"
          icon={Wallet}
          value={moneyBits(trip.revenue_by_currency, trip.total_revenue)}
        />
        <InfoCell label="Duration" icon={Clock} value={durationLabel(trip)} />
        <InfoCell
          label="Occupancy"
          icon={Gauge}
          value={
            trip.fleet_capacity != null && trip.fleet_capacity > 0
              ? `${ticketCount} / ${trip.fleet_capacity}`
              : `${ticketCount} seat${ticketCount === 1 ? "" : "s"}`
          }
          hint={
            trip.fleet_capacity != null && trip.fleet_capacity > 0
              ? `${Math.min(100, Math.round((ticketCount / trip.fleet_capacity) * 100))}% of bus capacity`
              : avgFare
                ? `Avg ticket ${avgFare}`
                : "Valid tickets on this trip"
          }
        />
      </section>

      <section className="grid gap-4 lg:grid-cols-3">
        <div className="rounded-2xl border border-border/80 bg-card p-5 space-y-3 lg:col-span-1">
          <p className="text-[11px] font-semibold uppercase tracking-wide text-muted-foreground">
            Assigned crew
          </p>
          <div className="space-y-3">
            <div className="rounded-xl border border-border/70 bg-muted/15 p-3.5">
              <div className="mb-1.5 flex items-center justify-between gap-2">
                <div className="flex items-center gap-1.5 text-[11px] uppercase tracking-wide text-muted-foreground">
                  <Users className="h-3.5 w-3.5" /> Conductor
                </div>
                {conductorPresencePill(trip)}
              </div>
              <p className="font-semibold">{trip.agent_name || "—"}</p>
              <p className="mt-0.5 font-mono text-xs text-muted-foreground">
                {trip.agent_code || "—"}
                {trip.agent_username ? ` · ${trip.agent_username}` : ""}
              </p>
            </div>
            <div className="rounded-xl border border-border/70 bg-muted/15 p-3.5">
              <div className="mb-1.5 flex items-center justify-between gap-2">
                <div className="flex items-center gap-1.5 text-[11px] uppercase tracking-wide text-muted-foreground">
                  <UserRound className="h-3.5 w-3.5" /> Driver
                </div>
                {driverDutyPill(trip)}
              </div>
              <p className="font-semibold">{trip.driver_name || "Not assigned"}</p>
              {(trip.driver_phone || trip.driver_licence) && (
                <p className="mt-0.5 text-xs text-muted-foreground">
                  {[trip.driver_phone, trip.driver_licence ? `Licence ${trip.driver_licence}` : null]
                    .filter(Boolean)
                    .join(" · ")}
                </p>
              )}
            </div>
            <div className="rounded-xl border border-border/70 bg-muted/15 p-3.5">
              <div className="mb-1.5 flex items-center justify-between gap-2">
                <div className="flex items-center gap-1.5 text-[11px] uppercase tracking-wide text-muted-foreground">
                  <Bus className="h-3.5 w-3.5" /> Fleet
                </div>
                {fleetStatusPill(trip)}
              </div>
              <p className="font-semibold font-mono">{trip.fleet_number || "—"}</p>
              <p className="mt-0.5 text-xs text-muted-foreground">
                {trip.fleet_capacity != null ? `Capacity ${trip.fleet_capacity}` : "Capacity —"}
              </p>
            </div>
            {(trip.device_serial || trip.device_name) && (
              <div className="rounded-xl border border-border/70 bg-muted/15 p-3.5">
                <div className="mb-1.5 flex items-center justify-between gap-2">
                  <div className="flex items-center gap-1.5 text-[11px] uppercase tracking-wide text-muted-foreground">
                    <Smartphone className="h-3.5 w-3.5" /> Device
                  </div>
                  {devicePresencePill(trip)}
                </div>
                <p className="font-semibold font-mono text-sm">{trip.device_serial || "—"}</p>
                {(trip.device_name || trip.device_model) && (
                  <p className="mt-0.5 text-xs text-muted-foreground">
                    {[trip.device_name, trip.device_model].filter(Boolean).join(" · ")}
                  </p>
                )}
                {isActiveTrip(trip) && trip.device_last_seen && (
                  <p className="mt-1 text-[11px] text-muted-foreground">
                    Last seen {formatWhen(trip.device_last_seen)}
                  </p>
                )}
              </div>
            )}
          </div>
        </div>

        <div className="rounded-2xl border border-border/80 bg-card p-5 space-y-4 lg:col-span-2">
          <div className="flex flex-wrap items-end justify-between gap-2">
            <div>
              <p className="text-[11px] font-semibold uppercase tracking-wide text-muted-foreground">
                Tickets on this trip
              </p>
              <p className="mt-1 text-sm text-muted-foreground">
                {activeTickets.length} valid
                {voidedTickets.length > 0 ? ` · ${voidedTickets.length} voided` : ""}
              </p>
            </div>
            {trip.category_counts && Object.keys(trip.category_counts).length > 0 && (
              <div className="flex flex-wrap gap-1.5">
                {Object.entries(trip.category_counts).map(([category, count]) => (
                  <Badge key={category} variant="outline" className="text-[10px]">
                    {categoryLabel(category)} · {count}
                  </Badge>
                ))}
              </div>
            )}
          </div>

          {tickets.length === 0 ? (
            <div className="rounded-xl border border-dashed border-border/80 px-4 py-10 text-center">
              <Ticket className="mx-auto mb-2 h-8 w-8 text-muted-foreground" />
              <p className="text-sm font-medium">No tickets issued yet</p>
              <p className="mt-1 text-xs text-muted-foreground">
                Tickets sold on this trip will appear here.
              </p>
            </div>
          ) : (
            <div className="max-h-[min(60vh,560px)] space-y-2.5 overflow-y-auto pr-1">
              {tickets.map((ticket) => (
                <TicketRow
                  key={ticket.id}
                  ticket={ticket}
                  canPrint={canPrint}
                  onPrint={setPrintTicket}
                />
              ))}
            </div>
          )}
        </div>
      </section>

      <EndTripConfirmDialog
        open={endConfirmOpen}
        onOpenChange={setEndConfirmOpen}
        loading={ending}
        onConfirm={() => void handleEndTrip()}
        trip={{
          fleet_number: trip.fleet_number,
          origin: trip.origin,
          destination: trip.destination,
          route_label: trip.route_label,
          agent_name: trip.agent_name,
          ticket_count: trip.ticket_count ?? activeTickets.length,
          revenue_label: moneyBits(trip.revenue_by_currency, trip.total_revenue),
        }}
      />

      <TicketReceiptPrintDialog
        open={!!printTicket}
        onOpenChange={(open) => {
          if (!open) setPrintTicket(null);
        }}
        ticket={printTicket}
        trip={trip}
      />
    </motion.div>
  );
};

export default TripDetailPage;

import { useEffect, useMemo, useState } from "react";
import { Printer, Loader2, X, Banknote, Bus, UserRound } from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { ticketService } from "@/lib/api/ticket.service";
import type { Ticket, Trip } from "@/types";

interface TripBatchPrintDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  trip: Trip | null;
}

const categoryLabel = (category: string) => {
  switch (category) {
    case "PASSENGER":
      return "Passenger";
    case "PASSENGER_WITH_LUGGAGE":
      return "Passenger + Luggage";
    case "LUGGAGE":
      return "Luggage";
    default:
      return category;
  }
};

const TripBatchPrintDialog = ({ open, onOpenChange, trip }: TripBatchPrintDialogProps) => {
  const [tickets, setTickets] = useState<Ticket[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!open || !trip) {
      setTickets([]);
      setError(null);
      return;
    }

    let cancelled = false;
    const load = async () => {
      setLoading(true);
      setError(null);
      try {
        const rows = await ticketService.search({ trip_id: trip.id });
        if (!cancelled) setTickets(rows);
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : "Could not load ticket batch");
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    };
    void load();
    return () => {
      cancelled = true;
    };
  }, [open, trip]);

  const validTickets = useMemo(
    () => tickets.filter((t) => !t.is_voided),
    [tickets],
  );

  const revenueByCurrency = useMemo(() => {
    const map = new Map<string, number>();
    for (const t of validTickets) {
      map.set(t.currency, (map.get(t.currency) ?? 0) + Number(t.amount));
    }
    return Array.from(map.entries()).sort(([a], [b]) => a.localeCompare(b));
  }, [validTickets]);

  const handlePrint = () => {
    window.print();
  };

  if (!trip) return null;

  const corridor =
    trip.route_label ||
    [trip.origin, trip.destination].filter(Boolean).join(" → ") ||
    "Corridor";

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-3xl max-h-[92vh] overflow-hidden p-0 gap-0 print:max-w-none print:max-h-none print:overflow-visible print:shadow-none print:border-0">
        <div className="flex items-start justify-between gap-3 border-b border-border/60 px-4 py-3 sm:px-6 print:hidden">
          <DialogHeader className="space-y-1 text-left">
            <DialogTitle className="text-lg sm:text-xl">Print ticket batch</DialogTitle>
            <DialogDescription>
              Review this trip’s sales, then print a cashier batch summary.
            </DialogDescription>
          </DialogHeader>
          <Button
            variant="ghost"
            size="icon"
            className="shrink-0"
            onClick={() => onOpenChange(false)}
          >
            <X className="h-4 w-4" />
          </Button>
        </div>

        <div className="overflow-y-auto px-4 py-4 sm:px-6 print:overflow-visible print:p-0">
          <div id="ticket-batch-print" className="space-y-4">
            <div className="rounded-xl border border-border/70 bg-muted/30 p-4 print:border print:rounded-none print:bg-transparent">
              <div className="flex flex-wrap items-start justify-between gap-3">
                <div>
                  <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                    CountryBoy · Ticket batch
                  </p>
                  <h2 className="mt-1 text-xl font-semibold tracking-tight">{corridor}</h2>
                  <p className="mt-1 text-sm text-muted-foreground">
                    Trip {trip.id.slice(0, 8)} · {trip.depot_name || "Depot"}
                  </p>
                </div>
                <Badge
                  variant="outline"
                  className={
                    trip.status === "ACTIVE"
                      ? "bg-success/10 text-success border-success/20"
                      : "bg-muted text-muted-foreground"
                  }
                >
                  {trip.status === "COMPLETED" ? "ENDED" : trip.status}
                </Badge>
              </div>

              <div className="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-4">
                <div className="rounded-lg bg-background/80 p-3 border border-border/50 print:border">
                  <p className="text-[11px] uppercase tracking-wide text-muted-foreground flex items-center gap-1">
                    <Bus className="h-3 w-3" /> Fleet
                  </p>
                  <p className="mt-1 font-mono font-semibold">{trip.fleet_number || "—"}</p>
                </div>
                <div className="rounded-lg bg-background/80 p-3 border border-border/50 print:border">
                  <p className="text-[11px] uppercase tracking-wide text-muted-foreground flex items-center gap-1">
                    <UserRound className="h-3 w-3" /> Conductor
                  </p>
                  <p className="mt-1 font-medium text-sm">{trip.agent_name || "—"}</p>
                </div>
                <div className="rounded-lg bg-background/80 p-3 border border-border/50 print:border">
                  <p className="text-[11px] uppercase tracking-wide text-muted-foreground">Started</p>
                  <p className="mt-1 text-sm">{new Date(trip.started_at).toLocaleString()}</p>
                </div>
                <div className="rounded-lg bg-background/80 p-3 border border-border/50 print:border">
                  <p className="text-[11px] uppercase tracking-wide text-muted-foreground">Ended</p>
                  <p className="mt-1 text-sm">
                    {trip.ended_at ? new Date(trip.ended_at).toLocaleString() : "Still active"}
                  </p>
                </div>
              </div>
            </div>

            {loading ? (
              <div className="flex items-center justify-center py-12 text-muted-foreground">
                <Loader2 className="mr-2 h-5 w-5 animate-spin" />
                Loading tickets…
              </div>
            ) : error ? (
              <p className="text-sm text-destructive">{error}</p>
            ) : (
              <>
                <div className="flex flex-wrap gap-2">
                  <Badge variant="secondary" className="px-3 py-1.5">
                    {validTickets.length} tickets
                  </Badge>
                  {revenueByCurrency.map(([currency, amount]) => (
                    <Badge key={currency} variant="outline" className="px-3 py-1.5 font-mono gap-1.5">
                      <Banknote className="h-3.5 w-3.5" />
                      {currency} {amount.toFixed(2)}
                    </Badge>
                  ))}
                </div>

                <div className="overflow-x-auto rounded-xl border border-border/60 print:border">
                  <table className="w-full text-sm">
                    <thead className="bg-muted/50 text-left text-xs uppercase tracking-wider text-muted-foreground">
                      <tr>
                        <th className="px-3 py-2.5 font-semibold">#</th>
                        <th className="px-3 py-2.5 font-semibold">Category</th>
                        <th className="px-3 py-2.5 font-semibold">Segment</th>
                        <th className="px-3 py-2.5 font-semibold text-right">Amount</th>
                        <th className="px-3 py-2.5 font-semibold">Issued</th>
                      </tr>
                    </thead>
                    <tbody>
                      {validTickets.length === 0 ? (
                        <tr>
                          <td colSpan={5} className="px-3 py-8 text-center text-muted-foreground">
                            No tickets on this trip yet.
                          </td>
                        </tr>
                      ) : (
                        validTickets.map((ticket) => (
                          <tr key={ticket.id} className="border-t border-border/50">
                            <td className="px-3 py-2.5 font-mono font-medium">
                              {ticket.serial_number ?? "—"}
                            </td>
                            <td className="px-3 py-2.5">{categoryLabel(ticket.ticket_category)}</td>
                            <td className="px-3 py-2.5 text-muted-foreground">
                              {ticket.departure && ticket.destination
                                ? `${ticket.departure} → ${ticket.destination}`
                                : ticket.route_label || "—"}
                            </td>
                            <td className="px-3 py-2.5 text-right font-mono font-semibold">
                              {ticket.currency} {Number(ticket.amount).toFixed(2)}
                            </td>
                            <td className="px-3 py-2.5 text-muted-foreground whitespace-nowrap">
                              {new Date(ticket.issued_at).toLocaleString()}
                            </td>
                          </tr>
                        ))
                      )}
                    </tbody>
                  </table>
                </div>

                <p className="text-xs text-muted-foreground print:mt-6">
                  Printed {new Date().toLocaleString()} · CountryBoy cashier batch
                </p>
              </>
            )}
          </div>
        </div>

        <div className="flex flex-col-reverse gap-2 border-t border-border/60 px-4 py-3 sm:flex-row sm:justify-end sm:px-6 print:hidden">
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Close
          </Button>
          <Button onClick={handlePrint} disabled={loading || !!error} className="gap-2">
            <Printer className="h-4 w-4" />
            Print batch
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
};

export default TripBatchPrintDialog;

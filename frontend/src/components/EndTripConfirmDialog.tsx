import { Bus, Loader2, Ticket, UserRound, Wallet } from "lucide-react";
import {
  AlertDialog,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { Button } from "@/components/ui/button";

export type EndTripSummary = {
  fleet_number?: string | null;
  origin?: string | null;
  destination?: string | null;
  route_label?: string | null;
  agent_name?: string | null;
  ticket_count?: number | null;
  revenue_label?: string | null;
};

interface EndTripConfirmDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  trip: EndTripSummary | null;
  loading?: boolean;
  onConfirm: () => void;
}

const EndTripConfirmDialog = ({
  open,
  onOpenChange,
  trip,
  loading = false,
  onConfirm,
}: EndTripConfirmDialogProps) => {
  if (!trip) return null;

  const corridor =
    trip.route_label ||
    [trip.origin, trip.destination].filter(Boolean).join(" → ") ||
    "This trip";

  return (
    <AlertDialog
      open={open}
      onOpenChange={(next) => {
        if (loading) return;
        onOpenChange(next);
      }}
    >
      <AlertDialogContent className="max-w-md gap-0 overflow-hidden p-0">
        <div className="border-b border-border/70 bg-gradient-to-br from-amber-500/10 via-background to-background px-6 py-5">
          <AlertDialogHeader className="space-y-2 text-left">
            <AlertDialogTitle className="text-xl tracking-tight">End this trip?</AlertDialogTitle>
            <AlertDialogDescription className="text-sm leading-relaxed">
              Closing stops new ticket sales on this bus. Ticket history stays available for
              reprint and reports.
            </AlertDialogDescription>
          </AlertDialogHeader>
        </div>

        <div className="space-y-3 px-6 py-5">
          <div className="rounded-xl border border-border/80 bg-muted/25 px-4 py-3.5">
            <p className="text-[11px] font-semibold uppercase tracking-wide text-muted-foreground">
              Corridor
            </p>
            <p className="mt-1 text-base font-semibold leading-snug">{corridor}</p>
          </div>

          <div className="grid grid-cols-2 gap-2.5">
            <div className="rounded-xl border border-border/80 bg-muted/15 p-3">
              <div className="mb-1 flex items-center gap-1.5 text-[11px] uppercase tracking-wide text-muted-foreground">
                <Bus className="h-3.5 w-3.5" /> Bus
              </div>
              <p className="font-mono text-sm font-semibold">{trip.fleet_number || "—"}</p>
            </div>
            <div className="rounded-xl border border-border/80 bg-muted/15 p-3">
              <div className="mb-1 flex items-center gap-1.5 text-[11px] uppercase tracking-wide text-muted-foreground">
                <UserRound className="h-3.5 w-3.5" /> Conductor
              </div>
              <p className="truncate text-sm font-semibold">{trip.agent_name || "—"}</p>
            </div>
            <div className="rounded-xl border border-border/80 bg-muted/15 p-3">
              <div className="mb-1 flex items-center gap-1.5 text-[11px] uppercase tracking-wide text-muted-foreground">
                <Ticket className="h-3.5 w-3.5" /> Tickets
              </div>
              <p className="text-sm font-semibold tabular-nums">{trip.ticket_count ?? 0}</p>
            </div>
            <div className="rounded-xl border border-border/80 bg-muted/15 p-3">
              <div className="mb-1 flex items-center gap-1.5 text-[11px] uppercase tracking-wide text-muted-foreground">
                <Wallet className="h-3.5 w-3.5" /> Revenue
              </div>
              <p className="truncate text-sm font-semibold tabular-nums">
                {trip.revenue_label || "—"}
              </p>
            </div>
          </div>
        </div>

        <AlertDialogFooter className="border-t border-border/70 bg-muted/20 px-6 py-4 sm:space-x-2">
          <AlertDialogCancel disabled={loading}>Keep trip open</AlertDialogCancel>
          <Button
            variant="destructive"
            disabled={loading}
            className="gap-2"
            onClick={(e) => {
              e.preventDefault();
              onConfirm();
            }}
          >
            {loading ? (
              <>
                <Loader2 className="h-4 w-4 animate-spin" />
                Ending…
              </>
            ) : (
              "End trip"
            )}
          </Button>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
};

export default EndTripConfirmDialog;

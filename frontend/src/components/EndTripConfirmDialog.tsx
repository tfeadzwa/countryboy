import { useEffect, useState } from "react";
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
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";

export type EndTripSummary = {
  fleet_number?: string | null;
  origin?: string | null;
  destination?: string | null;
  route_label?: string | null;
  agent_name?: string | null;
  ticket_count?: number | null;
  revenue_label?: string | null;
  conductor_presence?: "online" | "offline" | "signed_out" | null;
  conductor_is_online?: boolean | null;
  starting_mileage?: number | null;
  waybill_no?: string | null;
};

interface EndTripConfirmDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  trip: EndTripSummary | null;
  loading?: boolean;
  /** Super-admin ending while conductor is offline. */
  forceMode?: boolean;
  /** When false, confirm is hidden (cashier + offline). */
  canConfirm?: boolean;
  onConfirm: (closingMileage: number) => void;
}

const presenceLabel = (trip: EndTripSummary) => {
  if (trip.conductor_is_online || trip.conductor_presence === "online") {
    return { label: "Online", className: "text-emerald-700" };
  }
  if (trip.conductor_presence === "signed_out") {
    return { label: "Signed out", className: "text-slate-600" };
  }
  return { label: "Offline", className: "text-amber-800" };
};

const EndTripConfirmDialog = ({
  open,
  onOpenChange,
  trip,
  loading = false,
  forceMode = false,
  canConfirm = true,
  onConfirm,
}: EndTripConfirmDialogProps) => {
  const [closingMileage, setClosingMileage] = useState("");
  const [mileageError, setMileageError] = useState<string | null>(null);

  useEffect(() => {
    if (open) {
      setClosingMileage("");
      setMileageError(null);
    }
  }, [open, trip?.waybill_no, trip?.starting_mileage]);

  if (!trip) return null;

  const corridor =
    trip.route_label ||
    [trip.origin, trip.destination].filter(Boolean).join(" → ") ||
    "This trip";
  const presence = presenceLabel(trip);
  const starting = trip.starting_mileage;

  const validateClosing = (): number | null => {
    const raw = closingMileage.trim();
    if (!raw) {
      setMileageError("Closing mileage is required");
      return null;
    }
    const n = Number(raw);
    if (!Number.isInteger(n) || n < 0) {
      setMileageError("Enter a whole number of 0 or greater");
      return null;
    }
    if (starting != null && n < starting) {
      setMileageError(`Must be at least the starting mileage (${starting})`);
      return null;
    }
    setMileageError(null);
    return n;
  };

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
            <AlertDialogTitle className="text-xl tracking-tight">
              {canConfirm
                ? forceMode
                  ? "Force-end this trip?"
                  : "End this trip?"
                : "Cannot end trip yet"}
            </AlertDialogTitle>
            <AlertDialogDescription className="text-sm leading-relaxed">
              {canConfirm
                ? forceMode
                  ? "The conductor is offline. Ending now may leave unsynced tickets stranded. Only use this if the device is abandoned."
                  : "Closing stops new ticket sales on this bus. Enter the closing odometer reading to finish."
                : "The conductor must be online before this trip can be closed, so any tickets issued offline can sync first."}
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
              <p className={`mt-0.5 text-[11px] font-semibold ${presence.className}`}>
                {presence.label}
              </p>
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

          <div className="grid grid-cols-2 gap-2.5">
            <div className="rounded-xl border border-border/80 bg-muted/15 p-3">
              <p className="text-[11px] uppercase tracking-wide text-muted-foreground">
                Starting mileage
              </p>
              <p className="mt-1 text-sm font-semibold tabular-nums">
                {starting != null ? `${starting} km` : "—"}
              </p>
            </div>
            <div className="rounded-xl border border-border/80 bg-muted/15 p-3">
              <p className="text-[11px] uppercase tracking-wide text-muted-foreground">
                Waybill No
              </p>
              <p className="mt-1 font-mono text-sm font-semibold">
                {trip.waybill_no || "—"}
              </p>
            </div>
          </div>

          {canConfirm && (
            <div className="space-y-2 pt-1">
              <Label htmlFor="closing-mileage" className="text-xs font-semibold">
                Closing mileage (km) *
              </Label>
              <Input
                id="closing-mileage"
                type="number"
                min={starting ?? 0}
                step={1}
                inputMode="numeric"
                value={closingMileage}
                disabled={loading}
                placeholder={
                  starting != null ? `At least ${starting}` : "Odometer reading"
                }
                onChange={(e) => {
                  setClosingMileage(e.target.value);
                  setMileageError(null);
                }}
                className="h-10"
              />
              {mileageError && (
                <p className="text-xs text-destructive">{mileageError}</p>
              )}
            </div>
          )}
        </div>

        <AlertDialogFooter className="border-t border-border/70 bg-muted/20 px-6 py-4 sm:space-x-2">
          <AlertDialogCancel disabled={loading}>
            {canConfirm ? "Keep trip open" : "Close"}
          </AlertDialogCancel>
          {canConfirm && (
            <Button
              variant="destructive"
              disabled={loading}
              className="gap-2"
              onClick={(e) => {
                e.preventDefault();
                const mileage = validateClosing();
                if (mileage == null) return;
                onConfirm(mileage);
              }}
            >
              {loading ? (
                <>
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Ending…
                </>
              ) : forceMode ? (
                "Force end trip"
              ) : (
                "End trip"
              )}
            </Button>
          )}
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
};

export default EndTripConfirmDialog;

import { Bus, Clock, MapPin, Route, User, UserRound, ExternalLink } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import type { Agent, AgentActiveTrip } from "@/types";
import { useNavigate } from "react-router-dom";

interface ConductorTripDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  agent: Agent | null;
}

const formatWhen = (value?: string | null) => {
  if (!value) return "—";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "—";
  return date.toLocaleString();
};

const TripDetails = ({ trip }: { trip: AgentActiveTrip }) => (
  <div className="space-y-3">
    <div className="rounded-lg border border-primary/20 bg-primary/5 p-3">
      <div className="flex items-center gap-2 text-xs font-medium uppercase tracking-wide text-primary mb-1.5">
        <Route className="h-3.5 w-3.5" />
        Active trip
      </div>
      <p className="text-base font-semibold">
        {trip.origin} → {trip.destination}
      </p>
      <p className="text-xs text-muted-foreground mt-1">
        Started {formatWhen(trip.started_at)}
        {trip.started_offline ? " · started offline" : ""}
      </p>
    </div>

    <div className="grid grid-cols-2 gap-2.5 text-sm">
      <div className="rounded-lg border border-border/80 bg-muted/20 p-3">
        <div className="flex items-center gap-1.5 text-[11px] uppercase tracking-wide text-muted-foreground mb-1">
          <Bus className="h-3.5 w-3.5" /> Bus
        </div>
        <p className="font-semibold font-mono">{trip.fleet_number || "—"}</p>
      </div>
      <div className="rounded-lg border border-border/80 bg-muted/20 p-3">
        <div className="flex items-center gap-1.5 text-[11px] uppercase tracking-wide text-muted-foreground mb-1">
          <UserRound className="h-3.5 w-3.5" /> Driver
        </div>
        <p className="font-semibold">{trip.driver_name || "Not assigned"}</p>
      </div>
      {(trip.route_origin || trip.route_destination) && (
        <div className="rounded-lg border border-border/80 bg-muted/20 p-3 col-span-2">
          <div className="flex items-center gap-1.5 text-[11px] uppercase tracking-wide text-muted-foreground mb-1">
            <MapPin className="h-3.5 w-3.5" /> Catalog route
          </div>
          <p className="font-semibold">
            {trip.route_origin || "—"} → {trip.route_destination || "—"}
          </p>
        </div>
      )}
    </div>
  </div>
);

const ConductorTripDialog = ({ open, onOpenChange, agent }: ConductorTripDialogProps) => {
  const navigate = useNavigate();
  if (!agent) return null;

  const online = agent.is_online || agent.conductor_status === "online";
  const presenceLabel = agent.conductor_status
    ? online
      ? "Online"
      : "Offline"
    : "Signed out";

  const openTripPage = () => {
    if (!agent.active_trip?.id) return;
    onOpenChange(false);
    navigate(`/trips/${agent.active_trip.id}`);
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[480px] gap-0 p-0 overflow-hidden">
        <DialogHeader className="px-6 pt-6 pb-4 border-b border-border/60 space-y-3">
          <div className="flex items-start gap-3">
            <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-secondary/10">
              <User className="h-5 w-5 text-secondary" />
            </div>
            <div className="min-w-0 flex-1">
              <DialogTitle className="text-left text-lg leading-tight">{agent.full_name}</DialogTitle>
              <DialogDescription className="text-left font-mono text-sm mt-1">
                {agent.agent_code} · {agent.depot_name || "No depot"}
              </DialogDescription>
            </div>
            <Badge
              className={`shrink-0 text-xs uppercase tracking-wide ${
                online
                  ? "bg-success/10 text-success border border-success/20"
                  : "bg-muted text-muted-foreground border border-border"
              }`}
            >
              {presenceLabel}
            </Badge>
          </div>
        </DialogHeader>

        <div className="px-6 py-4 space-y-4 max-h-[min(60vh,480px)] overflow-y-auto">
          <div className="grid grid-cols-2 gap-2 text-sm">
            <div className="rounded-lg border border-border/80 bg-muted/20 p-3">
              <p className="text-[11px] uppercase tracking-wide text-muted-foreground mb-1">Account</p>
              <p className="font-semibold">{agent.status}</p>
            </div>
            <div className="rounded-lg border border-border/80 bg-muted/20 p-3">
              <div className="flex items-center gap-1.5 text-[11px] uppercase tracking-wide text-muted-foreground mb-1">
                <Clock className="h-3.5 w-3.5" /> Last seen
              </div>
              <p className="font-semibold text-sm">{formatWhen(agent.last_seen)}</p>
            </div>
          </div>

          {agent.active_session && (
            <p className="text-xs text-muted-foreground">
              Signed in on device{" "}
              <span className="font-mono">{agent.active_session.device_serial || agent.active_session.device_id}</span>
              {" · "}
              since {formatWhen(agent.active_session.started_at)}
            </p>
          )}

          {agent.active_trip ? (
            <>
              <TripDetails trip={agent.active_trip} />
              <Button className="w-full gap-2" onClick={openTripPage}>
                <ExternalLink className="h-4 w-4" />
                Open full trip page
              </Button>
            </>
          ) : (
            <div className="rounded-lg border border-dashed border-border/80 p-6 text-center">
              <Bus className="h-8 w-8 mx-auto text-muted-foreground mb-2" />
              <p className="text-sm font-medium">No active trip</p>
              <p className="text-xs text-muted-foreground mt-1">
                This conductor is not currently assigned to a trip.
              </p>
            </div>
          )}
        </div>

        <DialogFooter className="px-6 py-4 border-t border-border/60 bg-muted/20">
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Close
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};

export default ConductorTripDialog;

import { useState, useEffect } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Checkbox } from "@/components/ui/checkbox";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { MapPin, Loader2, AlertCircle } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { routeService } from "@/lib/api/route.service";
import { depotService } from "@/lib/api/depot.service";
import { useAuth } from "@/contexts/AuthContext";
import { isSuperAdmin } from "@/lib/permissions";
import RouteLinkPicker from "@/components/RouteLinkPicker";
import RouteFareFields, { emptyFare, type FareDraft } from "@/components/RouteFareFields";
import { fareService } from "@/lib/api/fare.service";
import { validateTicketFareAmount } from "@/lib/constants/currencies";
import type { Depot, RouteInfo } from "@/types";

interface AddRouteDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSuccess?: () => void;
}

const AddRouteDialog = ({ open, onOpenChange, onSuccess }: AddRouteDialogProps) => {
  const { user } = useAuth();
  const [origin, setOrigin] = useState("");
  const [destination, setDestination] = useState("");
  const [isActive, setIsActive] = useState(true);
  const [distanceKm, setDistanceKm] = useState("");
  const [childRouteIds, setChildRouteIds] = useState<string[]>([]);
  const [fares, setFares] = useState<FareDraft[]>([emptyFare()]);
  const [selectedDepotId, setSelectedDepotId] = useState("");
  const [depots, setDepots] = useState<Depot[]>([]);
  const [allRoutes, setAllRoutes] = useState<RouteInfo[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const { toast } = useToast();

  const isSuperAdminUser = user ? isSuperAdmin(user.roles || []) : false;

  useEffect(() => {
    const loadData = async () => {
      if (!open) return;

      if (isSuperAdminUser) {
        try {
          const depotList = await depotService.getAll();
          setDepots(depotList);
          if (depotList.length > 0 && !selectedDepotId) {
            setSelectedDepotId(depotList[0].id);
          }
        } catch (err) {
          console.error("Failed to load depots:", err);
        }
      }

      try {
        const routes = await routeService.getAll();
        setAllRoutes(routes);
      } catch (err) {
        console.error("Failed to load routes:", err);
      }
    };
    loadData();
  }, [isSuperAdminUser, open, selectedDepotId]);

  useEffect(() => {
    if (!open) {
      setOrigin("");
      setDestination("");
      setIsActive(true);
      setDistanceKm("");
      setChildRouteIds([]);
      setFares([emptyFare()]);
      setSelectedDepotId("");
      setError(null);
    }
  }, [open]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!origin.trim() || !destination.trim()) {
      setError("Both origin and destination are required");
      return;
    }

    if (isSuperAdminUser && !selectedDepotId) {
      setError("Please select a depot");
      return;
    }

    const fareRows = fares
      .map((fare) => ({
        currency: fare.currency.trim().toUpperCase(),
        amount: parseFloat(fare.amount),
      }))
      .filter((fare) => fare.currency && !Number.isNaN(fare.amount) && fare.amount > 0);

    const currencies = fareRows.map((fare) => fare.currency);
    if (new Set(currencies).size !== currencies.length) {
      setError("Each currency can only be added once per route.");
      return;
    }

    for (const fare of fareRows) {
      const fareError = validateTicketFareAmount(fare.currency, fare.amount);
      if (fareError) {
        setError(`${fare.currency}: ${fareError}`);
        return;
      }
    }

    setLoading(true);

    try {
      const depotId = isSuperAdminUser ? selectedDepotId : undefined;
      const createdRoute = await routeService.create(
        {
          origin: origin.trim(),
          destination: destination.trim(),
          child_route_ids: childRouteIds,
          is_active: isActive,
          distance_km: distanceKm ? parseFloat(distanceKm) : undefined,
        },
        depotId,
      );

      const fareErrors: string[] = [];
      for (const fare of fareRows) {
        try {
          await fareService.create(
            { route_id: createdRoute.id, currency: fare.currency, amount: fare.amount },
            depotId,
          );
        } catch (err) {
          const message = err instanceof Error ? err.message : "Failed to save fare";
          fareErrors.push(`${fare.currency}: ${message}`);
        }
      }

      toast({
        title: "Route Added!",
        description:
          fareErrors.length > 0
            ? `Route ${origin} → ${destination} created, but some fares failed: ${fareErrors.join("; ")}`
            : `Route ${origin} → ${destination}${fareRows.length > 0 ? " with fares" : ""} created successfully.`,
      });

      onSuccess?.();
      onOpenChange(false);
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : "Failed to save route";
      if (errorMessage.includes("Depot context")) {
        setError("Unable to save route. Please try again.");
      } else if (errorMessage.includes("duplicate") || errorMessage.includes("already exists")) {
        setError("A route with this origin and destination already exists in this depot.");
      } else {
        setError(errorMessage);
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[560px] max-h-[90vh] overflow-y-auto">
        <DialogHeader className="space-y-1">
          <div className="mx-auto flex h-10 w-10 items-center justify-center rounded-full bg-primary/10">
            <MapPin className="h-5 w-5 text-primary" />
          </div>
          <DialogTitle className="text-center">Add New Route</DialogTitle>
          <DialogDescription className="text-center text-xs">
            Create a route, set fares, and link child segments in one step.
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          {error && (
            <Alert variant="destructive" className="py-2">
              <AlertCircle className="h-4 w-4" />
              <AlertDescription className="text-sm">{error}</AlertDescription>
            </Alert>
          )}

          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1.5">
              <Label htmlFor="origin" className="text-sm">Origin</Label>
              <Input
                id="origin"
                placeholder="e.g. Harare"
                value={origin}
                onChange={(e) => setOrigin(e.target.value)}
                required
                disabled={loading}
                className="h-9"
              />
            </div>

            <div className="space-y-1.5">
              <Label htmlFor="destination" className="text-sm">Destination</Label>
              <Input
                id="destination"
                placeholder="e.g. Beitbridge"
                value={destination}
                onChange={(e) => setDestination(e.target.value)}
                required
                disabled={loading}
                className="h-9"
              />
            </div>
          </div>

          <div className="grid grid-cols-[1fr_auto] gap-3 items-end">
            <div className="space-y-1.5">
              <Label htmlFor="distance" className="text-sm">Distance (km)</Label>
              <Input
                id="distance"
                type="number"
                step="0.1"
                min="0"
                placeholder="e.g. 580"
                value={distanceKm}
                onChange={(e) => setDistanceKm(e.target.value)}
                disabled={loading}
                className="h-9"
              />
            </div>

            <div className="flex items-center space-x-2 pb-0.5">
              <Checkbox
                id="is_active"
                checked={isActive}
                onCheckedChange={(checked) => setIsActive(checked as boolean)}
                disabled={loading}
              />
              <Label htmlFor="is_active" className="text-sm font-normal cursor-pointer whitespace-nowrap">
                Active
              </Label>
            </div>
          </div>

          {isSuperAdminUser && (
            <div className="space-y-1.5">
              <Label htmlFor="depot" className="text-sm">Assign to Depot</Label>
              <Select value={selectedDepotId} onValueChange={setSelectedDepotId} required disabled={loading}>
                <SelectTrigger id="depot" className="h-9">
                  <SelectValue placeholder="Select a depot" />
                </SelectTrigger>
                <SelectContent>
                  {depots.map((d) => (
                    <SelectItem key={d.id} value={d.id}>
                      {d.name} — {d.location}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          )}

          <RouteFareFields
            fares={fares}
            onChange={setFares}
            disabled={loading}
          />

          <RouteLinkPicker
            label="Child routes"
            description="Search and add existing routes as segments under this route (e.g. Harare → Masvingo under Harare → Beitbridge)."
            routes={allRoutes}
            selectedIds={childRouteIds}
            onChange={setChildRouteIds}
            depotId={isSuperAdminUser ? selectedDepotId : undefined}
            disabled={loading}
            emptyMessage="No other routes available yet. You can link segments later from the edit page."
          />

          <DialogFooter className="pt-2">
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)} disabled={loading}>
              Cancel
            </Button>
            <Button
              type="submit"
              disabled={loading || !origin.trim() || !destination.trim() || (isSuperAdminUser && !selectedDepotId)}
              className="gap-2"
            >
              {loading ? (
                <>
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Adding…
                </>
              ) : (
                "Add Route"
              )}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
};

export default AddRouteDialog;

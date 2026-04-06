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
import type { Depot, RouteInfo } from "@/types";

interface AddRouteDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSuccess?: () => void;
  route?: RouteInfo | null;
}

const AddRouteDialog = ({ open, onOpenChange, onSuccess, route }: AddRouteDialogProps) => {
  const { user } = useAuth();
  const [origin, setOrigin] = useState("");
  const [destination, setDestination] = useState("");
  const [isActive, setIsActive] = useState(true);
  const [distanceKm, setDistanceKm] = useState("");
  const [selectedDepotId, setSelectedDepotId] = useState("");
  const [depots, setDepots] = useState<Depot[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const { toast } = useToast();
  
  const isSuperAdminUser = user ? isSuperAdmin(user.roles || []) : false;
  const isEditing = !!route;

  // Load depots for SUPER_ADMIN or set initial values for editing
  useEffect(() => {
    const loadData = async () => {
      if (open) {
        if (isSuperAdminUser) {
          try {
            const depotList = await depotService.getAll();
            setDepots(depotList);
            if (route) {
              setSelectedDepotId(route.depot_id);
            } else if (depotList.length > 0 && !selectedDepotId) {
              setSelectedDepotId(depotList[0].id);
            }
          } catch (err) {
            console.error('Failed to load depots:', err);
          }
        }
        
        if (route) {
          setOrigin(route.origin);
          setDestination(route.destination);
          setIsActive(route.is_active);
          setDistanceKm(route.distance_km ? route.distance_km.toString() : "");
          setSelectedDepotId(route.depot_id);
        }
      }
    };
    loadData();
  }, [isSuperAdminUser, open, route, selectedDepotId]);

  // Reset form when closing
  useEffect(() => {
    if (!open) {
      setOrigin("");
      setDestination("");
      setIsActive(true);
      setDistanceKm("");
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

    setLoading(true);

    try {
      if (isEditing && route) {
        await routeService.update(
          route.id,
          { 
            origin: origin.trim(),
            destination: destination.trim(),
            is_active: isActive,
            distance_km: distanceKm ? parseFloat(distanceKm) : undefined
          },
          isSuperAdminUser ? selectedDepotId : undefined
        );
        toast({
          title: "Route Updated!",
          description: `Route ${origin} → ${destination} updated successfully.`,
        });
      } else {
        await routeService.create(
          { 
            origin: origin.trim(),
            destination: destination.trim(),
            is_active: isActive,
            distance_km: distanceKm ? parseFloat(distanceKm) : undefined
          },
          isSuperAdminUser ? selectedDepotId : undefined
        );
        toast({
          title: "Route Added!",
          description: `Route ${origin} → ${destination} created successfully.`,
        });
      }

      onSuccess?.();
      onOpenChange(false);
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to save route';
      if (errorMessage.includes('Depot context')) {
        setError('Unable to save route. Please try again.');
      } else if (errorMessage.includes('duplicate') || errorMessage.includes('already exists')) {
        setError('A route with this origin and destination already exists in this depot.');
      } else {
        setError(errorMessage);
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[540px] max-h-[85vh] overflow-y-auto">
        <DialogHeader className="space-y-1">
          <div className="mx-auto flex h-10 w-10 items-center justify-center rounded-full bg-primary/10">
            <MapPin className="h-5 w-5 text-primary" />
          </div>
          <DialogTitle className="text-center">
            {isEditing ? "Edit Route" : "Add New Route"}
          </DialogTitle>
          <DialogDescription className="text-center text-xs">
            {isEditing ? "Update route information" : "Create a new route between two locations"}
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-3">
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
                placeholder="e.g. Bulawayo"
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
                placeholder="e.g. 450"
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
                Route is currently active
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
                  {isEditing ? "Updating…" : "Adding…"}
                </>
              ) : (
                isEditing ? "Update Route" : "Add Route"
              )}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
};

export default AddRouteDialog;

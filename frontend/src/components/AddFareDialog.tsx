import { useState, useEffect } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { DollarSign, Loader2, AlertCircle } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { fareService } from "@/lib/api/fare.service";
import { routeService } from "@/lib/api/route.service";
import { depotService } from "@/lib/api/depot.service";
import { useAuth } from "@/contexts/AuthContext";
import { isSuperAdmin } from "@/lib/permissions";
import type { Depot, RouteInfo, Fare } from "@/types";

interface AddFareDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSuccess?: () => void;
  fare?: Fare | null;
}

const CURRENCY_OPTIONS = [
  { value: 'USD', label: 'USD ($)' },
  { value: 'ZWL', label: 'ZWL (Z$)' },
  { value: 'ZAR', label: 'ZAR (R)' },
];

const AddFareDialog = ({ open, onOpenChange, onSuccess, fare }: AddFareDialogProps) => {
  const { user } = useAuth();
  const [routeId, setRouteId] = useState("");
  const [currency, setCurrency] = useState("USD");
  const [amount, setAmount] = useState("");
  const [selectedDepotId, setSelectedDepotId] = useState("");
  const [depots, setDepots] = useState<Depot[]>([]);
  const [routes, setRoutes] = useState<RouteInfo[]>([]);
  const [loading, setLoading] = useState(false);
  const [loadingRoutes, setLoadingRoutes] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const { toast } = useToast();
  
  const isSuperAdminUser = user ? isSuperAdmin(user.roles || []) : false;
  const isEditing = !!fare;

  // Load depots for SUPER_ADMIN
  useEffect(() => {
    const loadDepots = async () => {
      if (open && isSuperAdminUser) {
        try {
          const depotList = await depotService.getAll();
          setDepots(depotList);
          if (fare) {
            setSelectedDepotId(fare.depot_id);
          } else if (depotList.length > 0 && !selectedDepotId) {
            setSelectedDepotId(depotList[0].id);
          }
        } catch (err) {
          console.error('Failed to load depots:', err);
        }
      }
    };
    loadDepots();
  }, [isSuperAdminUser, open, fare, selectedDepotId]);

  // Load routes when dialog opens or depot changes
  useEffect(() => {
    const loadRoutes = async () => {
      if (open) {
        setLoadingRoutes(true);
        try {
          const routeList = await routeService.getAll();
          setRoutes(routeList);
          
          if (fare) {
            setRouteId(fare.route_id);
            setCurrency(fare.currency);
            setAmount(fare.amount.toString());
            setSelectedDepotId(fare.depot_id);
          }
        } catch (err) {
          console.error('Failed to load routes:', err);
          setError('Failed to load routes');
        } finally {
          setLoadingRoutes(false);
        }
      }
    };
    loadRoutes();
  }, [open, fare]);

  // Reset form when closing
  useEffect(() => {
    if (!open) {
      setRouteId("");
      setCurrency("USD");
      setAmount("");
      setSelectedDepotId("");
      setError(null);
    }
  }, [open]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!routeId) {
      setError("Please select a route");
      return;
    }

    if (!amount || parseFloat(amount) <= 0) {
      setError("Please enter a valid fare amount");
      return;
    }

    if (isSuperAdminUser && !selectedDepotId) {
      setError("Please select a depot");
      return;
    }

    setLoading(true);

    try {
      if (isEditing && fare) {
        await fareService.update(
          fare.id,
          { 
            currency,
            amount: parseFloat(amount)
          },
          isSuperAdminUser ? selectedDepotId : undefined
        );
        toast({
          title: "Fare Updated!",
          description: `Fare updated successfully.`,
        });
      } else {
        await fareService.create(
          { 
            route_id: routeId,
            currency,
            amount: parseFloat(amount)
          },
          isSuperAdminUser ? selectedDepotId : undefined
        );
        toast({
          title: "Fare Added!",
          description: `Fare for ${currency} ${amount} created successfully.`,
        });
      }

      onSuccess?.();
      onOpenChange(false);
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to save fare';
      if (errorMessage.includes('Depot context')) {
        setError('Unable to save fare. Please try again.');
      } else if (errorMessage.includes('duplicate') || errorMessage.includes('already exists')) {
        setError('A fare for this route already exists.');
      } else {
        setError(errorMessage);
      }
    } finally {
      setLoading(false);
    }
  };

  const selectedRoute = routes.find(r => r.id === routeId);

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[540px] max-h-[85vh] overflow-y-auto">
        <DialogHeader className="space-y-1">
          <div className="mx-auto flex h-10 w-10 items-center justify-center rounded-full bg-primary/10">
            <DollarSign className="h-5 w-5 text-primary" />
          </div>
          <DialogTitle className="text-center">
            {isEditing ? "Edit Fare" : "Add New Fare"}
          </DialogTitle>
          <DialogDescription className="text-center text-xs">
            {isEditing ? "Update fare pricing" : "Set pricing for a route"}
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-3">
          {error && (
            <Alert variant="destructive" className="py-2">
              <AlertCircle className="h-4 w-4" />
              <AlertDescription className="text-sm">{error}</AlertDescription>
            </Alert>
          )}

          {isSuperAdminUser && (
            <div className="space-y-1.5">
              <Label htmlFor="depot" className="text-sm">Depot</Label>
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

          <div className="space-y-1.5">
            <Label htmlFor="route" className="text-sm">Route</Label>
            <Select value={routeId} onValueChange={setRouteId} required disabled={loading || loadingRoutes || isEditing}>
              <SelectTrigger id="route" className="h-9">
                <SelectValue placeholder={loadingRoutes ? "Loading routes..." : "Select a route"} />
              </SelectTrigger>
              <SelectContent>
                {routes.map((r) => (
                  <SelectItem key={r.id} value={r.id}>
                    {r.origin} → {r.destination}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
            {selectedRoute && (
              <p className="text-xs text-muted-foreground">
                {selectedRoute.depot_name}
              </p>
            )}
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div className="space-y-1.5">
              <Label htmlFor="currency" className="text-sm">Currency</Label>
              <Select value={currency} onValueChange={setCurrency} required disabled={loading}>
                <SelectTrigger id="currency" className="h-9">
                  <SelectValue placeholder="Currency" />
                </SelectTrigger>
                <SelectContent>
                  {CURRENCY_OPTIONS.map((c) => (
                    <SelectItem key={c.value} value={c.value}>
                      {c.label}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-1.5">
              <Label htmlFor="amount" className="text-sm">Amount</Label>
              <Input
                id="amount"
                type="number"
                step="0.01"
                min="0"
                placeholder="0.00"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                required
                disabled={loading}
                className="h-9"
              />
            </div>
          </div>

          <DialogFooter className="pt-2">
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)} disabled={loading}>
              Cancel
            </Button>
            <Button 
              type="submit" 
              disabled={loading || !routeId || !amount || (isSuperAdminUser && !selectedDepotId)} 
              className="gap-2"
            >
              {loading ? (
                <>
                  <Loader2 className="h-4 w-4 animate-spin" />
                  {isEditing ? "Updating…" : "Adding…"}
                </>
              ) : (
                isEditing ? "Update Fare" : "Add Fare"
              )}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
};

export default AddFareDialog;

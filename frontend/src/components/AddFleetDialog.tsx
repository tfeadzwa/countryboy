import { useState, useEffect } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Bus, Loader2, AlertCircle } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { fleetService } from "@/lib/api/fleet.service";
import { depotService } from "@/lib/api/depot.service";
import { useAuth } from "@/contexts/AuthContext";
import { isSuperAdmin } from "@/lib/permissions";
import type { Depot, Fleet } from "@/types";

interface AddFleetDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSuccess?: () => void;
  fleet?: Fleet | null;
}

const AddFleetDialog = ({ open, onOpenChange, onSuccess, fleet }: AddFleetDialogProps) => {
  const { user } = useAuth();
  const [fleetNumber, setFleetNumber] = useState("");
  const [status, setStatus] = useState<'ACTIVE' | 'MAINTENANCE' | 'OUT_OF_SERVICE' | 'RETIRED'>("ACTIVE");
  const [capacity, setCapacity] = useState("0");
  const [selectedDepotId, setSelectedDepotId] = useState("");
  const [depots, setDepots] = useState<Depot[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const { toast } = useToast();
  
  const isSuperAdminUser = user ? isSuperAdmin(user.roles || []) : false;
  const isEditing = !!fleet;

  // Load depots for SUPER_ADMIN or set initial values for editing
  useEffect(() => {
    const loadData = async () => {
      if (open) {
        if (isSuperAdminUser) {
          try {
            const depotList = await depotService.getAll();
            setDepots(depotList);
            if (fleet) {
              setSelectedDepotId(fleet.depot_id);
            } else if (depotList.length > 0 && !selectedDepotId) {
              setSelectedDepotId(depotList[0].id);
            }
          } catch (err) {
            console.error('Failed to load depots:', err);
          }
        }
        
        if (fleet) {
          setFleetNumber(fleet.number);
          setStatus(fleet.status);
          setCapacity(fleet.capacity.toString());
          setSelectedDepotId(fleet.depot_id);
        }
      }
    };
    loadData();
  }, [isSuperAdminUser, open, fleet, selectedDepotId]);

  // Reset form when closing
  useEffect(() => {
    if (!open) {
      setFleetNumber("");
      setStatus("ACTIVE");
      setCapacity("0");
      setSelectedDepotId("");
      setError(null);
    }
  }, [open]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!fleetNumber.trim()) {
      setError("Fleet number is required");
      return;
    }

    if (isSuperAdminUser && !selectedDepotId) {
      setError("Please select a depot");
      return;
    }

    setLoading(true);

    try {
      if (isEditing && fleet) {
        await fleetService.update(
          fleet.id,
          { 
            number: fleetNumber.trim(),
            status,
            capacity: parseInt(capacity)
          },
          isSuperAdminUser ? selectedDepotId : undefined
        );
        toast({
          title: "Fleet Updated!",
          description: `Fleet ${fleetNumber} updated successfully.`,
        });
      } else {
        await fleetService.create(
          { 
            number: fleetNumber.trim(),
            status,
            capacity: parseInt(capacity)
          },
          isSuperAdminUser ? selectedDepotId : undefined
        );
        toast({
          title: "Fleet Added!",
          description: `Fleet ${fleetNumber} registered successfully.`,
        });
      }

      onSuccess?.();
      onOpenChange(false);
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to save fleet';
      if (errorMessage.includes('Depot context')) {
        setError('Unable to save fleet. Please try again.');
      } else if (errorMessage.includes('duplicate') || errorMessage.includes('already exists')) {
        setError('A fleet with this number already exists in this depot.');
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
            <Bus className="h-5 w-5 text-primary" />
          </div>
          <DialogTitle className="text-center">
            {isEditing ? "Edit Fleet" : "Add New Fleet"}
          </DialogTitle>
          <DialogDescription className="text-center text-xs">
            {isEditing ? "Update fleet vehicle information" : "Register a new fleet vehicle to a depot"}
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
              <Label htmlFor="fleet-number" className="text-sm">Fleet Number</Label>
              <Input
                id="fleet-number"
                placeholder="e.g. BUS-001"
                value={fleetNumber}
                onChange={(e) => setFleetNumber(e.target.value)}
                required
                disabled={loading}
                className="h-9"
              />
            </div>

            <div className="space-y-1.5">
              <Label htmlFor="capacity" className="text-sm">Capacity</Label>
              <Input
                id="capacity"
                type="number"
                min="0"
                placeholder="e.g. 50"
                value={capacity}
                onChange={(e) => setCapacity(e.target.value)}
                required
                disabled={loading}
                className="h-9"
              />
            </div>
          </div>

          <div className={`grid ${isSuperAdminUser ? 'grid-cols-2' : 'grid-cols-1'} gap-3`}>
            <div className="space-y-1.5">
              <Label htmlFor="status" className="text-sm">Status</Label>
              <Select value={status} onValueChange={(val) => setStatus(val as any)} required disabled={loading}>
                <SelectTrigger id="status" className="h-9">
                  <SelectValue placeholder="Select status" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="ACTIVE">Active</SelectItem>
                  <SelectItem value="MAINTENANCE">Maintenance</SelectItem>
                  <SelectItem value="OUT_OF_SERVICE">Out of Service</SelectItem>
                  <SelectItem value="RETIRED">Retired</SelectItem>
                </SelectContent>
              </Select>
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
          </div>

          <DialogFooter className="pt-2">
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)} disabled={loading}>
              Cancel
            </Button>
            <Button 
              type="submit" 
              disabled={loading || !fleetNumber.trim() || (isSuperAdminUser && !selectedDepotId)} 
              className="gap-2"
            >
              {loading ? (
                <>
                  <Loader2 className="h-4 w-4 animate-spin" />
                  {isEditing ? "Updating…" : "Adding…"}
                </>
              ) : (
                isEditing ? "Update Fleet" : "Add Fleet"
              )}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
};

export default AddFleetDialog;

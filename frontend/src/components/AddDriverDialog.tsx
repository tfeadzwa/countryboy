import { useEffect, useState } from "react";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { AlertCircle, Loader2, UserRound } from "lucide-react";
import { driverService } from "@/lib/api/driver.service";
import { depotService } from "@/lib/api/depot.service";
import { useAuth } from "@/contexts/AuthContext";
import { isSuperAdmin } from "@/lib/permissions";
import type { Depot, Driver, DriverStatus } from "@/types";

interface AddDriverDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSuccess: () => void;
  driver?: Driver;
}

const AddDriverDialog = ({ open, onOpenChange, onSuccess, driver }: AddDriverDialogProps) => {
  const { user } = useAuth();
  const isEditMode = !!driver;
  const isSuperAdminUser = user ? isSuperAdmin(user.roles || []) : false;

  const [fullName, setFullName] = useState("");
  const [phone, setPhone] = useState("");
  const [licenceNumber, setLicenceNumber] = useState("");
  const [status, setStatus] = useState<DriverStatus>("ACTIVE");
  const [selectedDepotId, setSelectedDepotId] = useState("");
  const [depots, setDepots] = useState<Depot[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const initialize = async () => {
      if (!open) {
        setFullName("");
        setPhone("");
        setLicenceNumber("");
        setStatus("ACTIVE");
        setSelectedDepotId("");
        setError(null);
        return;
      }

      let depotList: Depot[] = [];
      if (isSuperAdminUser) {
        try {
          depotList = await depotService.getAll();
          setDepots(depotList);
        } catch {
          // Super admin can still type other fields; create will fail without depot.
        }
      }

      if (driver) {
        setFullName(driver.full_name);
        setPhone(driver.phone ?? "");
        setLicenceNumber(driver.licence_number ?? "");
        setStatus(driver.status);
        if (isSuperAdminUser && driver.depot_id) {
          setSelectedDepotId(driver.depot_id);
        }
      } else {
        setFullName("");
        setPhone("");
        setLicenceNumber("");
        setStatus("ACTIVE");
        if (isSuperAdminUser && depotList.length > 0) {
          setSelectedDepotId(depotList[0].id);
        }
      }
    };

    void initialize();
  }, [driver, open, isSuperAdminUser]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!fullName.trim()) {
      setError("Full name is required");
      return;
    }

    if (isSuperAdminUser && !selectedDepotId) {
      setError("Please select a depot for this driver");
      return;
    }

    setLoading(true);
    try {
      if (isEditMode && driver) {
        const payload: {
          full_name: string;
          phone: string | null;
          licence_number: string | null;
          status: DriverStatus;
          depot_id?: string;
        } = {
          full_name: fullName.trim(),
          phone: phone.trim() || null,
          licence_number: licenceNumber.trim() || null,
          status,
        };
        if (isSuperAdminUser && selectedDepotId && selectedDepotId !== driver.depot_id) {
          payload.depot_id = selectedDepotId;
        }
        const contextDepotId =
          isSuperAdminUser && selectedDepotId ? selectedDepotId : driver.depot_id;
        await driverService.update(driver.id, payload, contextDepotId);
      } else {
        await driverService.create(
          {
            full_name: fullName.trim(),
            phone: phone.trim() || null,
            licence_number: licenceNumber.trim() || null,
            status,
          },
          isSuperAdminUser ? selectedDepotId : undefined,
        );
      }
      onSuccess();
      onOpenChange(false);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Could not save driver");
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <UserRound className="h-5 w-5" />
            {isEditMode ? "Edit Driver" : "Add Driver"}
          </DialogTitle>
          <DialogDescription>
            Drivers are assigned to a depot and selected by conductors when starting a trip.
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          {error && (
            <Alert variant="destructive">
              <AlertCircle className="h-4 w-4" />
              <AlertDescription>{error}</AlertDescription>
            </Alert>
          )}

          {isSuperAdminUser && (
            <div className="space-y-2">
              <Label>Depot *</Label>
              <Select value={selectedDepotId} onValueChange={setSelectedDepotId}>
                <SelectTrigger>
                  <SelectValue placeholder="Select depot" />
                </SelectTrigger>
                <SelectContent>
                  {depots.map((depot) => (
                    <SelectItem key={depot.id} value={depot.id}>
                      {depot.name}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          )}

          <div className="space-y-2">
            <Label htmlFor="driver-full-name">Full name *</Label>
            <Input
              id="driver-full-name"
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              placeholder="e.g. Tendai Moyo"
              autoFocus
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="driver-phone">Phone</Label>
            <Input
              id="driver-phone"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              placeholder="Optional phone number"
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="driver-licence">Licence number</Label>
            <Input
              id="driver-licence"
              value={licenceNumber}
              onChange={(e) => setLicenceNumber(e.target.value)}
              placeholder="Optional licence number"
            />
          </div>

          <div className="space-y-2">
            <Label>Status</Label>
            <Select value={status} onValueChange={(v) => setStatus(v as DriverStatus)}>
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="ACTIVE">Active</SelectItem>
                <SelectItem value="INACTIVE">Inactive</SelectItem>
                <SelectItem value="SUSPENDED">Suspended</SelectItem>
              </SelectContent>
            </Select>
          </div>

          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)} disabled={loading}>
              Cancel
            </Button>
            <Button type="submit" disabled={loading}>
              {loading ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Saving…
                </>
              ) : isEditMode ? (
                "Save changes"
              ) : (
                "Add driver"
              )}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
};

export default AddDriverDialog;

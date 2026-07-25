import { useState, useEffect } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Separator } from "@/components/ui/separator";
import { Bus, Loader2, AlertCircle, ShieldCheck, CalendarDays } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { fleetService } from "@/lib/api/fleet.service";
import { depotService } from "@/lib/api/depot.service";
import { useAuth } from "@/contexts/AuthContext";
import { isSuperAdmin } from "@/lib/permissions";
import {
  FLEET_COMPLIANCE_FIELDS,
  emptyComplianceForm,
  type ComplianceFormState,
} from "@/lib/fleet-compliance";
import type { Depot } from "@/types";

interface AddFleetDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSuccess?: () => void;
}

const AddFleetDialog = ({ open, onOpenChange, onSuccess }: AddFleetDialogProps) => {
  const { user } = useAuth();
  const [fleetNumber, setFleetNumber] = useState("");
  const [registrationNumber, setRegistrationNumber] = useState("");
  const [status, setStatus] = useState<"ACTIVE" | "MAINTENANCE" | "OUT_OF_SERVICE" | "RETIRED">("ACTIVE");
  const [capacity, setCapacity] = useState("0");
  const [selectedDepotId, setSelectedDepotId] = useState("");
  const [depots, setDepots] = useState<Depot[]>([]);
  const [compliance, setCompliance] = useState<ComplianceFormState>(emptyComplianceForm());
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const { toast } = useToast();

  const isSuperAdminUser = user ? isSuperAdmin(user.roles || []) : false;

  useEffect(() => {
    if (!open) {
      setFleetNumber("");
      setRegistrationNumber("");
      setStatus("ACTIVE");
      setCapacity("0");
      setSelectedDepotId("");
      setCompliance(emptyComplianceForm());
      setError(null);
      setLoading(false);
    }
  }, [open]);

  useEffect(() => {
    if (!open || !isSuperAdminUser) return;

    let cancelled = false;
    (async () => {
      try {
        const depotList = await depotService.getAll();
        if (cancelled) return;
        setDepots(depotList);
        setSelectedDepotId((current) => current || depotList[0]?.id || "");
      } catch (err) {
        console.error("Failed to load depots:", err);
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [open, isSuperAdminUser]);

  const setComplianceField = (key: keyof ComplianceFormState, value: string) => {
    setCompliance((prev) => ({ ...prev, [key]: value }));
  };

  const validateCompliance = (): string | null => {
    for (const field of FLEET_COMPLIANCE_FIELDS) {
      const value = compliance[field.key]?.trim();
      if (value && Number.isNaN(new Date(value).getTime())) {
        return `${field.label} has an invalid expiry date`;
      }
    }
    return null;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!fleetNumber.trim()) {
      setError("Fleet number is required");
      return;
    }

    if (!registrationNumber.trim()) {
      setError("Registration number is required");
      return;
    }

    if (isSuperAdminUser && !selectedDepotId) {
      setError("Please select a depot");
      return;
    }

    const complianceError = validateCompliance();
    if (complianceError) {
      setError(complianceError);
      return;
    }

    setLoading(true);

    const payload = {
      number: fleetNumber.trim(),
      registration_number: registrationNumber.trim(),
      status,
      capacity: parseInt(capacity, 10) || 0,
      licence_disc_expiry: compliance.licence_disc_expiry || null,
      cof_expiry: compliance.cof_expiry || null,
      passenger_liability_expiry: compliance.passenger_liability_expiry || null,
      route_authority_expiry: compliance.route_authority_expiry || null,
      ppa_expiry: compliance.ppa_expiry || null,
    };

    try {
      await fleetService.create(payload, isSuperAdminUser ? selectedDepotId : undefined);
      toast({
        title: "Fleet Added!",
        description: `Fleet ${fleetNumber} registered successfully.`,
      });

      onSuccess?.();
      onOpenChange(false);
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : "Failed to save fleet";
      if (errorMessage.includes("Depot context")) {
        setError("Unable to save fleet. Please try again.");
      } else if (
        errorMessage.toLowerCase().includes("registration") &&
        (errorMessage.includes("duplicate") || errorMessage.includes("already exists"))
      ) {
        setError("A fleet with this registration number already exists in this depot.");
      } else if (errorMessage.includes("duplicate") || errorMessage.includes("already exists")) {
        setError("A fleet with this number already exists in this depot.");
      } else {
        setError(errorMessage);
      }
    } finally {
      setLoading(false);
    }
  };

  const canSubmit =
    !loading &&
    Boolean(fleetNumber.trim()) &&
    Boolean(registrationNumber.trim()) &&
    (!isSuperAdminUser || Boolean(selectedDepotId));

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[640px] max-h-[90vh] overflow-y-auto">
        <DialogHeader className="space-y-1">
          <div className="mx-auto flex h-10 w-10 items-center justify-center rounded-full bg-primary/10">
            <Bus className="h-5 w-5 text-primary" />
          </div>
          <DialogTitle className="text-center">Add New Fleet</DialogTitle>
          <DialogDescription className="text-center text-xs">
            Register a fleet vehicle and set compliance document expiry dates
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4">
          {error && (
            <Alert variant="destructive" className="py-2">
              <AlertCircle className="h-4 w-4" />
              <AlertDescription className="text-sm">{error}</AlertDescription>
            </Alert>
          )}

          <div className="space-y-3">
            <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
              Vehicle details
            </p>
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1.5">
                <Label htmlFor="fleet-number" className="text-sm">
                  Fleet Number
                </Label>
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
                <Label htmlFor="registration-number" className="text-sm">
                  Registration Number
                </Label>
                <Input
                  id="registration-number"
                  placeholder="e.g. ABC234"
                  value={registrationNumber}
                  onChange={(e) => setRegistrationNumber(e.target.value)}
                  required
                  disabled={loading}
                  className="h-9 font-mono uppercase"
                />
              </div>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1.5">
                <Label htmlFor="capacity" className="text-sm">
                  Capacity
                </Label>
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

              <div className="space-y-1.5">
                <Label htmlFor="status" className="text-sm">
                  Status
                </Label>
                <Select
                  value={status}
                  onValueChange={(val) => setStatus(val as typeof status)}
                  required
                  disabled={loading}
                >
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
            </div>

            {isSuperAdminUser && (
              <div className="space-y-1.5">
                <Label htmlFor="depot" className="text-sm">
                  Assign to Depot
                </Label>
                <Select
                  value={selectedDepotId || undefined}
                  onValueChange={setSelectedDepotId}
                  required
                  disabled={loading}
                >
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

          <Separator />

          <div className="space-y-3">
            <div className="flex items-start gap-2.5">
              <div className="h-8 w-8 rounded-lg bg-accent/10 flex items-center justify-center shrink-0">
                <ShieldCheck className="h-4 w-4 text-accent" />
              </div>
              <div>
                <p className="text-sm font-semibold text-foreground">Compliance documents</p>
                <p className="text-xs text-muted-foreground mt-0.5">
                  Expiry dates are optional and can be updated individually later. Alerts escalate
                  monthly → weekly → daily as expiry approaches.
                </p>
              </div>
            </div>

            <div className="rounded-xl border border-border/60 bg-muted/20 p-3 space-y-3">
              {FLEET_COMPLIANCE_FIELDS.map((field) => (
                <div
                  key={field.key}
                  className="grid grid-cols-1 sm:grid-cols-[1fr_auto] gap-2 sm:items-center"
                >
                  <div className="min-w-0">
                    <Label htmlFor={field.key} className="text-sm font-medium">
                      {field.label}
                    </Label>
                    <p className="text-[11px] text-muted-foreground/80 mt-0.5">{field.hint}</p>
                  </div>
                  <div className="relative sm:w-[180px]">
                    <CalendarDays className="absolute left-2.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-muted-foreground/60 pointer-events-none" />
                    <Input
                      id={field.key}
                      type="date"
                      value={compliance[field.key]}
                      onChange={(e) => setComplianceField(field.key, e.target.value)}
                      disabled={loading}
                      className="h-9 pl-8"
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>

          <DialogFooter className="pt-1">
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)} disabled={loading}>
              Cancel
            </Button>
            <Button type="submit" disabled={!canSubmit} className="gap-2">
              {loading ? (
                <>
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Adding…
                </>
              ) : (
                "Add Fleet"
              )}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
};

export default AddFleetDialog;

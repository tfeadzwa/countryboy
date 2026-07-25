import { useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { motion } from "framer-motion";
import {
  AlertCircle,
  ArrowLeft,
  Bus,
  CalendarDays,
  Loader2,
  Save,
  ShieldCheck,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Separator } from "@/components/ui/separator";
import ErrorAlert from "@/components/ErrorAlert";
import { useToast } from "@/hooks/use-toast";
import { useAuth } from "@/contexts/AuthContext";
import { isSuperAdmin } from "@/lib/permissions";
import { fleetService } from "@/lib/api/fleet.service";
import { depotService } from "@/lib/api/depot.service";
import {
  FLEET_COMPLIANCE_FIELDS,
  complianceFromFleet,
  type ComplianceFormState,
} from "@/lib/fleet-compliance";
import type { Depot, Fleet } from "@/types";

const statusBadgeClass: Record<Fleet["status"], string> = {
  ACTIVE: "bg-green-500/10 text-green-700 border-green-500/20",
  MAINTENANCE: "bg-yellow-500/10 text-yellow-700 border-yellow-500/20",
  OUT_OF_SERVICE: "bg-red-500/10 text-red-700 border-red-500/20",
  RETIRED: "bg-gray-500/10 text-gray-700 border-gray-500/20",
};

const EditFleetPage = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { user } = useAuth();
  const { toast } = useToast();

  const isSuperAdminUser = user ? isSuperAdmin(user.roles || []) : false;

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [saveError, setSaveError] = useState<string | null>(null);

  const [fleet, setFleet] = useState<Fleet | null>(null);
  const [depots, setDepots] = useState<Depot[]>([]);

  const [fleetNumber, setFleetNumber] = useState("");
  const [registrationNumber, setRegistrationNumber] = useState("");
  const [status, setStatus] = useState<Fleet["status"]>("ACTIVE");
  const [capacity, setCapacity] = useState("0");
  const [selectedDepotId, setSelectedDepotId] = useState("");
  const [compliance, setCompliance] = useState<ComplianceFormState>({
    licence_disc_expiry: "",
    cof_expiry: "",
    passenger_liability_expiry: "",
    route_authority_expiry: "",
    ppa_expiry: "",
  });

  useEffect(() => {
    const load = async () => {
      if (!id) return;
      setLoading(true);
      setLoadError(null);

      try {
        const [fleetData, depotData] = await Promise.all([
          fleetService.getOne(id),
          isSuperAdminUser ? depotService.getAll() : Promise.resolve([] as Depot[]),
        ]);

        setFleet(fleetData);
        setDepots(depotData);
        setFleetNumber(fleetData.number);
        setRegistrationNumber(fleetData.registration_number ?? "");
        setStatus(fleetData.status);
        setCapacity(String(fleetData.capacity ?? 0));
        setSelectedDepotId(fleetData.depot_id);
        setCompliance(complianceFromFleet(fleetData));
      } catch (err) {
        setLoadError(err instanceof Error ? err.message : "Failed to load fleet");
      } finally {
        setLoading(false);
      }
    };

    load();
  }, [id, isSuperAdminUser]);

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

  const handleSave = async () => {
    if (!id) return;
    setSaveError(null);

    if (!fleetNumber.trim()) {
      setSaveError("Fleet number is required");
      return;
    }

    if (!registrationNumber.trim()) {
      setSaveError("Registration number is required");
      return;
    }

    if (isSuperAdminUser && !selectedDepotId) {
      setSaveError("Please select a depot");
      return;
    }

    const complianceError = validateCompliance();
    if (complianceError) {
      setSaveError(complianceError);
      return;
    }

    setSaving(true);
    try {
      await fleetService.update(
        id,
        {
          number: fleetNumber.trim(),
          registration_number: registrationNumber.trim(),
          status,
          capacity: parseInt(capacity, 10) || 0,
          licence_disc_expiry: compliance.licence_disc_expiry || null,
          cof_expiry: compliance.cof_expiry || null,
          passenger_liability_expiry: compliance.passenger_liability_expiry || null,
          route_authority_expiry: compliance.route_authority_expiry || null,
          ppa_expiry: compliance.ppa_expiry || null,
        },
        isSuperAdminUser ? selectedDepotId : undefined
      );

      toast({
        title: "Fleet updated",
        description: `${fleetNumber} saved successfully.`,
      });
      navigate("/fleets");
    } catch (err) {
      const message = err instanceof Error ? err.message : "Failed to update fleet";
      if (
        message.toLowerCase().includes("registration") &&
        (message.includes("duplicate") || message.includes("already exists"))
      ) {
        setSaveError("A fleet with this registration number already exists in this depot.");
      } else if (message.includes("duplicate") || message.includes("already exists")) {
        setSaveError("A fleet with this number already exists in this depot.");
      } else {
        setSaveError(message);
      }
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-24">
        <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
      </div>
    );
  }

  if (loadError || !fleet) {
    return (
      <div className="space-y-4">
        <Button variant="ghost" size="sm" className="gap-2" asChild>
          <Link to="/fleets">
            <ArrowLeft className="h-4 w-4" />
            Back to fleets
          </Link>
        </Button>
        <ErrorAlert error={loadError ?? "Fleet not found"} />
      </div>
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.25 }}
      className="space-y-6 pb-10"
    >
      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div className="space-y-3">
          <Button variant="ghost" size="sm" className="gap-2 -ml-2" asChild>
            <Link to="/fleets">
              <ArrowLeft className="h-4 w-4" />
              Back to fleets
            </Link>
          </Button>

          <div className="flex items-start gap-3">
            <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-primary/10">
              <Bus className="h-6 w-6 text-primary" />
            </div>
            <div>
              <h1 className="text-2xl font-semibold tracking-tight flex items-center gap-2 flex-wrap font-mono">
                {fleetNumber}
                <Badge variant="outline" className={`text-xs ${statusBadgeClass[status]}`}>
                  {status.replace(/_/g, " ")}
                </Badge>
              </h1>
              <p className="text-sm text-muted-foreground mt-1">
                {registrationNumber.trim()
                  ? `Reg ${registrationNumber.trim().toUpperCase()} · Update vehicle details and compliance document expiry dates.`
                  : "Update vehicle details and compliance document expiry dates."}
              </p>
            </div>
          </div>
        </div>

        <div className="flex gap-2 sm:pt-8">
          <Button variant="outline" onClick={() => navigate("/fleets")} disabled={saving}>
            Cancel
          </Button>
          <Button className="gap-2" onClick={handleSave} disabled={saving}>
            {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
            Save changes
          </Button>
        </div>
      </div>

      {saveError && (
        <Alert variant="destructive">
          <AlertCircle className="h-4 w-4" />
          <AlertDescription>{saveError}</AlertDescription>
        </Alert>
      )}

      <div className="grid gap-6 lg:grid-cols-2">
        <Card className="shadow-sm">
          <CardHeader>
            <CardTitle className="text-base">Vehicle details</CardTitle>
            <CardDescription>Core fleet information and depot assignment.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div className="space-y-1.5">
                <Label htmlFor="edit-fleet-number">Fleet number</Label>
                <Input
                  id="edit-fleet-number"
                  value={fleetNumber}
                  onChange={(e) => setFleetNumber(e.target.value)}
                  disabled={saving}
                />
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="edit-registration-number">Registration number</Label>
                <Input
                  id="edit-registration-number"
                  placeholder="e.g. ABC1234"
                  value={registrationNumber}
                  onChange={(e) => setRegistrationNumber(e.target.value)}
                  disabled={saving}
                  className="font-mono uppercase"
                />
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div className="space-y-1.5">
                <Label htmlFor="edit-capacity">Capacity</Label>
                <Input
                  id="edit-capacity"
                  type="number"
                  min="0"
                  value={capacity}
                  onChange={(e) => setCapacity(e.target.value)}
                  disabled={saving}
                />
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="edit-status">Status</Label>
                <Select
                  value={status}
                  onValueChange={(val) => setStatus(val as Fleet["status"])}
                  disabled={saving}
                >
                  <SelectTrigger id="edit-status">
                    <SelectValue />
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

            <div className="space-y-1.5">
              <Label>Depot</Label>
              {isSuperAdminUser ? (
                <Select
                  value={selectedDepotId || undefined}
                  onValueChange={setSelectedDepotId}
                  disabled={saving}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Select depot" />
                  </SelectTrigger>
                  <SelectContent>
                    {depots.map((depot) => (
                      <SelectItem key={depot.id} value={depot.id}>
                        {depot.name} — {depot.location}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              ) : (
                <Input value={fleet.depot_name ?? "N/A"} disabled />
              )}
            </div>
          </CardContent>
        </Card>

        <Card className="shadow-sm">
          <CardHeader>
            <div className="flex items-center gap-2">
              <ShieldCheck className="h-4 w-4 text-accent" />
              <CardTitle className="text-base">Compliance documents</CardTitle>
            </div>
            <CardDescription>
              Update any document expiry date independently. Alerts escalate monthly → weekly →
              daily as expiry approaches.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="rounded-xl border border-border/60 bg-muted/20 p-3 space-y-3">
              {FLEET_COMPLIANCE_FIELDS.map((field) => (
                <div
                  key={field.key}
                  className="grid grid-cols-1 sm:grid-cols-[1fr_auto] gap-2 sm:items-center"
                >
                  <div className="min-w-0">
                    <Label htmlFor={`edit-${field.key}`} className="text-sm font-medium">
                      {field.label}
                    </Label>
                    <p className="text-[11px] text-muted-foreground/80 mt-0.5">{field.hint}</p>
                  </div>
                  <div className="relative sm:w-[180px]">
                    <CalendarDays className="absolute left-2.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-muted-foreground/60 pointer-events-none" />
                    <Input
                      id={`edit-${field.key}`}
                      type="date"
                      value={compliance[field.key]}
                      onChange={(e) => setComplianceField(field.key, e.target.value)}
                      disabled={saving}
                      className="pl-8"
                    />
                  </div>
                </div>
              ))}
            </div>

            {fleet.compliance && fleet.compliance.length > 0 && (
              <>
                <Separator className="my-4" />
                <p className="text-xs font-medium text-muted-foreground mb-2">Current status</p>
                <div className="flex flex-wrap gap-1.5">
                  {fleet.compliance.map((item) => (
                    <Badge key={item.key} variant="outline" className="text-[10px]">
                      {item.shortLabel}: {item.status_label}
                    </Badge>
                  ))}
                </div>
              </>
            )}
          </CardContent>
        </Card>
      </div>
    </motion.div>
  );
};

export default EditFleetPage;

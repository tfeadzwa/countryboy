import { useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { motion } from "framer-motion";
import {
  AlertCircle,
  ArrowLeft,
  Loader2,
  Save,
  ShieldCheck,
  UserRound,
} from "lucide-react";
import DriverDocumentCard from "@/components/DriverDocumentCard";
import ErrorAlert from "@/components/ErrorAlert";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { useToast } from "@/hooks/use-toast";
import { useAuth } from "@/contexts/AuthContext";
import { driverService } from "@/lib/api/driver.service";
import { depotService } from "@/lib/api/depot.service";
import {
  DRIVER_DOCUMENT_FIELDS,
  certificateNumberFieldForDocument,
  documentsFromDriver,
  emptyDriverDocumentForm,
  expiryFieldForDocument,
  type DriverDocumentFormState,
} from "@/lib/driver-documents";
import { canManageDrivers, isSuperAdmin } from "@/lib/permissions";
import type { Depot, Driver, DriverStatus } from "@/types";

const statusBadgeClass: Record<DriverStatus, string> = {
  ACTIVE: "bg-green-500/10 text-green-700 border-green-500/20",
  INACTIVE: "bg-gray-500/10 text-gray-700 border-gray-500/20",
  SUSPENDED: "bg-red-500/10 text-red-700 border-red-500/20",
};

const EditDriverPage = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { user } = useAuth();
  const { toast } = useToast();

  const userRoles = user?.roles || [];
  const canManage = canManageDrivers(userRoles);
  const isSuperAdminUser = isSuperAdmin(userRoles);

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [saveError, setSaveError] = useState<string | null>(null);

  const [driver, setDriver] = useState<Driver | null>(null);
  const [depots, setDepots] = useState<Depot[]>([]);

  const [fullName, setFullName] = useState("");
  const [phone, setPhone] = useState("");
  const [status, setStatus] = useState<DriverStatus>("ACTIVE");
  const [selectedDepotId, setSelectedDepotId] = useState("");
  const [docForm, setDocForm] = useState<DriverDocumentFormState>(emptyDriverDocumentForm());

  useEffect(() => {
    const load = async () => {
      if (!id) return;
      setLoading(true);
      setLoadError(null);

      try {
        const [driverData, depotData] = await Promise.all([
          driverService.getOne(id),
          isSuperAdminUser ? depotService.getAll() : Promise.resolve([] as Depot[]),
        ]);

        setDriver(driverData);
        setDepots(depotData);
        setFullName(driverData.full_name);
        setPhone(driverData.phone ?? "");
        setStatus(driverData.status);
        setSelectedDepotId(driverData.depot_id);
        setDocForm(documentsFromDriver(driverData));
      } catch (err) {
        setLoadError(err instanceof Error ? err.message : "Failed to load driver");
      } finally {
        setLoading(false);
      }
    };

    void load();
  }, [id, isSuperAdminUser]);

  const handleSave = async () => {
    if (!id || !driver) return;
    setSaveError(null);

    if (!fullName.trim()) {
      setSaveError("Full name is required");
      return;
    }

    if (isSuperAdminUser && !selectedDepotId) {
      setSaveError("Please select a depot");
      return;
    }

    setSaving(true);
    try {
      const updated = await driverService.update(
        id,
        {
          full_name: fullName.trim(),
          phone: phone.trim() || null,
          status,
          depot_id:
            isSuperAdminUser && selectedDepotId !== driver.depot_id
              ? selectedDepotId
              : undefined,
        },
        isSuperAdminUser ? driver.depot_id : undefined,
      );

      setDriver(updated);
      setDocForm(documentsFromDriver(updated));
      toast({
        title: "Driver updated",
        description: `${updated.full_name} saved successfully.`,
      });
    } catch (err) {
      setSaveError(err instanceof Error ? err.message : "Failed to update driver");
    } finally {
      setSaving(false);
    }
  };

  const handleDriverUpdated = (updated: Driver) => {
    setDriver(updated);
    setDocForm(documentsFromDriver(updated));
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-24">
        <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
      </div>
    );
  }

  if (loadError || !driver) {
    return (
      <div className="space-y-4">
        <Button variant="ghost" size="sm" className="gap-2" asChild>
          <Link to="/drivers">
            <ArrowLeft className="h-4 w-4" />
            Back to drivers
          </Link>
        </Button>
        <ErrorAlert error={loadError ?? "Driver not found"} />
      </div>
    );
  }

  const depotScopeId = isSuperAdminUser ? driver.depot_id : undefined;
  const attention = driver.documents_summary?.items_needing_attention ?? 0;

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
            <Link to="/drivers">
              <ArrowLeft className="h-4 w-4" />
              Back to drivers
            </Link>
          </Button>

          <div className="flex items-start gap-3">
            <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-primary/10">
              <UserRound className="h-6 w-6 text-primary" />
            </div>
            <div>
              <h1 className="text-2xl font-semibold tracking-tight flex items-center gap-2 flex-wrap">
                {driver.full_name}
                <Badge variant="outline" className={`text-xs ${statusBadgeClass[status]}`}>
                  {status}
                </Badge>
              </h1>
              <p className="text-sm text-muted-foreground mt-1">
                Manage profile details, upload compliance documents, and track expiry dates.
              </p>
            </div>
          </div>
        </div>

        {canManage && (
          <div className="flex gap-2 sm:pt-8">
            <Button variant="outline" onClick={() => navigate("/drivers")} disabled={saving}>
              Cancel
            </Button>
            <Button className="gap-2" onClick={handleSave} disabled={saving}>
              {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
              Save profile
            </Button>
          </div>
        )}
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
            <CardTitle className="text-base">Driver profile</CardTitle>
            <CardDescription>Basic information and depot assignment.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-1.5">
              <Label htmlFor="edit-driver-name">Full name</Label>
              <Input
                id="edit-driver-name"
                value={fullName}
                onChange={(e) => setFullName(e.target.value)}
                disabled={!canManage || saving}
              />
            </div>

            <div className="space-y-1.5">
              <Label htmlFor="edit-driver-phone">Phone</Label>
              <Input
                id="edit-driver-phone"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                disabled={!canManage || saving}
                placeholder="Optional"
              />
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div className="space-y-1.5">
                <Label htmlFor="edit-driver-status">Account status</Label>
                <Select
                  value={status}
                  onValueChange={(val) => setStatus(val as DriverStatus)}
                  disabled={!canManage || saving}
                >
                  <SelectTrigger id="edit-driver-status">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="ACTIVE">Active</SelectItem>
                    <SelectItem value="INACTIVE">Inactive</SelectItem>
                    <SelectItem value="SUSPENDED">Suspended</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-1.5">
                <Label>Depot</Label>
                {isSuperAdminUser ? (
                  <Select
                    value={selectedDepotId || undefined}
                    onValueChange={setSelectedDepotId}
                    disabled={!canManage || saving}
                  >
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
                ) : (
                  <Input value={driver.depot_name ?? "N/A"} disabled />
                )}
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="shadow-sm">
          <CardHeader>
            <div className="flex items-center gap-2">
              <ShieldCheck className="h-4 w-4 text-accent" />
              <CardTitle className="text-base">Document compliance</CardTitle>
            </div>
            <CardDescription>
              Upload the driver&apos;s official licence and medical certificate. Admins can download
              copies at any time.
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-3">
            {attention > 0 ? (
              <Alert>
                <AlertCircle className="h-4 w-4" />
                <AlertDescription>
                  {attention} document{attention === 1 ? "" : "s"} need attention — upload missing
                  files or update expiry dates.
                </AlertDescription>
              </Alert>
            ) : (
              <div className="rounded-xl border border-success/20 bg-success/5 px-3 py-2.5 text-sm text-success flex items-center gap-2">
                <ShieldCheck className="h-4 w-4 shrink-0" />
                All compliance documents are in good standing.
              </div>
            )}

            {driver.documents && driver.documents.length > 0 && (
              <div className="flex flex-wrap gap-1.5 pb-1">
                {driver.documents.map((item) => (
                  <Badge key={item.key} variant="outline" className="text-[10px]">
                    {item.shortLabel}: {item.status_label}
                  </Badge>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      <div>
        <h2 className="text-lg font-semibold mb-1">Compliance documents</h2>
        <p className="text-sm text-muted-foreground mb-4">
          Store scanned copies of the driver&apos;s licence, medical certificate, and DDC on the
          server.
        </p>
        <div className="grid gap-5 md:grid-cols-2 xl:grid-cols-3">
          {DRIVER_DOCUMENT_FIELDS.map((field) => (
            <DriverDocumentCard
              key={field.key}
              driver={driver}
              field={field}
              canManage={canManage}
              depotId={depotScopeId}
              expiryValue={docForm[expiryFieldForDocument(field.key)]}
              certificateNumber={
                certificateNumberFieldForDocument(field.key)
                  ? docForm[certificateNumberFieldForDocument(field.key)!]
                  : undefined
              }
              onCertificateNumberChange={
                certificateNumberFieldForDocument(field.key)
                  ? (value) => {
                      const numberField = certificateNumberFieldForDocument(field.key)!;
                      setDocForm((prev) => ({
                        ...prev,
                        [numberField]: value,
                      }));
                    }
                  : undefined
              }
              noExpiry={field.key === "drivers_licence" ? docForm.drivers_licence_no_expiry : false}
              onExpiryChange={(value) =>
                setDocForm((prev) => ({
                  ...prev,
                  [expiryFieldForDocument(field.key)]: value,
                }))
              }
              onNoExpiryChange={
                field.key === "drivers_licence"
                  ? (checked) =>
                      setDocForm((prev) => ({
                        ...prev,
                        drivers_licence_no_expiry: checked,
                        ...(checked ? { drivers_licence_expiry: "" } : {}),
                      }))
                  : undefined
              }
              onUpdated={handleDriverUpdated}
            />
          ))}
        </div>
      </div>
    </motion.div>
  );
};

export default EditDriverPage;

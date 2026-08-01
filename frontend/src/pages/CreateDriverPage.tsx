import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import { AlertCircle, ArrowLeft, Loader2, Plus, ShieldCheck, UserRound } from "lucide-react";
import DriverDocumentCard from "@/components/DriverDocumentCard";
import { Alert, AlertDescription } from "@/components/ui/alert";
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
  emptyDriverDocumentForm,
  expiryFieldForDocument,
  getUploadExpiryForField,
  validateDocumentExpiryInput,
  type DriverDocumentFormState,
} from "@/lib/driver-documents";
import { canManageDrivers, isSuperAdmin } from "@/lib/permissions";
import type { Depot, DriverDocumentKey, DriverStatus } from "@/types";

type PendingFiles = Record<DriverDocumentKey, File | null>;

const emptyPendingFiles = (): PendingFiles => ({
  drivers_licence: null,
  medical_certificate: null,
  defensive_driving_certificate: null,
});

const CreateDriverPage = () => {
  const navigate = useNavigate();
  const { user } = useAuth();
  const { toast } = useToast();

  const userRoles = user?.roles || [];
  const canManage = canManageDrivers(userRoles);
  const isSuperAdminUser = isSuperAdmin(userRoles);

  const [depots, setDepots] = useState<Depot[]>([]);
  const [loadingDepots, setLoadingDepots] = useState(isSuperAdminUser);
  const [creating, setCreating] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);

  const [fullName, setFullName] = useState("");
  const [phone, setPhone] = useState("");
  const [status, setStatus] = useState<DriverStatus>("ACTIVE");
  const [selectedDepotId, setSelectedDepotId] = useState("");
  const [docForm, setDocForm] = useState<DriverDocumentFormState>(emptyDriverDocumentForm());
  const [pendingFiles, setPendingFiles] = useState<PendingFiles>(emptyPendingFiles());

  useEffect(() => {
    if (!canManage) {
      navigate("/drivers", { replace: true });
    }
  }, [canManage, navigate]);

  useEffect(() => {
    const loadDepots = async () => {
      if (!isSuperAdminUser) return;
      setLoadingDepots(true);
      try {
        const depotList = await depotService.getAll();
        setDepots(depotList);
        if (depotList.length > 0) {
          setSelectedDepotId(depotList[0].id);
        }
      } catch {
        // Create will fail with a clear message if depot is missing.
      } finally {
        setLoadingDepots(false);
      }
    };

    void loadDepots();
  }, [isSuperAdminUser]);

  const setPendingFile = (key: DriverDocumentKey, file: File | null) => {
    setPendingFiles((prev) => ({ ...prev, [key]: file }));
  };

  const validateDocuments = (): string | null => {
    for (const field of DRIVER_DOCUMENT_FIELDS) {
      if (!pendingFiles[field.key]) continue;
      const expiryError = validateDocumentExpiryInput(
        field.key,
        docForm[expiryFieldForDocument(field.key)],
        {
          noExpiry: field.key === "drivers_licence" ? docForm.drivers_licence_no_expiry : false,
        },
      );
      if (expiryError) return expiryError;
    }
    return null;
  };

  const handleCreate = async () => {
    setSaveError(null);

    if (!fullName.trim()) {
      setSaveError("Full name is required");
      return;
    }

    if (isSuperAdminUser && !selectedDepotId) {
      setSaveError("Please select a depot for this driver");
      return;
    }

    const documentError = validateDocuments();
    if (documentError) {
      setSaveError(documentError);
      return;
    }

    setCreating(true);
    try {
      const depotScope = isSuperAdminUser ? selectedDepotId : undefined;
      const created = await driverService.create(
        {
          full_name: fullName.trim(),
          phone: phone.trim() || null,
          licence_number: docForm.licence_number.trim() || null,
          defensive_driving_certificate_number:
            docForm.defensive_driving_certificate_number.trim() || null,
          status,
        },
        depotScope,
      );

      let driver = created;
      const uploadErrors: string[] = [];

      for (const field of DRIVER_DOCUMENT_FIELDS) {
        const file = pendingFiles[field.key];
        if (!file) continue;

        const expiry = getUploadExpiryForField(field, docForm);

        try {
          driver = await driverService.uploadDocument(
            created.id,
            field.key,
            file,
            expiry,
            depotScope,
          );
        } catch (err) {
          uploadErrors.push(
            `${field.label}: ${err instanceof Error ? err.message : "upload failed"}`,
          );
        }
      }

      if (uploadErrors.length > 0) {
        toast({
          title: "Driver created with document errors",
          description: uploadErrors.join(" · "),
          variant: "destructive",
        });
        navigate(`/drivers/${created.id}/edit`);
        return;
      }

      const uploadedCount = DRIVER_DOCUMENT_FIELDS.filter((f) => pendingFiles[f.key]).length;
      toast({
        title: "Driver created",
        description:
          uploadedCount > 0
            ? `${created.full_name} and ${uploadedCount} document${uploadedCount === 1 ? "" : "s"} saved.`
            : `${created.full_name} was added successfully.`,
      });
      navigate("/drivers");
    } catch (err) {
      setSaveError(err instanceof Error ? err.message : "Could not create driver");
    } finally {
      setCreating(false);
    }
  };

  if (loadingDepots) {
    return (
      <div className="flex items-center justify-center py-24">
        <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
      </div>
    );
  }

  const pendingDocCount = Object.values(pendingFiles).filter(Boolean).length;

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
              <h1 className="text-2xl font-semibold tracking-tight">Add driver</h1>
              <p className="text-sm text-muted-foreground mt-1">
                Create the driver profile and upload compliance documents in one step.
              </p>
            </div>
          </div>
        </div>

        <div className="flex gap-2 sm:pt-8">
          <Button variant="outline" onClick={() => navigate("/drivers")} disabled={creating}>
            Cancel
          </Button>
          <Button className="gap-2" onClick={handleCreate} disabled={creating}>
            {creating ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              <Plus className="h-4 w-4" />
            )}
            Create driver
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
            <CardTitle className="text-base">Driver profile</CardTitle>
            <CardDescription>Basic information and depot assignment.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {isSuperAdminUser && (
              <div className="space-y-1.5">
                <Label>Depot *</Label>
                <Select
                  value={selectedDepotId || undefined}
                  onValueChange={setSelectedDepotId}
                  disabled={creating}
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
              </div>
            )}

            <div className="space-y-1.5">
              <Label htmlFor="create-driver-name">Full name *</Label>
              <Input
                id="create-driver-name"
                value={fullName}
                onChange={(e) => setFullName(e.target.value)}
                disabled={creating}
                placeholder="e.g. Tendai Moyo"
              />
            </div>

            <div className="space-y-1.5">
              <Label htmlFor="create-driver-phone">Phone</Label>
              <Input
                id="create-driver-phone"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                disabled={creating}
                placeholder="Optional"
              />
            </div>

            <div className="space-y-1.5">
              <Label htmlFor="create-driver-status">Account status</Label>
              <Select
                value={status}
                onValueChange={(val) => setStatus(val as DriverStatus)}
                disabled={creating}
              >
                <SelectTrigger id="create-driver-status">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="ACTIVE">Active</SelectItem>
                  <SelectItem value="INACTIVE">Inactive</SelectItem>
                  <SelectItem value="SUSPENDED">Suspended</SelectItem>
                </SelectContent>
              </Select>
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
              Select files below — they will be uploaded and saved when you create the driver.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="rounded-xl border border-border/60 bg-muted/20 px-3.5 py-3 text-sm text-muted-foreground">
              {pendingDocCount === 0 ? (
                <p>No documents selected yet. Upload licence, medical, and DDC certificates below.</p>
              ) : (
                <p>
                  <span className="font-medium text-foreground">{pendingDocCount}</span> document
                  {pendingDocCount === 1 ? "" : "s"} ready to upload on save.
                </p>
              )}
            </div>
          </CardContent>
        </Card>
      </div>

      <div>
        <h2 className="text-lg font-semibold mb-1">Compliance documents</h2>
        <p className="text-sm text-muted-foreground mb-4">
          Attach the driver&apos;s licence, medical certificate, and DDC. Expiry dates are saved with
          each file in the database.
        </p>
        <div className="grid gap-5 md:grid-cols-2 xl:grid-cols-3">
          {DRIVER_DOCUMENT_FIELDS.map((field) => (
            <DriverDocumentCard
              key={field.key}
              draft
              field={field}
              canManage={canManage}
              disabled={creating}
              pendingFile={pendingFiles[field.key]}
              onPendingFileChange={(file) => setPendingFile(field.key, file)}
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
            />
          ))}
        </div>
      </div>
    </motion.div>
  );
};

export default CreateDriverPage;

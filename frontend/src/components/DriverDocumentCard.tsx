import { useRef, useState } from "react";
import {
  AlertCircle,
  CalendarDays,
  Download,
  FileText,
  HeartPulse,
  Loader2,
  Save,
  Shield,
  Trash2,
  Upload,
} from "lucide-react";
import ConfirmDeleteDialog from "@/components/ConfirmDeleteDialog";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Checkbox } from "@/components/ui/checkbox";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useToast } from "@/hooks/use-toast";
import { driverService } from "@/lib/api/driver.service";
import {
  maxDateYearsFromToday,
  severityStyles,
  toDateInputValue,
  validateDocumentExpiryInput,
} from "@/lib/driver-documents";
import type { Driver, DriverDocumentItem, DriverDocumentKey } from "@/types";

type DocumentFieldConfig = {
  key: DriverDocumentKey;
  label: string;
  description: string;
  expiryOptional: boolean;
  expiryHint: string;
  maxYearsFromToday?: number;
};

const ICONS: Record<DriverDocumentKey, typeof FileText> = {
  drivers_licence: FileText,
  medical_certificate: HeartPulse,
  defensive_driving_certificate: Shield,
};

const ICON_COLORS: Record<DriverDocumentKey, string> = {
  drivers_licence: "bg-blue-500/10 text-blue-600 dark:text-blue-400",
  medical_certificate: "bg-rose-500/10 text-rose-600 dark:text-rose-400",
  defensive_driving_certificate: "bg-amber-500/10 text-amber-700 dark:text-amber-300",
};

const ALLOWED_EXTENSIONS = [".pdf", ".jpg", ".jpeg", ".png", ".webp"];
const ALLOWED_MIMES = ["application/pdf", "image/jpeg", "image/png", "image/webp"];

const DOCUMENT_NUMBER_CONFIG: Partial<
  Record<
    DriverDocumentKey,
    {
      label: string;
      placeholder: string;
      displayPrefix: string;
      updateField: "licence_number" | "defensive_driving_certificate_number";
      savedTitle: string;
      savedDescription: string;
    }
  >
> = {
  drivers_licence: {
    label: "Licence number",
    placeholder: "e.g. AB123456",
    displayPrefix: "Licence #",
    updateField: "licence_number",
    savedTitle: "Licence number updated",
    savedDescription: "Licence number saved.",
  },
  defensive_driving_certificate: {
    label: "Certificate number",
    placeholder: "e.g. DDC-12345",
    displayPrefix: "DDC #",
    updateField: "defensive_driving_certificate_number",
    savedTitle: "Certificate number updated",
    savedDescription: "DDC number saved.",
  },
};

function isAllowedUploadFile(file: File): boolean {
  const ext = file.name.includes(".")
    ? file.name.slice(file.name.lastIndexOf(".")).toLowerCase()
    : "";
  if (ALLOWED_EXTENSIONS.includes(ext)) return true;
  return ALLOWED_MIMES.includes(file.type);
}

interface DriverDocumentCardProps {
  driver?: Driver | null;
  field: DocumentFieldConfig;
  canManage: boolean;
  depotId?: string;
  expiryValue: string;
  noExpiry?: boolean;
  certificateNumber?: string;
  onCertificateNumberChange?: (value: string) => void;
  onExpiryChange: (value: string) => void;
  onNoExpiryChange?: (checked: boolean) => void;
  onUpdated?: (driver: Driver) => void;
  /** When true, file is held locally until the parent creates the driver. */
  draft?: boolean;
  pendingFile?: File | null;
  onPendingFileChange?: (file: File | null) => void;
  disabled?: boolean;
}

function formatUploadedAt(iso?: string | null) {
  if (!iso) return null;
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return null;
  return d.toLocaleDateString(undefined, { day: "numeric", month: "short", year: "numeric" });
}

export default function DriverDocumentCard({
  driver = null,
  field,
  canManage,
  depotId,
  expiryValue,
  noExpiry = false,
  certificateNumber = "",
  onCertificateNumberChange,
  onExpiryChange,
  onNoExpiryChange,
  onUpdated,
  draft = false,
  pendingFile: controlledPendingFile,
  onPendingFileChange,
  disabled = false,
}: DriverDocumentCardProps) {
  const { toast } = useToast();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [internalPendingFile, setInternalPendingFile] = useState<File | null>(null);
  const [uploading, setUploading] = useState(false);
  const [savingExpiry, setSavingExpiry] = useState(false);
  const [savingCertificateNumber, setSavingCertificateNumber] = useState(false);
  const [downloading, setDownloading] = useState(false);
  const [removing, setRemoving] = useState(false);
  const [dragOver, setDragOver] = useState(false);
  const [confirmRemoveOpen, setConfirmRemoveOpen] = useState(false);
  const [confirmReplaceOpen, setConfirmReplaceOpen] = useState(false);

  const selectedFile = draft ? (controlledPendingFile ?? null) : internalPendingFile;
  const setSelectedFile = (file: File | null) => {
    if (draft) onPendingFileChange?.(file);
    else setInternalPendingFile(file);
  };

  const doc: DriverDocumentItem | undefined = driver?.documents?.find((d) => d.key === field.key);
  const Icon = ICONS[field.key];
  const hasUploadedFile = Boolean(doc?.has_file);
  const pendingUpload = Boolean(selectedFile) && !hasUploadedFile;
  const draftStyles = severityStyles.info;
  const styles = draft && pendingUpload ? draftStyles : severityStyles[doc?.severity ?? "warning"] ?? severityStyles.warning;
  const pendingStyles = severityStyles.warning;

  const storedExpiryInput = toDateInputValue(doc?.expiry_date);
  const storedNoExpiry = Boolean(field.expiryOptional && hasUploadedFile && !doc?.expiry_date);
  const expiryChanged =
    hasUploadedFile &&
    (field.key === "drivers_licence"
      ? noExpiry !== storedNoExpiry || (!noExpiry && expiryValue !== storedExpiryInput)
      : expiryValue !== storedExpiryInput);

  const numberConfig = DOCUMENT_NUMBER_CONFIG[field.key];
  const storedCertificateNumber = numberConfig
    ? field.key === "drivers_licence"
      ? (doc?.certificate_number ?? driver?.licence_number ?? "")
      : (doc?.certificate_number ?? driver?.defensive_driving_certificate_number ?? "")
    : "";
  const certificateNumberChanged =
    Boolean(numberConfig) &&
    certificateNumber.trim() !== storedCertificateNumber.trim();

  const handleFileSelect = (file: File | null) => {
    if (!file) return;
    if (!isAllowedUploadFile(file)) {
      toast({
        title: "Unsupported file type",
        description: "Please upload a PDF, JPEG, PNG, or WebP file.",
        variant: "destructive",
      });
      return;
    }
    if (file.size > 10 * 1024 * 1024) {
      toast({
        title: "File too large",
        description: "Maximum file size is 10 MB.",
        variant: "destructive",
      });
      return;
    }
    setSelectedFile(file);
  };

  const expiryMaxDate = field.maxYearsFromToday
    ? maxDateYearsFromToday(field.maxYearsFromToday)
    : undefined;

  const validateExpiry = (): string | null =>
    validateDocumentExpiryInput(field.key, expiryValue, { noExpiry });

  const handleUpload = async () => {
    if (draft || !driver || !onUpdated) return;
    if (!selectedFile) {
      toast({ title: "Choose a file first", variant: "destructive" });
      return;
    }

    const expiryError = validateExpiry();
    if (expiryError) {
      toast({
        title: "Invalid expiry date",
        description: expiryError,
        variant: "destructive",
      });
      return;
    }

    setUploading(true);
    try {
      const expiry = field.expiryOptional && noExpiry ? null : expiryValue.trim() || null;
      const updated = await driverService.uploadDocument(
        driver.id,
        field.key,
        selectedFile,
        expiry,
        depotId,
      );
      let nextDriver = updated;
      if (numberConfig && certificateNumber.trim()) {
        const storedValue =
          numberConfig.updateField === "licence_number"
            ? (updated.licence_number ?? "")
            : (updated.defensive_driving_certificate_number ?? "");
        if (certificateNumber.trim() !== storedValue.trim()) {
          nextDriver = await driverService.update(
            driver.id,
            { [numberConfig.updateField]: certificateNumber.trim() },
            depotId,
          );
        }
      }
      setSelectedFile(null);
      if (fileInputRef.current) fileInputRef.current.value = "";
      onUpdated(nextDriver);
      setConfirmReplaceOpen(false);
      toast({ title: "Document uploaded", description: `${field.label} saved successfully.` });
    } catch (err) {
      toast({
        title: "Upload failed",
        description: err instanceof Error ? err.message : "Could not upload document",
        variant: "destructive",
      });
    } finally {
      setUploading(false);
    }
  };

  const handleSaveCertificateNumber = async () => {
    if (draft || !driver || !onUpdated || !numberConfig) return;

    setSavingCertificateNumber(true);
    try {
      const updated = await driverService.update(
        driver.id,
        { [numberConfig.updateField]: certificateNumber.trim() || null },
        depotId,
      );
      onUpdated(updated);
      toast({
        title: numberConfig.savedTitle,
        description: numberConfig.savedDescription,
      });
    } catch (err) {
      toast({
        title: "Could not update certificate number",
        description: err instanceof Error ? err.message : "Try again",
        variant: "destructive",
      });
    } finally {
      setSavingCertificateNumber(false);
    }
  };

  const handleSaveExpiry = async () => {
    if (draft || !driver || !onUpdated) return;

    const expiryError = validateExpiry();
    if (expiryError) {
      toast({
        title: "Invalid expiry date",
        description: expiryError,
        variant: "destructive",
      });
      return;
    }

    setSavingExpiry(true);
    try {
      const updated = await driverService.update(
        driver.id,
        field.key === "drivers_licence"
          ? { drivers_licence_expiry: noExpiry ? null : expiryValue.trim() || null }
          : field.key === "medical_certificate"
            ? { medical_certificate_expiry: expiryValue.trim() || null }
            : { defensive_driving_certificate_expiry: expiryValue.trim() || null },
        depotId,
      );
      onUpdated(updated);
      toast({ title: "Expiry updated", description: `${field.label} expiry date saved.` });
    } catch (err) {
      toast({
        title: "Could not update expiry",
        description: err instanceof Error ? err.message : "Try again",
        variant: "destructive",
      });
    } finally {
      setSavingExpiry(false);
    }
  };

  const handleDownload = async () => {
    setDownloading(true);
    try {
      const blob = await driverService.downloadDocument(driver.id, field.key, depotId);
      const url = URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;
      link.download = doc?.file_name ?? `${field.key}.pdf`;
      document.body.appendChild(link);
      link.click();
      link.remove();
      URL.revokeObjectURL(url);
    } catch (err) {
      toast({
        title: "Download failed",
        description: err instanceof Error ? err.message : "Could not download document",
        variant: "destructive",
      });
    } finally {
      setDownloading(false);
    }
  };

  const handleRemove = async () => {
    if (!driver || !onUpdated) return;
    setRemoving(true);
    try {
      const updated = await driverService.removeDocument(driver.id, field.key, depotId);
      setSelectedFile(null);
      if (fileInputRef.current) fileInputRef.current.value = "";
      onUpdated(updated);
      setConfirmRemoveOpen(false);
      toast({ title: "Document removed", description: `${field.label} was deleted.` });
    } catch (err) {
      toast({
        title: "Could not remove document",
        description: err instanceof Error ? err.message : "Try again",
        variant: "destructive",
      });
    } finally {
      setRemoving(false);
    }
  };

  const requestUpload = () => {
    if (draft || !driver || !onUpdated) return;
    if (!selectedFile) {
      toast({ title: "Choose a file first", variant: "destructive" });
      return;
    }

    const expiryError = validateExpiry();
    if (expiryError) {
      toast({
        title: "Invalid expiry date",
        description: expiryError,
        variant: "destructive",
      });
      return;
    }

    if (doc?.has_file) {
      setConfirmReplaceOpen(true);
      return;
    }

    void handleUpload();
  };

  return (
    <div className={`rounded-2xl border bg-card shadow-sm overflow-hidden ring-1 ${styles.ring}`}>
      <div className={`h-1 ${styles.bar}`} />

      <div className="p-4 sm:p-5 space-y-4">
        <div className="flex items-start gap-3">
          <div
            className={`flex h-10 w-10 sm:h-11 sm:w-11 shrink-0 items-center justify-center rounded-xl ${ICON_COLORS[field.key]}`}
          >
            <Icon className="h-5 w-5" />
          </div>
          <div className="min-w-0 flex-1 space-y-2">
            <div className="space-y-1.5">
              <h3 className="pr-1 font-semibold text-sm leading-snug text-foreground">
                {field.label}
              </h3>
              {pendingUpload ? (
                <Badge
                  variant="outline"
                  className={`text-[10px] w-fit max-w-full whitespace-normal ${pendingStyles.badge}`}
                >
                  {draft ? "Will upload on save" : "Ready to upload"}
                </Badge>
              ) : doc ? (
                <Badge
                  variant="outline"
                  className={`text-[10px] w-fit max-w-full whitespace-normal ${styles.badge}`}
                >
                  {doc.status_label}
                </Badge>
              ) : (
                <Badge
                  variant="outline"
                  className={`text-[10px] w-fit max-w-full whitespace-normal ${severityStyles.warning.badge}`}
                >
                  Document not uploaded
                </Badge>
              )}
            </div>
            <p className="text-xs text-muted-foreground leading-relaxed">
              {field.description}
            </p>
          </div>
        </div>

        {hasUploadedFile ? (
          <div className="rounded-xl border border-border/60 bg-muted/30 px-3.5 py-3 flex flex-col gap-2.5 sm:flex-row sm:items-center sm:justify-between">
            <div className="min-w-0">
              <p className="text-sm font-medium truncate" title={doc.file_name ?? undefined}>
                {doc.file_name ?? "Uploaded document"}
              </p>
              {doc.uploaded_at && (
                <p className="text-[11px] text-muted-foreground mt-0.5">
                  Uploaded {formatUploadedAt(doc.uploaded_at)}
                  {numberConfig && storedCertificateNumber ? (
                    <>
                      {" · "}
                      {numberConfig.displayPrefix}
                      {storedCertificateNumber}
                    </>
                  ) : null}
                  {doc.expiry_date
                    ? ` · Expires ${formatUploadedAt(doc.expiry_date)}`
                    : field.expiryOptional
                      ? " · No expiry recorded"
                      : ""}
                </p>
              )}
            </div>
            <Button
              variant="outline"
              size="sm"
              className="shrink-0 gap-1.5 h-8 w-full sm:w-auto"
              onClick={handleDownload}
              disabled={downloading}
            >
              {downloading ? (
                <Loader2 className="h-3.5 w-3.5 animate-spin" />
              ) : (
                <Download className="h-3.5 w-3.5" />
              )}
              Download
            </Button>
          </div>
        ) : pendingUpload && selectedFile ? (
          <div className="rounded-xl border border-amber-500/30 bg-amber-500/5 px-3.5 py-3">
            <p className="text-sm font-medium text-amber-900 dark:text-amber-200">
              {selectedFile.name}
            </p>
            <p className="text-[11px] text-muted-foreground mt-0.5">
              {draft
                ? "File selected — it will be uploaded when you create the driver."
                : (
                  <>
                    File selected — click <span className="font-medium">Upload document</span> below to
                    save it to the server.
                  </>
                )}
            </p>
          </div>
        ) : (
          <div className="rounded-xl border border-dashed border-border/70 bg-muted/15 px-4 py-5 text-center">
            <AlertCircle className="h-5 w-5 text-muted-foreground/60 mx-auto mb-2" />
            <p className="text-sm text-muted-foreground">No document uploaded yet</p>
          </div>
        )}

        {canManage && (
          <>
            <div
              className={`relative rounded-xl border-2 border-dashed transition-colors ${
                disabled ? "opacity-60 pointer-events-none" : "cursor-pointer"
              } ${
                dragOver
                  ? "border-primary/50 bg-primary/5"
                  : "border-border/60 hover:border-primary/30 hover:bg-muted/20"
              }`}
              onDragOver={(e) => {
                if (disabled) return;
                e.preventDefault();
                setDragOver(true);
              }}
              onDragLeave={() => setDragOver(false)}
              onDrop={(e) => {
                if (disabled) return;
                e.preventDefault();
                setDragOver(false);
                handleFileSelect(e.dataTransfer.files[0] ?? null);
              }}
              onClick={() => !disabled && fileInputRef.current?.click()}
            >
              <input
                ref={fileInputRef}
                type="file"
                accept=".pdf,.jpg,.jpeg,.png,.webp,application/pdf,image/*"
                className="sr-only"
                disabled={disabled}
                onChange={(e) => handleFileSelect(e.target.files?.[0] ?? null)}
              />
              <div className="px-4 py-6 text-center pointer-events-none">
                <Upload className="h-5 w-5 text-muted-foreground mx-auto mb-2" />
                <p className="text-sm font-medium">
                  {selectedFile ? selectedFile.name : "Drop file here or click to browse"}
                </p>
                <p className="text-[11px] text-muted-foreground mt-1">PDF, JPEG, PNG or WebP · Max 10 MB</p>
              </div>
            </div>

            <div className="space-y-2.5">
              {numberConfig && onCertificateNumberChange && (
                <div className="space-y-1.5">
                  <Label htmlFor={`${field.key}-number`} className="text-sm">
                    {numberConfig.label}
                  </Label>
                  <Input
                    id={`${field.key}-number`}
                    value={certificateNumber}
                    onChange={(e) => onCertificateNumberChange(e.target.value)}
                    disabled={uploading || savingExpiry || savingCertificateNumber || disabled}
                    placeholder={numberConfig.placeholder}
                  />
                </div>
              )}

              {field.expiryOptional && onNoExpiryChange && (
                <div className="flex items-center gap-2">
                  <Checkbox
                    id={`${field.key}-no-expiry`}
                    checked={noExpiry}
                    onCheckedChange={(checked) => onNoExpiryChange(checked === true)}
                    disabled={uploading || savingExpiry || savingCertificateNumber || disabled}
                  />
                  <Label
                    htmlFor={`${field.key}-no-expiry`}
                    className="text-sm font-normal cursor-pointer text-muted-foreground"
                  >
                    This licence has no expiry date (older documents)
                  </Label>
                </div>
              )}

              {!(field.expiryOptional && noExpiry) && (
                <div className="space-y-1.5">
                  <Label htmlFor={`${field.key}-expiry`} className="text-sm">
                    Expiry date{field.expiryOptional ? " (optional)" : " *"}
                  </Label>
                  <div className="relative">
                    <CalendarDays className="absolute left-2.5 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-muted-foreground/60 pointer-events-none" />
                    <Input
                      id={`${field.key}-expiry`}
                      type="date"
                      value={expiryValue}
                      max={expiryMaxDate}
                      onChange={(e) => onExpiryChange(e.target.value)}
                      disabled={uploading || savingExpiry || savingCertificateNumber || disabled}
                      className="pl-8"
                    />
                  </div>
                  <p className="text-[11px] text-muted-foreground">{field.expiryHint}</p>
                </div>
              )}
            </div>

            {!draft && (
              <div className="flex flex-wrap gap-2 pt-1">
                <Button
                  size="sm"
                  className="gap-1.5"
                  onClick={requestUpload}
                  disabled={uploading || !selectedFile}
                >
                  {uploading ? (
                    <Loader2 className="h-3.5 w-3.5 animate-spin" />
                  ) : (
                    <Upload className="h-3.5 w-3.5" />
                  )}
                  {doc?.has_file ? "Replace document" : selectedFile ? "Upload document" : "Choose file to upload"}
                </Button>
                {certificateNumberChanged && !selectedFile && (
                  <Button
                    variant="outline"
                    size="sm"
                    className="gap-1.5"
                    onClick={handleSaveCertificateNumber}
                    disabled={savingCertificateNumber}
                  >
                    {savingCertificateNumber ? (
                      <Loader2 className="h-3.5 w-3.5 animate-spin" />
                    ) : (
                      <Save className="h-3.5 w-3.5" />
                    )}
                    Update number
                  </Button>
                )}
                {hasUploadedFile && expiryChanged && !selectedFile && (
                  <Button
                    variant="outline"
                    size="sm"
                    className="gap-1.5"
                    onClick={handleSaveExpiry}
                    disabled={savingExpiry}
                  >
                    {savingExpiry ? (
                      <Loader2 className="h-3.5 w-3.5 animate-spin" />
                    ) : (
                      <Save className="h-3.5 w-3.5" />
                    )}
                    Update expiry
                  </Button>
                )}
                {doc?.has_file && (
                  <Button
                    variant="outline"
                    size="sm"
                    className="gap-1.5 text-destructive hover:text-destructive hover:bg-destructive/10"
                    onClick={() => setConfirmRemoveOpen(true)}
                    disabled={removing}
                  >
                    {removing ? (
                      <Loader2 className="h-3.5 w-3.5 animate-spin" />
                    ) : (
                      <Trash2 className="h-3.5 w-3.5" />
                    )}
                    Remove
                  </Button>
                )}
              </div>
            )}
          </>
        )}
      </div>

      <ConfirmDeleteDialog
        open={confirmRemoveOpen}
        onOpenChange={setConfirmRemoveOpen}
        title="Remove document?"
        description={
          doc?.file_name
            ? `This will permanently remove ${field.label} (${doc.file_name}) from this driver. You can upload a new file later.`
            : `This will permanently remove ${field.label} from this driver. You can upload a new file later.`
        }
        confirmLabel="Remove"
        loadingLabel="Removing…"
        loading={removing}
        onConfirm={handleRemove}
      />

      <ConfirmDeleteDialog
        open={confirmReplaceOpen}
        onOpenChange={setConfirmReplaceOpen}
        title="Replace document?"
        description={
          selectedFile && doc?.file_name
            ? `Replace "${doc.file_name}" with "${selectedFile.name}"? The previous file will be deleted from the server.`
            : selectedFile
              ? `Upload "${selectedFile.name}" and replace the current ${field.label}? The previous file will be deleted from the server.`
              : `Replace the current ${field.label}? The previous file will be deleted from the server.`
        }
        confirmLabel="Replace"
        loadingLabel="Replacing…"
        loading={uploading}
        tone="default"
        onConfirm={() => void handleUpload()}
      />
    </div>
  );
}

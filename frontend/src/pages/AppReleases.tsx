import { useEffect, useRef, useState } from "react";
import { Link } from "react-router-dom";
import { motion } from "framer-motion";
import {
  AlertCircle,
  CheckCircle2,
  Download,
  FileDown,
  Loader2,
  Monitor,
  Package,
  Pencil,
  Smartphone,
  Star,
  Trash2,
  Upload,
  X,
} from "lucide-react";
import PageHeader from "@/components/PageHeader";
import ConfirmDeleteDialog from "@/components/ConfirmDeleteDialog";
import ErrorAlert from "@/components/ErrorAlert";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Checkbox } from "@/components/ui/checkbox";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { useToast } from "@/hooks/use-toast";
import { useAuth } from "@/contexts/AuthContext";
import { canPublishAppReleases } from "@/lib/permissions";
import {
  appReleaseService,
  getAdminNotes,
  getMobileNotes,
  hasReleaseNotes,
  type AppRelease,
} from "@/lib/api/app-release.service";

const formatBytes = (bytes: number) => {
  if (!bytes || bytes < 0) return "—";
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
};

const formatDate = (iso: string) => {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return "—";
  return d.toLocaleString(undefined, {
    day: "numeric",
    month: "short",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
};

const NotesPreviewBlock = ({
  title,
  icon: Icon,
  text,
}: {
  title: string;
  icon: typeof Smartphone;
  text: string;
}) => (
  <div className="rounded-xl border border-border/60 bg-muted/10 px-3.5 py-3">
    <div className="mb-1.5 flex items-center gap-1.5 text-[11px] font-semibold uppercase tracking-wide text-muted-foreground">
      <Icon className="h-3.5 w-3.5" />
      {title}
    </div>
    {text ? (
      <p className="text-sm text-foreground/90 whitespace-pre-wrap line-clamp-4">{text}</p>
    ) : (
      <p className="text-sm text-muted-foreground italic">No notes yet</p>
    )}
  </div>
);

const AppReleases = () => {
  const { toast } = useToast();
  const { user } = useAuth();
  const canPublish = canPublishAppReleases(user?.roles ?? []);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const [releases, setReleases] = useState<AppRelease[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [versionName, setVersionName] = useState("");
  const [versionCode, setVersionCode] = useState("");
  const [mobileNotes, setMobileNotes] = useState("");
  const [adminNotes, setAdminNotes] = useState("");
  const [setAsCurrent, setSetAsCurrent] = useState(true);
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [publishing, setPublishing] = useState(false);
  const [publishError, setPublishError] = useState<string | null>(null);
  const [editingRelease, setEditingRelease] = useState<AppRelease | null>(null);
  const [notesFocusId, setNotesFocusId] = useState<string | null>(null);

  const [downloadingId, setDownloadingId] = useState<string | null>(null);
  const [settingCurrentId, setSettingCurrentId] = useState<string | null>(null);
  const [deleteTarget, setDeleteTarget] = useState<AppRelease | null>(null);
  const [deleting, setDeleting] = useState(false);
  const [updateConfirmOpen, setUpdateConfirmOpen] = useState(false);
  const [publishConfirmOpen, setPublishConfirmOpen] = useState(false);

  const loadReleases = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await appReleaseService.list();
      setReleases(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load releases");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void loadReleases();
  }, []);

  const current = releases.find((r) => r.is_current) ?? releases[0] ?? null;
  const history = releases.filter((r) => r.id !== current?.id);
  const notesRelease =
    releases.find((r) => r.id === notesFocusId) ??
    editingRelease ??
    current;

  const handleFileSelect = (file: File | null) => {
    if (!file) return;
    const ext = file.name.slice(file.name.lastIndexOf(".")).toLowerCase();
    if (![".apk", ".aab"].includes(ext)) {
      toast({
        title: "Unsupported file",
        description: "Please upload an Android APK or AAB file.",
        variant: "destructive",
      });
      return;
    }
    if (file.size > 150 * 1024 * 1024) {
      toast({
        title: "File too large",
        description: "Maximum package size is 150 MB.",
        variant: "destructive",
      });
      return;
    }
    setSelectedFile(file);
  };

  const resetForm = () => {
    setVersionName("");
    setVersionCode("");
    setMobileNotes("");
    setAdminNotes("");
    setSetAsCurrent(true);
    setSelectedFile(null);
    setPublishError(null);
    setEditingRelease(null);
    if (fileInputRef.current) fileInputRef.current.value = "";
  };

  const startEdit = (release: AppRelease) => {
    setEditingRelease(release);
    setNotesFocusId(release.id);
    setVersionName(release.version_name);
    setVersionCode(String(release.version_code));
    setMobileNotes(getMobileNotes(release));
    setAdminNotes(getAdminNotes(release));
    setSetAsCurrent(release.is_current);
    setSelectedFile(null);
    setPublishError(null);
    if (fileInputRef.current) fileInputRef.current.value = "";
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const handlePublish = (e: React.FormEvent) => {
    e.preventDefault();
    setPublishError(null);

    if (!versionName.trim()) {
      setPublishError("Version name is required (e.g. 1.0.0)");
      return;
    }
    const code = Number(versionCode);
    if (!Number.isInteger(code) || code < 1) {
      setPublishError("Version code must be a positive integer");
      return;
    }
    if (!editingRelease && !selectedFile) {
      setPublishError("Select an APK or AAB file to publish");
      return;
    }

    if (editingRelease) {
      setUpdateConfirmOpen(true);
      return;
    }

    setPublishConfirmOpen(true);
  };

  const submitRelease = async () => {
    const code = Number(versionCode);
    setPublishing(true);
    try {
      if (editingRelease) {
        const updated = await appReleaseService.update(editingRelease.id, {
          version_name: versionName.trim(),
          version_code: code,
          mobile_notes: mobileNotes.trim() || undefined,
          admin_notes: adminNotes.trim() || undefined,
          set_as_current: setAsCurrent,
          file: selectedFile ?? undefined,
        });
        toast({
          title: "Release updated",
          description: `v${updated.version_name} (${updated.version_code}) was saved.`,
        });
        setNotesFocusId(updated.id);
        setUpdateConfirmOpen(false);
      } else {
        const created = await appReleaseService.publish({
          version_name: versionName.trim(),
          version_code: code,
          mobile_notes: mobileNotes.trim() || undefined,
          admin_notes: adminNotes.trim() || undefined,
          set_as_current: setAsCurrent,
          file: selectedFile!,
        });
        toast({
          title: "Release published",
          description: `v${created.version_name} (${created.version_code}) is ready to download.`,
        });
        setNotesFocusId(created.id);
        setPublishConfirmOpen(false);
      }
      resetForm();
      await loadReleases();
    } catch (err) {
      setPublishError(
        err instanceof Error
          ? err.message
          : editingRelease
            ? "Could not update release"
            : "Could not publish release",
      );
      setUpdateConfirmOpen(false);
      setPublishConfirmOpen(false);
    } finally {
      setPublishing(false);
    }
  };

  const handleDownload = async (release: AppRelease) => {
    setDownloadingId(release.id);
    try {
      const blob = await appReleaseService.download(release.id);
      const url = URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;
      link.download = release.file_name || `countryboy-${release.version_name}.apk`;
      document.body.appendChild(link);
      link.click();
      link.remove();
      URL.revokeObjectURL(url);
      toast({
        title: "Download started",
        description: `${release.file_name} · ${formatBytes(release.file_size)}`,
      });
    } catch (err) {
      toast({
        title: "Download failed",
        description: err instanceof Error ? err.message : "Try again",
        variant: "destructive",
      });
    } finally {
      setDownloadingId(null);
    }
  };

  const handleSetCurrent = async (release: AppRelease) => {
    setSettingCurrentId(release.id);
    try {
      await appReleaseService.setCurrent(release.id);
      toast({
        title: "Current release updated",
        description: `v${release.version_name} is now the current build.`,
      });
      await loadReleases();
    } catch (err) {
      toast({
        title: "Could not update current release",
        description: err instanceof Error ? err.message : "Try again",
        variant: "destructive",
      });
    } finally {
      setSettingCurrentId(null);
    }
  };

  const handleDelete = async () => {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      await appReleaseService.remove(deleteTarget.id);
      toast({
        title: "Release deleted",
        description: `v${deleteTarget.version_name} was removed from the server.`,
      });
      if (notesFocusId === deleteTarget.id) setNotesFocusId(null);
      setDeleteTarget(null);
      await loadReleases();
    } catch (err) {
      toast({
        title: "Could not delete release",
        description: err instanceof Error ? err.message : "Try again",
        variant: "destructive",
      });
    } finally {
      setDeleting(false);
    }
  };

  const heroSummary = current
    ? getMobileNotes(current) || getAdminNotes(current) ||
      "Official Country Boy conductor app package for depot devices."
    : null;

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.3 }}
      className="space-y-8 pb-10"
    >
      <PageHeader
        title="App Releases"
        description={
          canPublish
            ? "Publish builds and document mobile + admin panel changes"
            : "Download the conductor app and review release changes"
        }
      />

      <ErrorAlert error={error} />

      <ConfirmDeleteDialog
        open={!!deleteTarget}
        onOpenChange={(open) => {
          if (!open && !deleting) setDeleteTarget(null);
        }}
        title="Delete release?"
        description={
          deleteTarget
            ? `This permanently deletes v${deleteTarget.version_name} (${deleteTarget.file_name}) from the server. This cannot be undone.`
            : ""
        }
        confirmLabel="Delete release"
        loadingLabel="Deleting…"
        loading={deleting}
        onConfirm={() => void handleDelete()}
      />

      <ConfirmDeleteDialog
        open={updateConfirmOpen}
        onOpenChange={(open) => {
          if (!open && !publishing) setUpdateConfirmOpen(false);
        }}
        title="Save release changes?"
        description={
          editingRelease
            ? `Update v${editingRelease.version_name} to v${versionName.trim() || editingRelease.version_name} (build ${versionCode || editingRelease.version_code})${selectedFile ? ` and replace the package with ${selectedFile.name}` : ""}. Super admins will see the updated notes.`
            : ""
        }
        confirmLabel="Save changes"
        loadingLabel="Saving…"
        loading={publishing}
        tone="default"
        onConfirm={() => void submitRelease()}
      />

      <ConfirmDeleteDialog
        open={publishConfirmOpen}
        onOpenChange={(open) => {
          if (!open && !publishing) setPublishConfirmOpen(false);
        }}
        title="Publish new release?"
        description={`Publish v${versionName.trim()} (build ${versionCode})${selectedFile ? ` with ${selectedFile.name}` : ""}${setAsCurrent ? " and mark it as the current download" : ""}.`}
        confirmLabel="Publish release"
        loadingLabel="Publishing…"
        loading={publishing}
        tone="default"
        onConfirm={() => void submitRelease()}
      />

      {loading ? (
        <div className="flex items-center justify-center py-20 text-muted-foreground">
          <Loader2 className="mr-2 h-5 w-5 animate-spin" />
          Loading releases…
        </div>
      ) : (
        <>
          <section className="relative overflow-hidden rounded-3xl border border-border/60 bg-gradient-to-br from-primary/10 via-background to-muted/40 shadow-sm">
            <div
              className="pointer-events-none absolute inset-0 opacity-[0.35]"
              style={{
                backgroundImage:
                  "radial-gradient(circle at 20% 20%, hsl(var(--primary) / 0.18), transparent 45%), radial-gradient(circle at 80% 0%, hsl(var(--accent) / 0.12), transparent 40%)",
              }}
            />
            <div className="relative grid gap-8 p-6 sm:p-8 lg:grid-cols-[1.2fr_0.8fr] lg:items-center">
              <div className="space-y-4">
                <div className="inline-flex items-center gap-2 rounded-full border border-border/60 bg-background/70 px-3 py-1 text-[11px] font-medium uppercase tracking-wider text-muted-foreground backdrop-blur">
                  <Smartphone className="h-3.5 w-3.5 text-primary" />
                  Conductor mobile · Android
                </div>

                {current ? (
                  <>
                    <div className="space-y-2">
                      <div className="flex flex-wrap items-center gap-2">
                        <h2 className="font-display text-3xl font-bold tracking-tight sm:text-4xl">
                          v{current.version_name}
                        </h2>
                        {current.is_current && (
                          <Badge className="gap-1 bg-success/15 text-success border-success/25 hover:bg-success/15">
                            <CheckCircle2 className="h-3 w-3" />
                            Current
                          </Badge>
                        )}
                      </div>
                      <p className="text-sm text-muted-foreground max-w-xl line-clamp-3">
                        {heroSummary}
                      </p>
                      {hasReleaseNotes(current) && (
                        <Button asChild variant="link" className="h-auto p-0 text-sm">
                          <Link to={`/app-releases/${current.id}/notes`}>Read more</Link>
                        </Button>
                      )}
                    </div>

                    <div className="flex flex-wrap gap-x-5 gap-y-2 text-xs text-muted-foreground">
                      <span>
                        Build <span className="font-medium text-foreground">{current.version_code}</span>
                      </span>
                      <span>
                        Size{" "}
                        <span className="font-medium text-foreground">
                          {formatBytes(current.file_size)}
                        </span>
                      </span>
                      <span>
                        Published{" "}
                        <span className="font-medium text-foreground">
                          {formatDate(current.created_at)}
                        </span>
                      </span>
                    </div>

                    <div className="flex flex-wrap gap-2 pt-1">
                      <Button
                        size="lg"
                        className="gap-2 shadow-md shadow-primary/20"
                        onClick={() => void handleDownload(current)}
                        disabled={downloadingId === current.id}
                      >
                        {downloadingId === current.id ? (
                          <Loader2 className="h-4 w-4 animate-spin" />
                        ) : (
                          <Download className="h-4 w-4" />
                        )}
                        Download APK
                      </Button>
                      <p className="w-full text-[11px] text-muted-foreground sm:w-auto sm:self-center">
                        {current.file_name}
                      </p>
                    </div>
                  </>
                ) : (
                  <div className="space-y-3 py-2">
                    <h2 className="font-display text-2xl font-bold tracking-tight sm:text-3xl">
                      No release published yet
                    </h2>
                    <p className="text-sm text-muted-foreground max-w-lg">
                      {canPublish
                        ? "Upload the first Android build below. Once published, you can download it anytime from this page."
                        : "No mobile app package is available yet. Check back after a developer publishes a release."}
                    </p>
                  </div>
                )}
              </div>

              <div className="hidden lg:flex justify-center">
                <div className="relative flex h-44 w-44 items-center justify-center rounded-[2rem] border border-border/50 bg-background/60 shadow-inner backdrop-blur">
                  <div className="absolute inset-4 rounded-[1.5rem] border border-dashed border-primary/25" />
                  <Package className="h-16 w-16 text-primary/80" />
                </div>
              </div>
            </div>
          </section>

          {canPublish && (
            <Card className="shadow-sm border-border/60">
              <CardHeader>
                <div className="flex items-start justify-between gap-3">
                  <div className="space-y-1.5">
                    <div className="flex items-center gap-2">
                      {editingRelease ? (
                        <Pencil className="h-4 w-4 text-primary" />
                      ) : (
                        <Upload className="h-4 w-4 text-primary" />
                      )}
                      <CardTitle className="text-base font-display">
                        {editingRelease
                          ? `Edit v${editingRelease.version_name}`
                          : "Publish new release"}
                      </CardTitle>
                    </div>
                    <CardDescription>
                      {editingRelease
                        ? "Update version details, platform notes, or replace the APK/AAB package."
                        : (
                          <>
                            Upload a signed APK or AAB and document what changed on mobile and the admin panel.
                          </>
                        )}
                    </CardDescription>
                  </div>
                  {editingRelease && (
                    <Button
                      type="button"
                      variant="ghost"
                      size="sm"
                      className="shrink-0 gap-1.5"
                      onClick={resetForm}
                      disabled={publishing}
                    >
                      <X className="h-3.5 w-3.5" />
                      Cancel
                    </Button>
                  )}
                </div>
              </CardHeader>
              <CardContent>
                <form onSubmit={handlePublish} className="space-y-4">
                  {publishError && (
                    <Alert variant="destructive">
                      <AlertCircle className="h-4 w-4" />
                      <AlertDescription>{publishError}</AlertDescription>
                    </Alert>
                  )}

                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    <div className="space-y-1.5">
                      <Label htmlFor="version-name">Version name *</Label>
                      <Input
                        id="version-name"
                        placeholder="e.g. 1.0.0"
                        value={versionName}
                        onChange={(e) => setVersionName(e.target.value)}
                        disabled={publishing}
                      />
                    </div>
                    <div className="space-y-1.5">
                      <Label htmlFor="version-code">Version code *</Label>
                      <Input
                        id="version-code"
                        type="number"
                        min={1}
                        step={1}
                        placeholder="e.g. 1"
                        value={versionCode}
                        onChange={(e) => setVersionCode(e.target.value)}
                        disabled={publishing}
                      />
                    </div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                    <div className="space-y-1.5">
                      <Label htmlFor="mobile-notes" className="flex items-center gap-1.5">
                        <Smartphone className="h-3.5 w-3.5 text-muted-foreground" />
                        Mobile app changes
                      </Label>
                      <Textarea
                        id="mobile-notes"
                        placeholder="What changed in the conductor Android app?"
                        value={mobileNotes}
                        onChange={(e) => setMobileNotes(e.target.value)}
                        disabled={publishing}
                        rows={5}
                      />
                    </div>
                    <div className="space-y-1.5">
                      <Label htmlFor="admin-notes" className="flex items-center gap-1.5">
                        <Monitor className="h-3.5 w-3.5 text-muted-foreground" />
                        Admin panel changes
                      </Label>
                      <Textarea
                        id="admin-notes"
                        placeholder="What changed on the admin web site?"
                        value={adminNotes}
                        onChange={(e) => setAdminNotes(e.target.value)}
                        disabled={publishing}
                        rows={5}
                      />
                    </div>
                  </div>

                  <div
                    className={`rounded-xl border-2 border-dashed px-4 py-6 text-center transition-colors cursor-pointer ${
                      selectedFile
                        ? "border-primary/40 bg-primary/5"
                        : "border-border/60 hover:border-primary/30 hover:bg-muted/20"
                    }`}
                    onClick={() => fileInputRef.current?.click()}
                    onDragOver={(e) => e.preventDefault()}
                    onDrop={(e) => {
                      e.preventDefault();
                      handleFileSelect(e.dataTransfer.files[0] ?? null);
                    }}
                  >
                    <input
                      ref={fileInputRef}
                      type="file"
                      accept=".apk,.aab,application/vnd.android.package-archive"
                      className="sr-only"
                      onChange={(e) => handleFileSelect(e.target.files?.[0] ?? null)}
                    />
                    <FileDown className="mx-auto mb-2 h-5 w-5 text-muted-foreground" />
                    <p className="text-sm font-medium">
                      {selectedFile
                        ? selectedFile.name
                        : editingRelease
                          ? "Drop a new APK/AAB to replace, or leave empty to keep current file"
                          : "Drop APK/AAB here or click to browse"}
                    </p>
                    <p className="mt-1 text-[11px] text-muted-foreground">
                      {selectedFile
                        ? formatBytes(selectedFile.size)
                        : editingRelease
                          ? `Current: ${editingRelease.file_name} · ${formatBytes(editingRelease.file_size)}`
                          : "Android package · Max 150 MB"}
                    </p>
                  </div>

                  <div className="flex items-center gap-2">
                    <Checkbox
                      id="set-current"
                      checked={setAsCurrent}
                      onCheckedChange={(checked) => setSetAsCurrent(checked === true)}
                      disabled={publishing}
                    />
                    <Label
                      htmlFor="set-current"
                      className="text-sm font-normal cursor-pointer text-muted-foreground"
                    >
                      {editingRelease
                        ? "Mark as current release"
                        : "Mark as current release after upload"}
                    </Label>
                  </div>

                  <Button type="submit" className="w-full gap-2" disabled={publishing}>
                    {publishing ? (
                      <Loader2 className="h-4 w-4 animate-spin" />
                    ) : editingRelease ? (
                      <Pencil className="h-4 w-4" />
                    ) : (
                      <Upload className="h-4 w-4" />
                    )}
                    {editingRelease ? "Save changes" : "Publish release"}
                  </Button>
                </form>
              </CardContent>
            </Card>
          )}

          <div className="grid gap-6 lg:grid-cols-2">
            <Card className="shadow-sm border-border/60">
              <CardHeader>
                <div className="flex items-center gap-2">
                  <Package className="h-4 w-4 text-muted-foreground" />
                  <CardTitle className="text-base font-display">Release history</CardTitle>
                </div>
                <CardDescription>
                  {canPublish
                    ? "Select a build to preview its notes. Edit, promote, or delete as needed."
                    : "Download builds and open the full changelog from What’s new."}
                </CardDescription>
              </CardHeader>
              <CardContent>
                {releases.length === 0 ? (
                  <div className="rounded-xl border border-dashed border-border/70 bg-muted/15 px-4 py-10 text-center">
                    <Package className="mx-auto mb-2 h-6 w-6 text-muted-foreground/50" />
                    <p className="text-sm text-muted-foreground">No releases yet</p>
                  </div>
                ) : (
                  <div className="space-y-2.5">
                    {[current, ...history].filter(Boolean).map((release) => {
                      if (!release) return null;
                      const isFocused = notesRelease?.id === release.id;
                      return (
                        <div
                          key={release.id}
                          className={`rounded-xl border px-3.5 py-3 transition-colors cursor-pointer ${
                            isFocused
                              ? "border-primary/40 bg-primary/5"
                              : release.is_current
                                ? "border-success/25 bg-success/5"
                                : "border-border/60 bg-card hover:bg-muted/20"
                          }`}
                          onClick={() => setNotesFocusId(release.id)}
                        >
                          <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                            <div className="min-w-0">
                              <div className="flex flex-wrap items-center gap-2">
                                <p className="font-medium text-sm">v{release.version_name}</p>
                                <span className="text-[11px] text-muted-foreground">
                                  build {release.version_code}
                                </span>
                                {release.is_current && (
                                  <Badge
                                    variant="outline"
                                    className="text-[10px] gap-1 border-success/30 text-success"
                                  >
                                    <Star className="h-2.5 w-2.5" />
                                    Current
                                  </Badge>
                                )}
                              </div>
                              <p className="mt-0.5 text-[11px] text-muted-foreground truncate">
                                {release.file_name} · {formatBytes(release.file_size)} ·{" "}
                                {formatDate(release.created_at)}
                              </p>
                            </div>

                            <div
                              className="flex flex-wrap gap-1.5 shrink-0"
                              onClick={(e) => e.stopPropagation()}
                            >
                              <Button
                                variant="outline"
                                size="sm"
                                className="gap-1.5 h-8"
                                onClick={() => void handleDownload(release)}
                                disabled={downloadingId === release.id}
                              >
                                {downloadingId === release.id ? (
                                  <Loader2 className="h-3.5 w-3.5 animate-spin" />
                                ) : (
                                  <Download className="h-3.5 w-3.5" />
                                )}
                                Download
                              </Button>
                              {canPublish && (
                                <Button
                                  variant="ghost"
                                  size="sm"
                                  className="gap-1.5 h-8"
                                  onClick={() => startEdit(release)}
                                >
                                  <Pencil className="h-3.5 w-3.5" />
                                  Edit
                                </Button>
                              )}
                              {canPublish && !release.is_current && (
                                <Button
                                  variant="ghost"
                                  size="sm"
                                  className="gap-1.5 h-8"
                                  onClick={() => void handleSetCurrent(release)}
                                  disabled={settingCurrentId === release.id}
                                >
                                  {settingCurrentId === release.id ? (
                                    <Loader2 className="h-3.5 w-3.5 animate-spin" />
                                  ) : (
                                    <Star className="h-3.5 w-3.5" />
                                  )}
                                  Set current
                                </Button>
                              )}
                              {canPublish && (
                                <Button
                                  variant="ghost"
                                  size="sm"
                                  className="h-8 text-destructive hover:text-destructive hover:bg-destructive/10"
                                  onClick={() => setDeleteTarget(release)}
                                >
                                  <Trash2 className="h-3.5 w-3.5" />
                                </Button>
                              )}
                            </div>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}
              </CardContent>
            </Card>

            <Card className="shadow-sm border-border/60">
              <CardHeader>
                <div className="flex items-start justify-between gap-3">
                  <div className="space-y-1.5">
                    <div className="flex items-center gap-2">
                      <Monitor className="h-4 w-4 text-muted-foreground" />
                      <CardTitle className="text-base font-display">What’s new</CardTitle>
                    </div>
                    <CardDescription>
                      {notesRelease
                        ? `Changes for v${notesRelease.version_name} (build ${notesRelease.version_code})`
                        : "Select a release to preview platform notes."}
                    </CardDescription>
                  </div>
                  {notesRelease && hasReleaseNotes(notesRelease) && (
                    <Button asChild variant="outline" size="sm" className="shrink-0">
                      <Link to={`/app-releases/${notesRelease.id}/notes`}>Read more</Link>
                    </Button>
                  )}
                </div>
              </CardHeader>
              <CardContent>
                {!notesRelease ? (
                  <div className="rounded-xl border border-dashed border-border/70 bg-muted/15 px-4 py-10 text-center">
                    <p className="text-sm text-muted-foreground">No release selected</p>
                  </div>
                ) : (
                  <div className="space-y-3">
                    <NotesPreviewBlock
                      title="Mobile app"
                      icon={Smartphone}
                      text={getMobileNotes(notesRelease)}
                    />
                    <NotesPreviewBlock
                      title="Admin panel"
                      icon={Monitor}
                      text={getAdminNotes(notesRelease)}
                    />
                    {!hasReleaseNotes(notesRelease) && (
                      <p className="text-xs text-muted-foreground text-center pt-1">
                        {canPublish
                          ? "Use Edit on this release to add mobile and admin notes."
                          : "No changelog notes were published for this version."}
                      </p>
                    )}
                  </div>
                )}
              </CardContent>
            </Card>
          </div>
        </>
      )}
    </motion.div>
  );
};

export default AppReleases;

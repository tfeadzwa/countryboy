import { useState, useEffect, useCallback } from "react";
import { motion } from "framer-motion";
import PageHeader from "@/components/PageHeader";
import { TableCell, TableRow } from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from "@/components/ui/dialog";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { ResponsiveTable } from "@/components/ResponsiveTable";
import ErrorAlert from "@/components/ErrorAlert";
import {
  Plus,
  UserCog,
  Loader2,
  ShieldCheck,
  Shield,
  Eye,
  EyeOff,
  Copy,
  Check,
  AlertCircle,
  Building2,
  Mail,
  User,
  KeyRound,
  Clock,
} from "lucide-react";
import { adminUsersService, AdminUserListItem, getPrimaryRoleName, isProtectedAdminRole } from "@/lib/api/adminUsers.service";
import { depotService } from "@/lib/api/depot.service";
import { Depot } from "@/types";
import { useAuth } from "@/contexts/AuthContext";
import { useToast } from "@/hooks/use-toast";
import type { AdminUserRole } from "@/lib/api/adminUsers.service";

const PRESENCE_POLL_MS = 30_000;

const ROLE_OPTIONS: { value: Exclude<AdminUserRole, "SUPER_ADMIN" | "DEVELOPER">; label: string; description: string }[] = [
  { value: "DEPOT_ADMIN", label: "Depot Admin", description: "Full access to one depot" },
  { value: "CASHIER", label: "Cashier", description: "End trips and print ticket batches; no conductors, drivers, or fleets access" },
  { value: "MANAGER", label: "Manager", description: "View and manage depot operations" },
  { value: "VIEWER", label: "Viewer", description: "Read-only access" },
];

const roleConfig: Record<string, { class: string; icon: typeof Shield }> = {
  DEVELOPER: { class: "bg-violet-500/10 text-violet-700 border border-violet-500/25 dark:text-violet-300", icon: ShieldCheck },
  SUPER_ADMIN: { class: "bg-warning/10 text-warning border border-warning/20", icon: ShieldCheck },
  DEPOT_ADMIN: { class: "bg-primary/10 text-primary border border-primary/20", icon: Shield },
  CASHIER: { class: "bg-success/10 text-success border border-success/20", icon: Shield },
  MANAGER: { class: "bg-accent/10 text-accent border border-accent/20", icon: Shield },
  VIEWER: { class: "bg-muted text-muted-foreground", icon: Shield },
};

const accountStatusConfig = {
  ACTIVE: "bg-success/10 text-success border border-success/20",
  INACTIVE: "bg-destructive/10 text-destructive border border-destructive/20",
};

const presenceConfig = {
  online: "bg-success/10 text-success border border-success/20 uppercase tracking-wide",
  offline: "bg-muted text-muted-foreground border border-border uppercase tracking-wide",
};

const columns = [
  { header: "Name" },
  { header: "Role" },
  { header: "Depot" },
  { header: "Presence" },
  { header: "Last Seen" },
  { header: "Account" },
  { header: "Actions", className: "text-right" },
];

const emptyForm = {
  username: "",
  full_name: "",
  email: "",
  role: "" as Exclude<AdminUserRole, "SUPER_ADMIN" | "DEVELOPER"> | "",
  depot_id: "",
  password: "",
};

const formatLastSeen = (value?: string | null) => {
  if (!value) return "Never";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return "Never";
  return date.toLocaleString();
};

const AdminUsers = () => {
  const { user } = useAuth();
  const { toast } = useToast();

  const [admins, setAdmins] = useState<AdminUserListItem[]>([]);
  const [depots, setDepots] = useState<Depot[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingAdmin, setEditingAdmin] = useState<AdminUserListItem | null>(null);
  const [form, setForm] = useState({ ...emptyForm });
  const [formError, setFormError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  const [credsDialog, setCredsDialog] = useState<{ username: string; password: string } | null>(null);
  const [copied, setCopied] = useState(false);
  const [resetTarget, setResetTarget] = useState<AdminUserListItem | null>(null);
  const [resettingPassword, setResettingPassword] = useState(false);
  const [resetMode, setResetMode] = useState<"generate" | "manual">("generate");
  const [resetManualPassword, setResetManualPassword] = useState("");
  const [resetShowPassword, setResetShowPassword] = useState(false);
  const [resetError, setResetError] = useState<string | null>(null);

  const openResetDialog = (admin: AdminUserListItem) => {
    if (isProtectedAdminRole(getPrimaryRoleName(admin))) return;
    setResetTarget(admin);
    setResetMode("generate");
    setResetManualPassword("");
    setResetShowPassword(false);
    setResetError(null);
  };

  const closeResetDialog = () => {
    if (resettingPassword) return;
    setResetTarget(null);
    setResetManualPassword("");
    setResetError(null);
  };

  const fetchData = useCallback(async (opts?: { silent?: boolean }) => {
    try {
      if (!opts?.silent) setLoading(true);
      setError(null);
      const [adminData, depotData] = await Promise.all([
        adminUsersService.getAll(),
        depotService.getAll(),
      ]);
      setAdmins(adminData);
      setDepots(depotData);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load data");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void fetchData();
    const id = window.setInterval(() => void fetchData({ silent: true }), PRESENCE_POLL_MS);
    return () => window.clearInterval(id);
  }, [fetchData]);

  const openCreateDialog = () => {
    setEditingAdmin(null);
    setForm({ ...emptyForm });
    setFormError(null);
    setShowPassword(false);
    setDialogOpen(true);
  };

  const openEditDialog = (admin: AdminUserListItem) => {
    if (isProtectedAdminRole(getPrimaryRoleName(admin))) return;
    setEditingAdmin(admin);
    const primaryRole = getPrimaryRoleName(admin);
    setForm({
      username: admin.username,
      full_name: admin.full_name,
      email: admin.email ?? "",
      role: isProtectedAdminRole(primaryRole)
        ? ""
        : (primaryRole as Exclude<AdminUserRole, "SUPER_ADMIN" | "DEVELOPER">),
      depot_id: admin.depot_id ?? "",
      password: "",
    });
    setFormError(null);
    setShowPassword(false);
    setDialogOpen(true);
  };

  const closeDialog = () => {
    setDialogOpen(false);
    setEditingAdmin(null);
  };

  const handleSave = async () => {
    setFormError(null);

    if (!form.full_name.trim()) return setFormError("Full name is required");
    if (!form.role) return setFormError("Role is required");
    if (!editingAdmin && !form.username.trim()) return setFormError("Username is required");
    if (
      (form.role === "DEPOT_ADMIN" || form.role === "CASHIER" || form.role === "MANAGER" || form.role === "VIEWER") &&
      !form.depot_id
    ) {
      return setFormError("Depot is required for this role");
    }

    setSaving(true);
    try {
      if (editingAdmin) {
        await adminUsersService.update(editingAdmin.id, {
          full_name: form.full_name.trim(),
          email: form.email.trim() || null,
          role: form.role as Exclude<AdminUserRole, "SUPER_ADMIN" | "DEVELOPER">,
          depot_id: form.depot_id || null,
        });
        toast({ title: "Admin updated", description: `${form.full_name} has been updated.` });
      } else {
        const result = await adminUsersService.create({
          username: form.username.trim(),
          full_name: form.full_name.trim(),
          email: form.email.trim() || undefined,
          role: form.role as Exclude<AdminUserRole, "SUPER_ADMIN" | "DEVELOPER">,
          depot_id: form.depot_id || undefined,
          password: form.password.trim() || undefined,
        });

        if (result.temporaryPassword) {
          setCredsDialog({ username: result.username, password: result.temporaryPassword });
        }

        toast({ title: "Admin created", description: `${result.full_name} has been added.` });
      }

      await fetchData();
      closeDialog();
    } catch (err) {
      setFormError(err instanceof Error ? err.message : "Failed to save");
    } finally {
      setSaving(false);
    }
  };

  const handleToggleStatus = async (admin: AdminUserListItem) => {
    const newStatus = admin.status === "ACTIVE" ? "INACTIVE" : "ACTIVE";
    try {
      await adminUsersService.update(admin.id, { status: newStatus });
      toast({
        title: newStatus === "ACTIVE" ? "Account activated" : "Account deactivated",
        description: `${admin.full_name}'s account is now ${newStatus.toLowerCase()}.`,
      });
      await fetchData();
    } catch (err) {
      toast({
        title: "Action failed",
        description: err instanceof Error ? err.message : "Failed to update status",
        variant: "destructive",
      });
    }
  };

  const handleResetPasswordConfirm = async () => {
    if (!resetTarget) return;
    setResetError(null);

    const manual = resetManualPassword.trim();
    if (resetMode === "manual") {
      if (manual.length < 8) {
        setResetError("Password must be at least 8 characters");
        return;
      }
    }

    setResettingPassword(true);
    try {
      const result = await adminUsersService.resetPassword(
        resetTarget.id,
        resetMode === "manual" ? manual : undefined,
      );
      setResetTarget(null);
      setResetManualPassword("");
      setCredsDialog({
        username: result.username,
        password: result.temporaryPassword,
      });
      toast({
        title: "Password reset",
        description:
          resetMode === "manual"
            ? `Password updated for ${result.full_name}.`
            : `A new temporary password was generated for ${result.full_name}.`,
      });
    } catch (err) {
      setResetError(err instanceof Error ? err.message : "Failed to reset password");
    } finally {
      setResettingPassword(false);
    }
  };

  const handleCopyPassword = async (password: string) => {
    await navigator.clipboard.writeText(password);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const RoleBadge = ({ roleName }: { roleName: string }) => {
    const cfg = roleConfig[roleName] ?? roleConfig.VIEWER;
    const Icon = cfg.icon;
    return (
      <Badge className={`text-xs gap-1.5 ${cfg.class}`}>
        <Icon className="h-3 w-3" />
        {roleName.replace("_", " ")}
      </Badge>
    );
  };

  const currentUserId = user?.id;
  const selectedRole = ROLE_OPTIONS.find((r) => r.value === form.role);

  if (loading) {
    return (
      <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.3 }}>
        <PageHeader title="Admins" description="Manage system administrators and their access" />
        <div className="flex items-center justify-center py-12">
          <div className="flex flex-col items-center gap-3">
            <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
            <p className="text-sm text-muted-foreground">Loading admin users…</p>
          </div>
        </div>
      </motion.div>
    );
  }

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.3 }}>
      <PageHeader title="Admins" description="Manage system administrators and their access">
        <Button size="sm" className="gap-2 shadow-sm" onClick={openCreateDialog}>
          <Plus className="h-4 w-4" /> Add Admin
        </Button>
      </PageHeader>

      <ErrorAlert error={error} />

      <Dialog open={dialogOpen} onOpenChange={(open) => { if (!open) closeDialog(); }}>
        <DialogContent className="sm:max-w-[520px] gap-0 p-0 overflow-hidden max-h-[90vh] flex flex-col">
          <DialogHeader className="px-6 pt-6 pb-4 space-y-3 border-b border-border/60">
            <div className="flex items-start gap-3">
              <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-primary/10">
                <UserCog className="h-5 w-5 text-primary" />
              </div>
              <div className="min-w-0 flex-1 pt-0.5">
                <DialogTitle className="text-left text-lg leading-tight">
                  {editingAdmin ? "Edit Admin User" : "Add Admin User"}
                </DialogTitle>
                <DialogDescription className="text-left text-sm mt-1">
                  {editingAdmin
                    ? "Update this administrator’s profile, role, and depot access."
                    : "Create a depot administrator account. Leave password blank to auto-generate one."}
                </DialogDescription>
              </div>
            </div>
          </DialogHeader>

          <div className="px-6 py-4 space-y-5 overflow-y-auto">
            {formError && (
              <Alert variant="destructive" className="py-2.5">
                <AlertCircle className="h-4 w-4" />
                <AlertDescription className="text-sm">{formError}</AlertDescription>
              </Alert>
            )}

            <section className="space-y-3">
              <p className="text-[11px] font-semibold uppercase tracking-wide text-muted-foreground">
                Profile
              </p>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                {editingAdmin ? (
                  <div className="space-y-1.5 sm:col-span-2">
                    <Label htmlFor="au-username" className="text-sm">
                      Username
                    </Label>
                    <div className="relative">
                      <User className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                      <Input
                        id="au-username"
                        value={form.username}
                        className="pl-9 font-mono bg-muted/40"
                        disabled
                        readOnly
                      />
                    </div>
                    <p className="text-xs text-muted-foreground">
                      Username cannot be changed after the account is created.
                    </p>
                  </div>
                ) : (
                  <div className="space-y-1.5 sm:col-span-2">
                    <Label htmlFor="au-username" className="text-sm">
                      Username <span className="text-destructive">*</span>
                    </Label>
                    <div className="relative">
                      <User className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                      <Input
                        id="au-username"
                        placeholder="e.g. admin.harare"
                        value={form.username}
                        onChange={(e) => setForm((f) => ({ ...f, username: e.target.value.toLowerCase() }))}
                        className="pl-9 font-mono"
                        disabled={saving}
                      />
                    </div>
                  </div>
                )}

                <div className="space-y-1.5 sm:col-span-2">
                  <Label htmlFor="au-fullname" className="text-sm">
                    Full name <span className="text-destructive">*</span>
                  </Label>
                  <Input
                    id="au-fullname"
                    placeholder="e.g. John Moyo"
                    value={form.full_name}
                    onChange={(e) => setForm((f) => ({ ...f, full_name: e.target.value }))}
                    disabled={saving}
                  />
                </div>

                <div className="space-y-1.5 sm:col-span-2">
                  <Label htmlFor="au-email" className="text-sm">
                    Email
                  </Label>
                  <div className="relative">
                    <Mail className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                    <Input
                      id="au-email"
                      type="email"
                      placeholder="admin@example.com"
                      value={form.email}
                      onChange={(e) => setForm((f) => ({ ...f, email: e.target.value }))}
                      className="pl-9"
                      disabled={saving}
                    />
                  </div>
                </div>
              </div>
            </section>

            <section className="space-y-3">
              <p className="text-[11px] font-semibold uppercase tracking-wide text-muted-foreground">
                Access
              </p>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div className="space-y-1.5">
                  <Label className="text-sm">
                    Role <span className="text-destructive">*</span>
                  </Label>
                  <Select
                    value={form.role}
                    onValueChange={(v) => setForm((f) => ({ ...f, role: v as typeof form.role }))}
                    disabled={saving}
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="Select a role" />
                    </SelectTrigger>
                    <SelectContent>
                      {ROLE_OPTIONS.map((r) => (
                        <SelectItem key={r.value} value={r.value}>
                          {r.label}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  {selectedRole && (
                    <p className="text-xs text-muted-foreground">{selectedRole.description}</p>
                  )}
                </div>

                <div className="space-y-1.5">
                  <Label className="text-sm">Depot</Label>
                  <Select
                    value={form.depot_id || "_none"}
                    onValueChange={(v) => setForm((f) => ({ ...f, depot_id: v === "_none" ? "" : v }))}
                    disabled={saving}
                  >
                    <SelectTrigger>
                      <SelectValue placeholder="Select a depot" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="_none">
                        <span className="text-muted-foreground">No depot (system-wide)</span>
                      </SelectItem>
                      {depots.map((d) => (
                        <SelectItem key={d.id} value={d.id}>
                          {d.name} ({d.merchant_code})
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  <p className="text-xs text-muted-foreground flex items-center gap-1">
                    <Building2 className="h-3 w-3" />
                    Usually assign one depot for depot admins
                  </p>
                </div>
              </div>
            </section>

            {!editingAdmin && (
              <section className="space-y-3">
                <p className="text-[11px] font-semibold uppercase tracking-wide text-muted-foreground">
                  Password
                </p>
                <div className="space-y-1.5">
                  <Label htmlFor="au-password" className="text-sm">
                    Temporary password
                  </Label>
                  <div className="relative">
                    <KeyRound className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                    <Input
                      id="au-password"
                      type={showPassword ? "text" : "password"}
                      placeholder="Leave blank to auto-generate"
                      value={form.password}
                      onChange={(e) => setForm((f) => ({ ...f, password: e.target.value }))}
                      className="pl-9 pr-10"
                      disabled={saving}
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword((v) => !v)}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground/70 hover:text-foreground transition-colors"
                      aria-label={showPassword ? "Hide password" : "Show password"}
                    >
                      {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                    </button>
                  </div>
                  <p className="text-xs text-muted-foreground">
                    If left blank, a temporary password is generated and shown once after create.
                  </p>
                </div>
              </section>
            )}
          </div>

          <DialogFooter className="gap-2 px-6 py-4 border-t border-border/60 bg-muted/20">
            <Button variant="outline" onClick={closeDialog} disabled={saving}>
              Cancel
            </Button>
            <Button onClick={handleSave} disabled={saving} className="gap-2 min-w-[140px]">
              {saving ? (
                <>
                  <Loader2 className="h-4 w-4 animate-spin" />
                  {editingAdmin ? "Saving…" : "Creating…"}
                </>
              ) : editingAdmin ? (
                "Save changes"
              ) : (
                "Create admin"
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog
        open={!!credsDialog}
        onOpenChange={(open) => {
          if (!open) {
            setCredsDialog(null);
            setCopied(false);
          }
        }}
      >
        <DialogContent className="sm:max-w-sm">
          <DialogHeader>
            <div className="mx-auto mb-2 flex h-12 w-12 items-center justify-center rounded-full bg-success/10">
              <ShieldCheck className="h-6 w-6 text-success" />
            </div>
            <DialogTitle className="text-center">Temporary password</DialogTitle>
            <DialogDescription className="text-center">
              Share these credentials securely. The password will not be shown again.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-3 py-2">
            <div className="rounded-xl bg-muted/40 border border-border/60 px-4 py-3 space-y-2 text-sm">
              <div className="flex justify-between gap-3">
                <span className="text-muted-foreground">Username</span>
                <span className="font-mono font-semibold">{credsDialog?.username}</span>
              </div>
              <div className="flex justify-between items-center gap-3">
                <span className="text-muted-foreground">Password</span>
                <div className="flex items-center gap-2">
                  <span className="font-mono font-semibold">{credsDialog?.password}</span>
                  <button
                    onClick={() => credsDialog && handleCopyPassword(credsDialog.password)}
                    className="text-muted-foreground hover:text-foreground transition-colors"
                    aria-label="Copy password"
                  >
                    {copied ? <Check className="h-3.5 w-3.5 text-success" /> : <Copy className="h-3.5 w-3.5" />}
                  </button>
                </div>
              </div>
            </div>
            <p className="text-xs text-muted-foreground text-center">
              The admin should sign in with this password and change it if needed.
            </p>
          </div>

          <DialogFooter>
            <Button
              className="w-full"
              onClick={() => {
                setCredsDialog(null);
                setCopied(false);
              }}
            >
              Done
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog
        open={!!resetTarget}
        onOpenChange={(open) => {
          if (!open) closeResetDialog();
        }}
      >
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Reset password</DialogTitle>
            <DialogDescription>
              Set a new password for{" "}
              <strong>
                {resetTarget?.full_name} ({resetTarget?.username})
              </strong>
              . Their current password will stop working immediately.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-1">
            {resetError && (
              <Alert variant="destructive" className="py-2.5">
                <AlertCircle className="h-4 w-4" />
                <AlertDescription className="text-sm">{resetError}</AlertDescription>
              </Alert>
            )}

            <div className="space-y-2">
              <button
                type="button"
                onClick={() => {
                  setResetMode("generate");
                  setResetError(null);
                }}
                className={`w-full rounded-lg border px-3 py-3 text-left transition-colors ${
                  resetMode === "generate"
                    ? "border-primary bg-primary/5"
                    : "border-border/60 hover:bg-muted/30"
                }`}
                disabled={resettingPassword}
              >
                <p className="text-sm font-medium">Generate temporary password</p>
                <p className="text-xs text-muted-foreground mt-0.5">
                  Create a strong password automatically and show it once.
                </p>
              </button>
              <button
                type="button"
                onClick={() => {
                  setResetMode("manual");
                  setResetError(null);
                }}
                className={`w-full rounded-lg border px-3 py-3 text-left transition-colors ${
                  resetMode === "manual"
                    ? "border-primary bg-primary/5"
                    : "border-border/60 hover:bg-muted/30"
                }`}
                disabled={resettingPassword}
              >
                <p className="text-sm font-medium">Set password manually</p>
                <p className="text-xs text-muted-foreground mt-0.5">
                  Enter a password yourself (minimum 8 characters).
                </p>
              </button>
            </div>

            {resetMode === "manual" && (
              <div className="space-y-2">
                <Label htmlFor="reset-manual-password">New password</Label>
                <div className="relative">
                  <Input
                    id="reset-manual-password"
                    type={resetShowPassword ? "text" : "password"}
                    value={resetManualPassword}
                    onChange={(e) => setResetManualPassword(e.target.value)}
                    placeholder="At least 8 characters"
                    className="pr-10"
                    disabled={resettingPassword}
                    autoFocus
                  />
                  <button
                    type="button"
                    onClick={() => setResetShowPassword((v) => !v)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground/70 hover:text-foreground transition-colors"
                    aria-label={resetShowPassword ? "Hide password" : "Show password"}
                  >
                    {resetShowPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                  </button>
                </div>
              </div>
            )}
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={closeResetDialog} disabled={resettingPassword}>
              Cancel
            </Button>
            <Button onClick={handleResetPasswordConfirm} disabled={resettingPassword}>
              {resettingPassword ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Resetting…
                </>
              ) : (
                <>
                  <KeyRound className="mr-2 h-4 w-4" />
                  Reset password
                </>
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <ResponsiveTable
        columns={columns}
        data={admins}
        keyExtractor={(a) => a.id}
        renderRow={(a) => {
          const roleName = getPrimaryRoleName(a);
          const isCurrentUser = a.id === currentUserId;
          const canOpen = !isProtectedAdminRole(roleName);
          return (
            <TableRow
              key={a.id}
              className={`group hover:bg-muted/30 transition-colors ${canOpen ? "cursor-pointer" : ""}`}
              onClick={() => {
                if (canOpen) openEditDialog(a);
              }}
            >
              <TableCell>
                <div className="flex items-center gap-2.5">
                  <div className="h-8 w-8 rounded-full bg-primary/10 flex items-center justify-center text-[11px] font-bold text-primary">
                    {a.full_name
                      .split(" ")
                      .map((n) => n[0])
                      .join("")
                      .toUpperCase()
                      .slice(0, 2)}
                  </div>
                  <div>
                    <p className="font-medium text-sm">{a.full_name}</p>
                    {a.email && <p className="text-xs text-muted-foreground">{a.email}</p>}
                    {isCurrentUser && <span className="text-[10px] text-accent font-semibold">You</span>}
                  </div>
                </div>
              </TableCell>
              <TableCell>
                <RoleBadge roleName={roleName} />
              </TableCell>
              <TableCell className="text-sm text-muted-foreground">
                {a.depot ? (
                  <span>
                    {a.depot.name}{" "}
                    <span className="text-xs opacity-60">({a.depot.merchant_code})</span>
                  </span>
                ) : (
                  <span className="text-muted-foreground/50 text-xs italic">All depots</span>
                )}
              </TableCell>
              <TableCell>
                <Badge className={`text-xs ${a.is_online ? presenceConfig.online : presenceConfig.offline}`}>
                  {a.is_online ? "Online" : "Offline"}
                </Badge>
              </TableCell>
              <TableCell>
                <span className="flex items-center gap-1.5 text-sm text-muted-foreground">
                  <Clock className="h-3.5 w-3.5 shrink-0" />
                  {formatLastSeen(a.last_seen_at)}
                </span>
              </TableCell>
              <TableCell>
                <Badge className={`text-xs gap-1.5 ${accountStatusConfig[a.status]}`}>
                  <span
                    className={`h-1.5 w-1.5 rounded-full ${
                      a.status === "ACTIVE" ? "bg-success" : "bg-destructive"
                    }`}
                  />
                  {a.status}
                </Badge>
              </TableCell>
              <TableCell className="text-right space-x-1" onClick={(e) => e.stopPropagation()}>
                {canOpen && !isCurrentUser && (
                  <>
                    <Button
                      variant="ghost"
                      size="sm"
                      className="text-orange-700 hover:text-orange-800 hover:bg-orange-500/10"
                      onClick={() => openResetDialog(a)}
                    >
                      <KeyRound className="h-3.5 w-3.5 mr-1" />
                      Reset password
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      className={
                        a.status === "ACTIVE"
                          ? "text-destructive hover:text-destructive hover:bg-destructive/10"
                          : "text-success hover:text-success hover:bg-success/10"
                      }
                      onClick={() => handleToggleStatus(a)}
                    >
                      {a.status === "ACTIVE" ? "Deactivate" : "Activate"}
                    </Button>
                  </>
                )}
                {isProtectedAdminRole(roleName) && (
                  <span className="text-xs text-muted-foreground/50 pr-2">Protected</span>
                )}
              </TableCell>
            </TableRow>
          );
        }}
        renderCard={(a) => {
          const roleName = getPrimaryRoleName(a);
          const isCurrentUser = a.id === currentUserId;
          const canOpen = !isProtectedAdminRole(roleName);
          return (
            <div
              className={`space-y-3 ${canOpen ? "cursor-pointer" : ""}`}
              onClick={() => {
                if (canOpen) openEditDialog(a);
              }}
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2.5">
                  <div className="h-9 w-9 rounded-full bg-primary/10 flex items-center justify-center text-[11px] font-bold text-primary">
                    {a.full_name
                      .split(" ")
                      .map((n) => n[0])
                      .join("")
                      .toUpperCase()
                      .slice(0, 2)}
                  </div>
                  <div>
                    <div className="flex items-center gap-1">
                      <p className="font-medium text-sm">{a.full_name}</p>
                      {isCurrentUser && (
                        <span className="text-[10px] text-accent font-semibold">(You)</span>
                      )}
                    </div>
                    {a.email && (
                      <p className="text-xs text-muted-foreground truncate max-w-[180px]">{a.email}</p>
                    )}
                  </div>
                </div>
                <div className="flex flex-col items-end gap-1">
                  <Badge className={`text-xs ${a.is_online ? presenceConfig.online : presenceConfig.offline}`}>
                    {a.is_online ? "Online" : "Offline"}
                  </Badge>
                  <Badge className={`text-xs gap-1.5 ${accountStatusConfig[a.status]}`}>
                    <span
                      className={`h-1.5 w-1.5 rounded-full ${
                        a.status === "ACTIVE" ? "bg-success" : "bg-destructive"
                      }`}
                    />
                    {a.status}
                  </Badge>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-2 text-sm">
                <div>
                  <p className="text-muted-foreground text-xs">Role</p>
                  <RoleBadge roleName={roleName} />
                </div>
                <div>
                  <p className="text-muted-foreground text-xs">Depot</p>
                  <p className="text-sm font-medium">
                    {a.depot ? (
                      a.depot.name
                    ) : (
                      <span className="text-muted-foreground/50 italic text-xs">All depots</span>
                    )}
                  </p>
                </div>
                <div className="col-span-2">
                  <p className="text-muted-foreground text-xs">Last seen</p>
                  <p className="text-sm font-medium flex items-center gap-1.5">
                    <Clock className="h-3.5 w-3.5 text-muted-foreground" />
                    {formatLastSeen(a.last_seen_at)}
                  </p>
                </div>
              </div>

              {canOpen && !isCurrentUser && (
                <div
                  className="flex flex-wrap items-center justify-end gap-2 pt-2 border-t border-border/40"
                  onClick={(e) => e.stopPropagation()}
                >
                  <Button
                    variant="ghost"
                    size="sm"
                    className="text-orange-700 hover:text-orange-800"
                    onClick={() => openResetDialog(a)}
                  >
                    <KeyRound className="h-3.5 w-3.5 mr-1" />
                    Reset password
                  </Button>
                  <Button
                    variant="ghost"
                    size="sm"
                    className={
                      a.status === "ACTIVE"
                        ? "text-destructive hover:text-destructive"
                        : "text-success hover:text-success"
                    }
                    onClick={() => handleToggleStatus(a)}
                  >
                    {a.status === "ACTIVE" ? "Deactivate" : "Activate"}
                  </Button>
                </div>
              )}
              {isProtectedAdminRole(roleName) && (
                <p className="text-xs text-muted-foreground/50 text-right pt-1">Protected</p>
              )}
            </div>
          );
        }}
      />
    </motion.div>
  );
};

export default AdminUsers;

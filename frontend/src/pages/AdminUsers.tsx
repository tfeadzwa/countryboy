import { useState, useEffect } from "react";
import { motion } from "framer-motion";
import PageHeader from "@/components/PageHeader";
import { TableCell, TableRow } from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from "@/components/ui/dialog";
import { ResponsiveTable } from "@/components/ResponsiveTable";
import ErrorAlert from "@/components/ErrorAlert";
import { Plus, UserCog, Loader2, ShieldCheck, Shield, Eye, EyeOff, Copy, Check } from "lucide-react";
import { adminUsersService, AdminUserListItem, getPrimaryRoleName } from "@/lib/api/adminUsers.service";
import { depotService } from "@/lib/api/depot.service";
import { Depot } from "@/types";
import { useAuth } from "@/contexts/AuthContext";
import { useToast } from "@/hooks/use-toast";
import type { AdminUserRole } from "@/lib/api/adminUsers.service";

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const ROLE_OPTIONS: { value: Exclude<AdminUserRole, 'SUPER_ADMIN'>; label: string; description: string }[] = [
  { value: 'DEPOT_ADMIN', label: 'Depot Admin', description: 'Full access to one depot' },
  { value: 'MANAGER', label: 'Manager', description: 'View and manage depot operations' },
  { value: 'VIEWER', label: 'Viewer', description: 'Read-only access' },
];

const roleConfig: Record<string, { class: string; icon: typeof Shield }> = {
  SUPER_ADMIN: { class: 'bg-warning/10 text-warning border border-warning/20', icon: ShieldCheck },
  DEPOT_ADMIN: { class: 'bg-primary/10 text-primary border border-primary/20', icon: Shield },
  MANAGER: { class: 'bg-accent/10 text-accent border border-accent/20', icon: Shield },
  VIEWER: { class: 'bg-muted text-muted-foreground', icon: Shield },
};

const statusConfig = {
  ACTIVE: 'bg-success/10 text-success border border-success/20',
  INACTIVE: 'bg-destructive/10 text-destructive border border-destructive/20',
};

const columns = [
  { header: 'Name' },
  { header: 'Username' },
  { header: 'Role' },
  { header: 'Depot' },
  { header: 'Status' },
  { header: 'Actions', className: 'text-right' },
];

// ---------------------------------------------------------------------------
// Empty form state
// ---------------------------------------------------------------------------

const emptyForm = {
  username: '',
  full_name: '',
  email: '',
  role: '' as Exclude<AdminUserRole, 'SUPER_ADMIN'> | '',
  depot_id: '',
  password: '',
};

// ---------------------------------------------------------------------------
// Page component
// ---------------------------------------------------------------------------

const AdminUsers = () => {
  const { user } = useAuth();
  const { toast } = useToast();

  const [admins, setAdmins] = useState<AdminUserListItem[]>([]);
  const [depots, setDepots] = useState<Depot[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Form dialog
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingAdmin, setEditingAdmin] = useState<AdminUserListItem | null>(null);
  const [form, setForm] = useState({ ...emptyForm });
  const [formError, setFormError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  // Credentials reveal dialog (after create)
  const [credsDialog, setCredsDialog] = useState<{ username: string; password: string } | null>(null);
  const [copied, setCopied] = useState(false);

  // ---------------------------------------------------------------------------
  // Data loading
  // ---------------------------------------------------------------------------

  const fetchData = async () => {
    try {
      setLoading(true);
      setError(null);
      const [adminData, depotData] = await Promise.all([
        adminUsersService.getAll(),
        depotService.getAll(),
      ]);
      setAdmins(adminData);
      setDepots(depotData);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load data');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  // ---------------------------------------------------------------------------
  // Dialog helpers
  // ---------------------------------------------------------------------------

  const openCreateDialog = () => {
    setEditingAdmin(null);
    setForm({ ...emptyForm });
    setFormError(null);
    setShowPassword(false);
    setDialogOpen(true);
  };

  const openEditDialog = (admin: AdminUserListItem) => {
    setEditingAdmin(admin);
    const primaryRole = getPrimaryRoleName(admin);
    setForm({
      username: admin.username,
      full_name: admin.full_name,
      email: admin.email ?? '',
      role: primaryRole === 'SUPER_ADMIN' ? '' : primaryRole,
      depot_id: admin.depot_id ?? '',
      password: '',
    });
    setFormError(null);
    setShowPassword(false);
    setDialogOpen(true);
  };

  const closeDialog = () => {
    setDialogOpen(false);
    setEditingAdmin(null);
  };

  // ---------------------------------------------------------------------------
  // Form submission
  // ---------------------------------------------------------------------------

  const handleSave = async () => {
    setFormError(null);

    if (!form.full_name.trim()) return setFormError('Full name is required');
    if (!form.role) return setFormError('Role is required');
    if (!editingAdmin && !form.username.trim()) return setFormError('Username is required');

    setSaving(true);
    try {
      if (editingAdmin) {
        // Edit mode
        await adminUsersService.update(editingAdmin.id, {
          full_name: form.full_name.trim(),
          email: form.email.trim() || null,
          role: form.role as Exclude<AdminUserRole, 'SUPER_ADMIN'>,
          depot_id: form.depot_id || null,
        });
        toast({ title: 'Admin updated', description: `${form.full_name} has been updated.` });
      } else {
        // Create mode
        const result = await adminUsersService.create({
          username: form.username.trim(),
          full_name: form.full_name.trim(),
          email: form.email.trim() || undefined,
          role: form.role as Exclude<AdminUserRole, 'SUPER_ADMIN'>,
          depot_id: form.depot_id || undefined,
          password: form.password.trim() || undefined,
        });

        // Show credentials if a temp password was generated
        if (result.temporaryPassword) {
          setCredsDialog({ username: result.username, password: result.temporaryPassword });
        }

        toast({ title: 'Admin created', description: `${result.full_name} has been added.` });
      }

      await fetchData();
      closeDialog();
    } catch (err) {
      setFormError(err instanceof Error ? err.message : 'Failed to save');
    } finally {
      setSaving(false);
    }
  };

  const handleToggleStatus = async (admin: AdminUserListItem) => {
    const newStatus = admin.status === 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
    try {
      await adminUsersService.update(admin.id, { status: newStatus });
      toast({
        title: newStatus === 'ACTIVE' ? 'Account activated' : 'Account deactivated',
        description: `${admin.full_name}'s account is now ${newStatus.toLowerCase()}.`,
      });
      await fetchData();
    } catch (err) {
      toast({
        title: 'Action failed',
        description: err instanceof Error ? err.message : 'Failed to update status',
        variant: 'destructive',
      });
    }
  };

  const handleCopyPassword = async (password: string) => {
    await navigator.clipboard.writeText(password);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  // ---------------------------------------------------------------------------
  // Render helpers
  // ---------------------------------------------------------------------------

  const RoleBadge = ({ roleName }: { roleName: string }) => {
    const cfg = roleConfig[roleName] ?? roleConfig.VIEWER;
    const Icon = cfg.icon;
    return (
      <Badge className={`text-xs gap-1.5 ${cfg.class}`}>
        <Icon className="h-3 w-3" />
        {roleName.replace('_', ' ')}
      </Badge>
    );
  };

  const currentUserId = user?.id;

  // ---------------------------------------------------------------------------
  // Loading state
  // ---------------------------------------------------------------------------

  if (loading) {
    return (
      <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.3 }}>
        <PageHeader title="Admin Users" description="Manage system administrators and their access" />
        <div className="flex items-center justify-center py-12">
          <div className="flex flex-col items-center gap-3">
            <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
            <p className="text-sm text-muted-foreground">Loading admin users…</p>
          </div>
        </div>
      </motion.div>
    );
  }

  // ---------------------------------------------------------------------------
  // Main render
  // ---------------------------------------------------------------------------

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.3 }}>
      <PageHeader title="Admin Users" description="Manage system administrators and their access">
        <Button size="sm" className="gap-2 shadow-sm" onClick={openCreateDialog}>
          <Plus className="h-4 w-4" /> Add Admin
        </Button>
      </PageHeader>

      <ErrorAlert error={error} />

      {/* ------------------------------------------------------------------ */}
      {/* Create / Edit dialog                                                */}
      {/* ------------------------------------------------------------------ */}
      <Dialog open={dialogOpen} onOpenChange={(open) => { if (!open) closeDialog(); }}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>{editingAdmin ? 'Edit Admin User' : 'Add Admin User'}</DialogTitle>
            <DialogDescription>
              {editingAdmin
                ? 'Update this administrator\'s details and role.'
                : 'Create a new administrator account. A temporary password will be generated if you leave the password field empty.'}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-2">
            {formError && (
              <div className="rounded-lg bg-destructive/10 border border-destructive/30 px-3 py-2 text-sm text-destructive">
                {formError}
              </div>
            )}

            {/* Username (create only) */}
            {!editingAdmin && (
              <div className="space-y-1.5">
                <Label htmlFor="au-username" className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                  Username <span className="text-destructive">*</span>
                </Label>
                <Input
                  id="au-username"
                  placeholder="e.g. admin.harare"
                  value={form.username}
                  onChange={(e) => setForm((f) => ({ ...f, username: e.target.value.toLowerCase() }))}
                  className="h-10 rounded-xl bg-muted/30 border-border/60 focus:bg-background focus:border-[hsl(var(--accent))]"
                  disabled={saving}
                />
              </div>
            )}

            {/* Full name */}
            <div className="space-y-1.5">
              <Label htmlFor="au-fullname" className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                Full Name <span className="text-destructive">*</span>
              </Label>
              <Input
                id="au-fullname"
                placeholder="e.g. John Moyo"
                value={form.full_name}
                onChange={(e) => setForm((f) => ({ ...f, full_name: e.target.value }))}
                className="h-10 rounded-xl bg-muted/30 border-border/60 focus:bg-background focus:border-[hsl(var(--accent))]"
                disabled={saving}
              />
            </div>

            {/* Email */}
            <div className="space-y-1.5">
              <Label htmlFor="au-email" className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                Email
              </Label>
              <Input
                id="au-email"
                type="email"
                placeholder="admin@example.com"
                value={form.email}
                onChange={(e) => setForm((f) => ({ ...f, email: e.target.value }))}
                className="h-10 rounded-xl bg-muted/30 border-border/60 focus:bg-background focus:border-[hsl(var(--accent))]"
                disabled={saving}
              />
            </div>

            {/* Role */}
            <div className="space-y-1.5">
              <Label className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                Role <span className="text-destructive">*</span>
              </Label>
              <Select
                value={form.role}
                onValueChange={(v) => setForm((f) => ({ ...f, role: v as typeof form.role }))}
                disabled={saving}
              >
                <SelectTrigger className="h-10 rounded-xl bg-muted/30 border-border/60">
                  <SelectValue placeholder="Select a role" />
                </SelectTrigger>
                <SelectContent>
                  {ROLE_OPTIONS.map((r) => (
                    <SelectItem key={r.value} value={r.value}>
                      <div>
                        <span className="font-medium">{r.label}</span>
                        <span className="text-muted-foreground text-xs ml-2">— {r.description}</span>
                      </div>
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            {/* Depot */}
            <div className="space-y-1.5">
              <Label className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                Depot
              </Label>
              <Select
                value={form.depot_id || '_none'}
                onValueChange={(v) => setForm((f) => ({ ...f, depot_id: v === '_none' ? '' : v }))}
                disabled={saving}
              >
                <SelectTrigger className="h-10 rounded-xl bg-muted/30 border-border/60">
                  <SelectValue placeholder="Select a depot" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="_none">
                    <span className="text-muted-foreground">No depot (system-wide)</span>
                  </SelectItem>
                  {depots.map((d) => (
                    <SelectItem key={d.id} value={d.id}>
                      {d.name} <span className="text-muted-foreground text-xs ml-1">({d.merchant_code})</span>
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            {/* Password (create only) */}
            {!editingAdmin && (
              <div className="space-y-1.5">
                <Label htmlFor="au-password" className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                  Password
                  <span className="ml-1.5 text-muted-foreground/60 normal-case font-normal">(leave blank to auto-generate)</span>
                </Label>
                <div className="relative">
                  <Input
                    id="au-password"
                    type={showPassword ? 'text' : 'password'}
                    placeholder="Min 8 characters"
                    value={form.password}
                    onChange={(e) => setForm((f) => ({ ...f, password: e.target.value }))}
                    className="h-10 pr-10 rounded-xl bg-muted/30 border-border/60 focus:bg-background focus:border-[hsl(var(--accent))] appearance-none"
                    disabled={saving}
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword((v) => !v)}
                    className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground/70 hover:text-foreground transition-colors"
                    aria-label={showPassword ? 'Hide password' : 'Show password'}
                  >
                    {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                  </button>
                </div>
              </div>
            )}
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={closeDialog} disabled={saving}>Cancel</Button>
            <Button onClick={handleSave} disabled={saving}>
              {saving ? (
                <span className="flex items-center gap-2">
                  <Loader2 className="h-4 w-4 animate-spin" />
                  {editingAdmin ? 'Saving…' : 'Creating…'}
                </span>
              ) : (
                editingAdmin ? 'Save Changes' : 'Create Admin'
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* ------------------------------------------------------------------ */}
      {/* Temporary credentials dialog                                        */}
      {/* ------------------------------------------------------------------ */}
      <Dialog open={!!credsDialog} onOpenChange={(open) => { if (!open) { setCredsDialog(null); setCopied(false); } }}>
        <DialogContent className="sm:max-w-sm">
          <DialogHeader>
            <div className="mx-auto mb-2 flex h-12 w-12 items-center justify-center rounded-full bg-success/10">
              <ShieldCheck className="h-6 w-6 text-success" />
            </div>
            <DialogTitle className="text-center">Admin Account Created</DialogTitle>
            <DialogDescription className="text-center">
              Share these credentials with the new administrator securely. The password will not be shown again.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-3 py-2">
            <div className="rounded-lg bg-muted/40 border border-border/60 px-4 py-3 space-y-2 text-sm">
              <div className="flex justify-between">
                <span className="text-muted-foreground">Username</span>
                <span className="font-mono font-semibold">{credsDialog?.username}</span>
              </div>
              <div className="flex justify-between items-center">
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
              The admin should change their password on first login.
            </p>
          </div>

          <DialogFooter>
            <Button className="w-full" onClick={() => { setCredsDialog(null); setCopied(false); }}>
              Done
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* ------------------------------------------------------------------ */}
      {/* Table                                                               */}
      {/* ------------------------------------------------------------------ */}
      <ResponsiveTable
        columns={columns}
        data={admins}
        keyExtractor={(a) => a.id}
        renderRow={(a) => {
          const roleName = getPrimaryRoleName(a);
          const isCurrentUser = a.id === currentUserId;
          return (
            <TableRow key={a.id} className="group hover:bg-muted/30 transition-colors">
              <TableCell>
                <div className="flex items-center gap-2.5">
                  <div className="h-8 w-8 rounded-full bg-primary/10 flex items-center justify-center text-[11px] font-bold text-primary">
                    {a.full_name.split(' ').map((n) => n[0]).join('').toUpperCase().slice(0, 2)}
                  </div>
                  <div>
                    <p className="font-medium text-sm">{a.full_name}</p>
                    {a.email && <p className="text-xs text-muted-foreground">{a.email}</p>}
                    {isCurrentUser && <span className="text-[10px] text-accent font-semibold">You</span>}
                  </div>
                </div>
              </TableCell>
              <TableCell className="font-mono text-sm text-muted-foreground">{a.username}</TableCell>
              <TableCell><RoleBadge roleName={roleName} /></TableCell>
              <TableCell className="text-sm text-muted-foreground">
                {a.depot ? (
                  <span>{a.depot.name} <span className="text-xs opacity-60">({a.depot.merchant_code})</span></span>
                ) : (
                  <span className="text-muted-foreground/50 text-xs italic">All depots</span>
                )}
              </TableCell>
              <TableCell>
                <Badge className={`text-xs gap-1.5 ${statusConfig[a.status]}`}>
                  <span className={`h-1.5 w-1.5 rounded-full ${a.status === 'ACTIVE' ? 'bg-success' : 'bg-destructive'}`} />
                  {a.status}
                </Badge>
              </TableCell>
              <TableCell className="text-right space-x-1">
                {roleName !== 'SUPER_ADMIN' && (
                  <>
                    <Button variant="ghost" size="sm" onClick={() => openEditDialog(a)}>
                      Edit
                    </Button>
                    {!isCurrentUser && (
                      <Button
                        variant="ghost"
                        size="sm"
                        className={a.status === 'ACTIVE' ? 'text-destructive hover:text-destructive hover:bg-destructive/10' : 'text-success hover:text-success hover:bg-success/10'}
                        onClick={() => handleToggleStatus(a)}
                      >
                        {a.status === 'ACTIVE' ? 'Deactivate' : 'Activate'}
                      </Button>
                    )}
                  </>
                )}
                {roleName === 'SUPER_ADMIN' && (
                  <span className="text-xs text-muted-foreground/50 pr-2">Protected</span>
                )}
              </TableCell>
            </TableRow>
          );
        }}
        renderCard={(a) => {
          const roleName = getPrimaryRoleName(a);
          const isCurrentUser = a.id === currentUserId;
          return (
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2.5">
                  <div className="h-9 w-9 rounded-full bg-primary/10 flex items-center justify-center text-[11px] font-bold text-primary">
                    {a.full_name.split(' ').map((n) => n[0]).join('').toUpperCase().slice(0, 2)}
                  </div>
                  <div>
                    <div className="flex items-center gap-1">
                      <p className="font-medium text-sm">{a.full_name}</p>
                      {isCurrentUser && <span className="text-[10px] text-accent font-semibold">(You)</span>}
                    </div>
                    <p className="text-xs text-muted-foreground font-mono">{a.username}</p>
                  </div>
                </div>
                <Badge className={`text-xs gap-1.5 ${statusConfig[a.status]}`}>
                  <span className={`h-1.5 w-1.5 rounded-full ${a.status === 'ACTIVE' ? 'bg-success' : 'bg-destructive'}`} />
                  {a.status}
                </Badge>
              </div>

              <div className="grid grid-cols-2 gap-2 text-sm">
                <div>
                  <p className="text-muted-foreground text-xs">Role</p>
                  <RoleBadge roleName={roleName} />
                </div>
                <div>
                  <p className="text-muted-foreground text-xs">Depot</p>
                  <p className="text-sm font-medium">{a.depot ? a.depot.name : <span className="text-muted-foreground/50 italic text-xs">All depots</span>}</p>
                </div>
              </div>

              {roleName !== 'SUPER_ADMIN' && (
                <div className="flex items-center justify-end gap-2 pt-2 border-t border-border/40">
                  <Button variant="ghost" size="sm" onClick={() => openEditDialog(a)}>Edit</Button>
                  {!isCurrentUser && (
                    <Button
                      variant="ghost"
                      size="sm"
                      className={a.status === 'ACTIVE' ? 'text-destructive hover:text-destructive' : 'text-success hover:text-success'}
                      onClick={() => handleToggleStatus(a)}
                    >
                      {a.status === 'ACTIVE' ? 'Deactivate' : 'Activate'}
                    </Button>
                  )}
                </div>
              )}
            </div>
          );
        }}
      />
    </motion.div>
  );
};

export default AdminUsers;

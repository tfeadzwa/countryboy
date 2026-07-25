import { useCallback, useEffect, useMemo, useState } from "react";
import { motion } from "framer-motion";
import PageHeader from "@/components/PageHeader";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Checkbox } from "@/components/ui/checkbox";
import ErrorAlert from "@/components/ErrorAlert";
import {
  Save,
  Shield,
  Globe,
  Bell,
  KeyRound,
  Loader2,
  Building2,
  User,
  Phone,
  Mail,
} from "lucide-react";
import { useAuth } from "@/contexts/AuthContext";
import { isSuperAdmin } from "@/lib/permissions";
import { useToast } from "@/hooks/use-toast";
import {
  settingsService,
  type SettingsPayload,
  type TicketCurrencyCode,
} from "@/lib/api/settings.service";

const containerVariants = {
  hidden: { opacity: 0 },
  visible: { opacity: 1, transition: { staggerChildren: 0.08 } },
};

const cardVariants = {
  hidden: { opacity: 0, y: 12 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.4, ease: [0.25, 0.46, 0.45, 0.94] as [number, number, number, number] },
  },
};

const TIMEZONES = [
  "Africa/Harare",
  "Africa/Johannesburg",
  "Africa/Lusaka",
  "UTC",
];

const Settings = () => {
  const { user, updateUser } = useAuth();
  const { toast } = useToast();
  const roles = user?.roles || [];
  const isSuper = isSuperAdmin(roles);

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [data, setData] = useState<SettingsPayload | null>(null);

  // Profile (all admins)
  const [fullName, setFullName] = useState("");
  const [email, setEmail] = useState("");
  const [phone, setPhone] = useState("");

  // System (super admin)
  const [companyName, setCompanyName] = useState("");
  const [companyEmail, setCompanyEmail] = useState("");
  const [companyPhone, setCompanyPhone] = useState("");
  const [supportEmail, setSupportEmail] = useState("");
  const [enabledCurrencies, setEnabledCurrencies] = useState<TicketCurrencyCode[]>([]);
  const [defaultCurrency, setDefaultCurrency] = useState<TicketCurrencyCode>("USD");
  const [timezone, setTimezone] = useState("Africa/Harare");

  // Change password dialog
  const [passwordOpen, setPasswordOpen] = useState(false);
  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [passwordSaving, setPasswordSaving] = useState(false);
  const [passwordError, setPasswordError] = useState<string | null>(null);

  const applyPayload = useCallback((payload: SettingsPayload) => {
    setData(payload);
    setFullName(payload.profile.full_name ?? "");
    setEmail(payload.profile.email ?? "");
    setPhone(payload.profile.phone ?? "");
    setCompanyName(payload.system.company_name);
    setCompanyEmail(payload.system.company_email ?? "");
    setCompanyPhone(payload.system.company_phone ?? "");
    setSupportEmail(payload.system.support_email ?? "");
    setEnabledCurrencies(payload.system.enabled_currencies);
    setDefaultCurrency(payload.system.default_currency);
    setTimezone(payload.system.timezone);
  }, []);

  const load = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      const payload = await settingsService.get();
      applyPayload(payload);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load settings");
    } finally {
      setLoading(false);
    }
  }, [applyPayload]);

  useEffect(() => {
    void load();
  }, [load]);

  const availableCurrencies = data?.available_currencies ?? ["USD", "ZWL", "ZAR"];

  const toggleCurrency = (code: TicketCurrencyCode, checked: boolean) => {
    setEnabledCurrencies((prev) => {
      if (checked) return prev.includes(code) ? prev : [...prev, code];
      const next = prev.filter((c) => c !== code);
      if (next.length === 0) return prev;
      if (!next.includes(defaultCurrency)) {
        setDefaultCurrency(next[0]);
      }
      return next;
    });
  };

  const handleSave = async () => {
    setSaving(true);
    setError(null);
    try {
      const profile = await settingsService.updateProfile({
        full_name: fullName.trim(),
        email: email.trim() || null,
        phone: phone.trim() || null,
      });

      updateUser({
        email: profile.email,
        full_name: profile.full_name ?? undefined,
      });

      if (isSuper) {
        if (enabledCurrencies.length === 0) {
          throw new Error("Enable at least one currency");
        }
        if (!enabledCurrencies.includes(defaultCurrency)) {
          throw new Error("Default currency must be enabled");
        }
        await settingsService.updateSystem({
          company_name: companyName.trim(),
          company_email: companyEmail.trim() || null,
          company_phone: companyPhone.trim() || null,
          support_email: supportEmail.trim() || null,
          enabled_currencies: enabledCurrencies,
          default_currency: defaultCurrency,
          timezone,
        });
      }

      await load();
      toast({
        title: "Settings saved",
        description: "Your changes have been saved successfully.",
      });
    } catch (err) {
      const message = err instanceof Error ? err.message : "Failed to save settings";
      setError(message);
      toast({ title: "Save failed", description: message, variant: "destructive" });
    } finally {
      setSaving(false);
    }
  };

  const handleChangePassword = async () => {
    setPasswordError(null);
    if (!currentPassword) {
      setPasswordError("Enter your current password");
      return;
    }
    if (newPassword.length < 8) {
      setPasswordError("New password must be at least 8 characters");
      return;
    }
    if (newPassword !== confirmPassword) {
      setPasswordError("New passwords do not match");
      return;
    }

    setPasswordSaving(true);
    try {
      await settingsService.changePassword(currentPassword, newPassword);
      setPasswordOpen(false);
      setCurrentPassword("");
      setNewPassword("");
      setConfirmPassword("");
      toast({
        title: "Password updated",
        description: "Use your new password the next time you sign in.",
      });
    } catch (err) {
      setPasswordError(err instanceof Error ? err.message : "Failed to change password");
    } finally {
      setPasswordSaving(false);
    }
  };

  const disabledFeatureNote = useMemo(
    () => "Coming soon — this option is temporarily unavailable.",
    [],
  );

  if (loading) {
    return (
      <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.3 }}>
        <PageHeader title="Settings" description="Manage your account and system preferences" />
        <div className="flex items-center justify-center py-16 text-muted-foreground">
          <Loader2 className="mr-2 h-5 w-5 animate-spin" />
          Loading settings…
        </div>
      </motion.div>
    );
  }

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.3 }}>
      <PageHeader title="Settings" description="Manage your account and system preferences">
        <Button onClick={handleSave} disabled={saving} className="gap-2 shadow-sm">
          {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
          Save Changes
        </Button>
      </PageHeader>

      <ErrorAlert error={error} />

      <motion.div
        variants={containerVariants}
        initial="hidden"
        animate="visible"
        className="grid grid-cols-1 lg:grid-cols-2 gap-6 max-w-5xl"
      >
        <motion.div variants={cardVariants}>
          <Card className="shadow-sm border-border/60 h-full">
            <CardHeader className="pb-4">
              <CardTitle className="text-base font-display flex items-center gap-2.5">
                <div className="h-8 w-8 rounded-lg bg-primary/10 flex items-center justify-center">
                  <User className="h-4 w-4 text-primary" />
                </div>
                Your profile
              </CardTitle>
              <CardDescription>Personal details for your admin account</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="space-y-2">
                <Label className="text-xs font-medium">Username</Label>
                <Input value={data?.profile.username ?? ""} disabled className="bg-muted/40 font-mono" />
                <p className="text-[11px] text-muted-foreground">Username cannot be changed.</p>
              </div>
              <div className="space-y-2">
                <Label htmlFor="settings-full-name" className="text-xs font-medium">
                  Full name
                </Label>
                <Input
                  id="settings-full-name"
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                  placeholder="Your full name"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="settings-email" className="text-xs font-medium flex items-center gap-1.5">
                  <Mail className="h-3.5 w-3.5" /> Email
                </Label>
                <Input
                  id="settings-email"
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="you@example.com"
                />
              </div>
              <div className="space-y-2">
                <Label htmlFor="settings-phone" className="text-xs font-medium flex items-center gap-1.5">
                  <Phone className="h-3.5 w-3.5" /> Phone
                </Label>
                <Input
                  id="settings-phone"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  placeholder="Optional phone number"
                />
              </div>
              {!isSuper && (
                <>
                  <div className="space-y-2">
                    <Label className="text-xs font-medium flex items-center gap-1.5">
                      <Building2 className="h-3.5 w-3.5" /> Company name
                    </Label>
                    <Input value={data?.system.company_name ?? ""} disabled className="bg-muted/40" />
                  </div>
                  {data?.profile.depot_name && (
                    <div className="space-y-2">
                      <Label className="text-xs font-medium">Depot</Label>
                      <Input
                        value={`${data.profile.depot_name}${
                          data.profile.depot_merchant_code
                            ? ` (${data.profile.depot_merchant_code})`
                            : ""
                        }`}
                        disabled
                        className="bg-muted/40"
                      />
                    </div>
                  )}
                </>
              )}
            </CardContent>
          </Card>
        </motion.div>

        {isSuper ? (
          <motion.div variants={cardVariants}>
            <Card className="shadow-sm border-border/60 h-full">
              <CardHeader className="pb-4">
                <CardTitle className="text-base font-display flex items-center gap-2.5">
                  <div className="h-8 w-8 rounded-lg bg-accent/10 flex items-center justify-center">
                    <Globe className="h-4 w-4 text-accent" />
                  </div>
                  Organisation
                </CardTitle>
                <CardDescription>Company-wide portal settings</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="company-name" className="text-xs font-medium">
                    Company name
                  </Label>
                  <Input
                    id="company-name"
                    value={companyName}
                    onChange={(e) => setCompanyName(e.target.value)}
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="company-email" className="text-xs font-medium">
                    Company email
                  </Label>
                  <Input
                    id="company-email"
                    type="email"
                    value={companyEmail}
                    onChange={(e) => setCompanyEmail(e.target.value)}
                    placeholder="bus@countryboy.co.zw"
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="support-email" className="text-xs font-medium">
                    Support email
                  </Label>
                  <Input
                    id="support-email"
                    type="email"
                    value={supportEmail}
                    onChange={(e) => setSupportEmail(e.target.value)}
                    placeholder="Optional support contact"
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="company-phone" className="text-xs font-medium">
                    Company phone
                  </Label>
                  <Input
                    id="company-phone"
                    value={companyPhone}
                    onChange={(e) => setCompanyPhone(e.target.value)}
                    placeholder="Optional company phone"
                  />
                </div>
                <div className="space-y-2">
                  <Label className="text-xs font-medium">Timezone</Label>
                  <Select value={timezone} onValueChange={setTimezone}>
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {TIMEZONES.map((tz) => (
                        <SelectItem key={tz} value={tz}>
                          {tz}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </CardContent>
            </Card>
          </motion.div>
        ) : (
          <motion.div variants={cardVariants}>
            <Card className="shadow-sm border-border/60 h-full">
              <CardHeader className="pb-4">
                <CardTitle className="text-base font-display flex items-center gap-2.5">
                  <div className="h-8 w-8 rounded-lg bg-accent/10 flex items-center justify-center">
                    <Building2 className="h-4 w-4 text-accent" />
                  </div>
                  Organisation
                </CardTitle>
                <CardDescription>Read-only company details for your depot</CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="space-y-2">
                  <Label className="text-xs font-medium">Company email</Label>
                  <Input
                    value={data?.system.company_email || "—"}
                    disabled
                    className="bg-muted/40"
                  />
                </div>
                <div className="space-y-2">
                  <Label className="text-xs font-medium">Default currency</Label>
                  <Input
                    value={data?.system.default_currency ?? "USD"}
                    disabled
                    className="bg-muted/40"
                  />
                </div>
                <div className="space-y-2">
                  <Label className="text-xs font-medium">Timezone</Label>
                  <Input
                    value={data?.system.timezone ?? "Africa/Harare"}
                    disabled
                    className="bg-muted/40"
                  />
                </div>
              </CardContent>
            </Card>
          </motion.div>
        )}

        {isSuper && (
          <motion.div variants={cardVariants} className="lg:col-span-2">
            <Card className="shadow-sm border-border/60">
              <CardHeader className="pb-4">
                <CardTitle className="text-base font-display flex items-center gap-2.5">
                  <div className="h-8 w-8 rounded-lg bg-warning/10 flex items-center justify-center">
                    <Globe className="h-4 w-4 text-warning" />
                  </div>
                  Currencies
                </CardTitle>
                <CardDescription>
                  Choose which currencies conductors can use, and the default for new fares
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                  {availableCurrencies.map((code) => {
                    const checked = enabledCurrencies.includes(code);
                    return (
                      <label
                        key={code}
                        className="flex items-center gap-3 rounded-lg border border-border/60 bg-muted/20 px-3 py-3 cursor-pointer"
                      >
                        <Checkbox
                          checked={checked}
                          onCheckedChange={(v) => toggleCurrency(code, v === true)}
                        />
                        <span className="text-sm font-medium">{code}</span>
                      </label>
                    );
                  })}
                </div>
                <div className="space-y-2 max-w-xs">
                  <Label className="text-xs font-medium">Default currency</Label>
                  <Select
                    value={defaultCurrency}
                    onValueChange={(v) => setDefaultCurrency(v as TicketCurrencyCode)}
                  >
                    <SelectTrigger>
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {enabledCurrencies.map((code) => (
                        <SelectItem key={code} value={code}>
                          {code}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </CardContent>
            </Card>
          </motion.div>
        )}

        <motion.div variants={cardVariants}>
          <Card className="shadow-sm border-border/60 h-full opacity-70">
            <CardHeader className="pb-4">
              <CardTitle className="text-base font-display flex items-center gap-2.5">
                <div className="h-8 w-8 rounded-lg bg-primary/10 flex items-center justify-center">
                  <Bell className="h-4 w-4 text-primary" />
                </div>
                Notifications
              </CardTitle>
              <CardDescription>How you receive alerts</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4 pointer-events-none">
              <div className="flex items-center justify-between p-3 rounded-lg bg-muted/30">
                <div>
                  <p className="text-sm font-medium text-foreground">Email Notifications</p>
                  <p className="text-xs text-muted-foreground">{disabledFeatureNote}</p>
                </div>
                <Switch checked={false} disabled />
              </div>
              <div className="flex items-center justify-between p-3 rounded-lg bg-muted/30">
                <div>
                  <p className="text-sm font-medium text-foreground">SMS Notifications</p>
                  <p className="text-xs text-muted-foreground">{disabledFeatureNote}</p>
                </div>
                <Switch checked={false} disabled />
              </div>
            </CardContent>
          </Card>
        </motion.div>

        <motion.div variants={cardVariants}>
          <Card className="shadow-sm border-border/60 h-full">
            <CardHeader className="pb-4">
              <CardTitle className="text-base font-display flex items-center gap-2.5">
                <div className="h-8 w-8 rounded-lg bg-secondary/10 flex items-center justify-center">
                  <Shield className="h-4 w-4 text-secondary" />
                </div>
                Security
              </CardTitle>
              <CardDescription>Account security settings</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center justify-between p-3 rounded-lg bg-muted/30 opacity-70 pointer-events-none">
                <div>
                  <p className="text-sm font-medium text-foreground">Two-Factor Authentication</p>
                  <p className="text-xs text-muted-foreground">{disabledFeatureNote}</p>
                </div>
                <Switch checked={false} disabled />
              </div>
              <div className="flex items-center justify-between p-3 rounded-lg bg-muted/30">
                <div className="flex items-center gap-3">
                  <div className="h-8 w-8 rounded-lg bg-warning/10 flex items-center justify-center">
                    <KeyRound className="h-4 w-4 text-warning" />
                  </div>
                  <div>
                    <p className="text-sm font-medium text-foreground">Change Password</p>
                    <p className="text-xs text-muted-foreground">Update your account password</p>
                  </div>
                </div>
                <Button
                  variant="outline"
                  size="sm"
                  className="shadow-sm"
                  onClick={() => {
                    setPasswordError(null);
                    setPasswordOpen(true);
                  }}
                >
                  Change
                </Button>
              </div>
            </CardContent>
          </Card>
        </motion.div>
      </motion.div>

      <Dialog
        open={passwordOpen}
        onOpenChange={(open) => {
          if (!passwordSaving) {
            setPasswordOpen(open);
            if (!open) {
              setCurrentPassword("");
              setNewPassword("");
              setConfirmPassword("");
              setPasswordError(null);
            }
          }
        }}
      >
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Change password</DialogTitle>
            <DialogDescription>
              Enter your current password and choose a new one (at least 8 characters).
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-3 py-2">
            {passwordError && (
              <p className="text-sm text-destructive">{passwordError}</p>
            )}
            <div className="space-y-2">
              <Label htmlFor="current-password">Current password</Label>
              <Input
                id="current-password"
                type="password"
                value={currentPassword}
                onChange={(e) => setCurrentPassword(e.target.value)}
                disabled={passwordSaving}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="new-password">New password</Label>
              <Input
                id="new-password"
                type="password"
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
                disabled={passwordSaving}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="confirm-password">Confirm new password</Label>
              <Input
                id="confirm-password"
                type="password"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
                disabled={passwordSaving}
              />
            </div>
          </div>
          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setPasswordOpen(false)}
              disabled={passwordSaving}
            >
              Cancel
            </Button>
            <Button onClick={handleChangePassword} disabled={passwordSaving}>
              {passwordSaving ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Updating…
                </>
              ) : (
                "Update password"
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </motion.div>
  );
};

export default Settings;

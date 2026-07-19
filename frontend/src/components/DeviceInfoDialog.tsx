import { useState, useEffect } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from "@/components/ui/dialog";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Alert, AlertDescription } from "@/components/ui/alert";
import {
  Copy,
  Smartphone,
  MapPin,
  Calendar,
  Activity,
  AlertTriangle,
  CheckCircle2,
  Key,
  Loader2,
  AlertCircle,
  User,
  History,
  Clock,
  RefreshCw,
} from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { Badge } from "@/components/ui/badge";
import { deviceService } from "@/lib/api/device.service";
import { canManageDevices, isSuperAdmin } from "@/lib/permissions";
import { useAuth } from "@/contexts/AuthContext";
import type { Device, DeviceSession } from "@/types";

interface DeviceInfoDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  device: Device | null;
  onUpdated?: () => void;
}

type InfoRow = {
  label: string;
  value: string;
  icon: typeof Smartphone;
  mono?: boolean;
  copyable?: boolean;
  badge?: boolean;
  fullWidth?: boolean;
};

const formatSessionReason = (reason: string | null | undefined) => {
  if (!reason) return null;
  return reason.replace(/_/g, " ");
};

const DeviceInfoDialog = ({ open, onOpenChange, device, onUpdated }: DeviceInfoDialogProps) => {
  const { user } = useAuth();
  const { toast } = useToast();
  const [activeTab, setActiveTab] = useState("overview");
  const [showUnpairConfirm, setShowUnpairConfirm] = useState(false);
  const [showRegenerateConfirm, setShowRegenerateConfirm] = useState(false);
  const [unpairLoading, setUnpairLoading] = useState(false);
  const [regenerateLoading, setRegenerateLoading] = useState(false);
  const [successPairingCode, setSuccessPairingCode] = useState<string | null>(null);
  const [successTitle, setSuccessTitle] = useState("Pairing code ready");
  const [pairingCode, setPairingCode] = useState<string | null>(null);
  const [sessions, setSessions] = useState<DeviceSession[]>([]);
  const [sessionsLoading, setSessionsLoading] = useState(false);

  const canManage = user ? canManageDevices(user.roles || []) : false;
  const depotIdForMutations =
    user && isSuperAdmin(user.roles || []) ? device?.depot_id : undefined;

  useEffect(() => {
    if (!open || !device) {
      setPairingCode(null);
      return;
    }
    setPairingCode(!device.paired && device.pairing_code ? device.pairing_code : null);
  }, [open, device?.id, device?.paired, device?.pairing_code]);

  useEffect(() => {
    if (!open || !device?.id || successPairingCode || showUnpairConfirm || showRegenerateConfirm) {
      return;
    }
    let cancelled = false;
    setSessionsLoading(true);
    deviceService
      .getSessions(device.id, 20)
      .then((result) => {
        if (!cancelled) setSessions(result.sessions);
      })
      .catch(() => {
        if (!cancelled) setSessions([]);
      })
      .finally(() => {
        if (!cancelled) setSessionsLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [open, device?.id, successPairingCode, showUnpairConfirm, showRegenerateConfirm]);

  if (!device) return null;

  const copyToClipboard = (text: string, label: string) => {
    navigator.clipboard.writeText(text);
    toast({ title: "Copied!", description: `${label} copied to clipboard.` });
  };

  const handleUnpair = async () => {
    if (!device) return;

    setUnpairLoading(true);
    try {
      const result = await deviceService.unpair(device.id, depotIdForMutations);
      setSuccessPairingCode(result.pairing_code);
      setSuccessTitle("Device Unpaired Successfully!");
      setPairingCode(result.pairing_code);
      setShowUnpairConfirm(false);

      toast({
        title: "Device Unpaired",
        description: "New pairing code generated. It stays visible while the device is unpaired.",
      });

      onUpdated?.();
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : "Failed to unpair device";
      toast({
        title: "Error",
        description: errorMessage,
        variant: "destructive",
      });
    } finally {
      setUnpairLoading(false);
    }
  };

  const handleRegenerate = async () => {
    if (!device) return;

    setRegenerateLoading(true);
    try {
      const result = await deviceService.regeneratePairingCode(device.id, depotIdForMutations);
      setPairingCode(result.pairing_code);
      setShowRegenerateConfirm(false);

      toast({
        title: "Pairing code regenerated",
        description: "The previous code no longer works. Share the new code with the agent.",
      });

      onUpdated?.();
    } catch (error) {
      const errorMessage =
        error instanceof Error ? error.message : "Failed to regenerate pairing code";
      toast({
        title: "Error",
        description: errorMessage,
        variant: "destructive",
      });
    } finally {
      setRegenerateLoading(false);
    }
  };

  const handleClose = () => {
    setShowUnpairConfirm(false);
    setShowRegenerateConfirm(false);
    setSuccessPairingCode(null);
    setSessions([]);
    setActiveTab("overview");
    onOpenChange(false);
  };

  if (successPairingCode) {
    return (
      <Dialog open={open} onOpenChange={handleClose}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <div className="mx-auto mb-1 flex h-10 w-10 items-center justify-center rounded-full bg-green-100 dark:bg-green-900/20">
              <CheckCircle2 className="h-5 w-5 text-green-600 dark:text-green-500" />
            </div>
            <DialogTitle className="text-center text-lg">{successTitle}</DialogTitle>
            <DialogDescription className="text-center text-sm">
              Share this code with the agent. You can also view it anytime from device details while unpaired.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-3 py-2">
            <Alert className="border-primary/20 bg-primary/5 py-2">
              <Key className="h-4 w-4 text-primary" />
              <AlertDescription className="text-sm">
                This code stays available on the device details page until the device is paired.
              </AlertDescription>
            </Alert>

            <div className="space-y-1.5">
              <Label>Pairing Code</Label>
              <div className="flex gap-2">
                <Input
                  value={successPairingCode}
                  readOnly
                  className="font-mono text-lg text-center tracking-wider"
                />
                <Button
                  type="button"
                  size="icon"
                  variant="outline"
                  onClick={() => copyToClipboard(successPairingCode, "Pairing code")}
                  className="shrink-0"
                >
                  <Copy className="h-4 w-4" />
                </Button>
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button onClick={handleClose} className="w-full">
              Close
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    );
  }

  if (showRegenerateConfirm) {
    return (
      <Dialog open={open} onOpenChange={() => !regenerateLoading && setShowRegenerateConfirm(false)}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <div className="mx-auto mb-1 flex h-10 w-10 items-center justify-center rounded-full bg-amber-100 dark:bg-amber-900/20">
              <RefreshCw className="h-5 w-5 text-amber-600 dark:text-amber-500" />
            </div>
            <DialogTitle className="text-center text-lg">Regenerate pairing code?</DialogTitle>
            <DialogDescription className="text-center text-sm">
              The current code will stop working immediately.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-3 py-2">
            <Alert className="py-2">
              <AlertCircle className="h-4 w-4" />
              <AlertDescription className="text-sm">
                Use this if the code was lost, forgotten, or shared with the wrong person. The device stays unpaired.
              </AlertDescription>
            </Alert>

            <div className="rounded-lg border border-border bg-muted/30 p-3">
              <p className="text-sm font-mono text-muted-foreground">Serial: {device.serial_number}</p>
              {pairingCode && (
                <p className="text-sm text-muted-foreground mt-1">
                  Current code: <span className="font-mono font-medium">{pairingCode}</span>
                </p>
              )}
            </div>
          </div>

          <DialogFooter className="gap-2">
            <Button
              type="button"
              variant="outline"
              onClick={() => setShowRegenerateConfirm(false)}
              disabled={regenerateLoading}
            >
              Cancel
            </Button>
            <Button
              type="button"
              onClick={handleRegenerate}
              disabled={regenerateLoading}
              className="gap-2"
            >
              {regenerateLoading ? (
                <>
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Regenerating...
                </>
              ) : (
                <>
                  <RefreshCw className="h-4 w-4" />
                  Regenerate code
                </>
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    );
  }

  if (showUnpairConfirm) {
    return (
      <Dialog open={open} onOpenChange={() => !unpairLoading && setShowUnpairConfirm(false)}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <div className="mx-auto mb-1 flex h-10 w-10 items-center justify-center rounded-full bg-amber-100 dark:bg-amber-900/20">
              <AlertTriangle className="h-5 w-5 text-amber-600 dark:text-amber-500" />
            </div>
            <DialogTitle className="text-center text-lg">Unpair Device?</DialogTitle>
            <DialogDescription className="text-center text-sm">
              This will reset the device and generate a new pairing code.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-3 py-2">
            <Alert className="py-2">
              <AlertCircle className="h-4 w-4" />
              <AlertDescription className="text-sm">
                <ul className="list-disc list-inside space-y-1 text-sm">
                  <li>The device will be reset to unpaired status</li>
                  <li>A new pairing code will be generated</li>
                  <li>Active conductor sessions on this device will end</li>
                  <li>The agent must pair again with the new code</li>
                </ul>
              </AlertDescription>
            </Alert>

            <div className="rounded-lg border border-border bg-muted/30 p-3">
              <p className="text-sm font-mono text-muted-foreground">Serial: {device.serial_number}</p>
              {device.device_name && <p className="text-sm text-muted-foreground">Name: {device.device_name}</p>}
            </div>
          </div>

          <DialogFooter className="gap-2">
            <Button
              type="button"
              variant="outline"
              onClick={() => setShowUnpairConfirm(false)}
              disabled={unpairLoading}
            >
              Cancel
            </Button>
            <Button
              type="button"
              variant="destructive"
              onClick={handleUnpair}
              disabled={unpairLoading}
              className="gap-2"
            >
              {unpairLoading ? (
                <>
                  <Loader2 className="h-4 w-4 animate-spin" />
                  Unpairing...
                </>
              ) : (
                "Unpair Device"
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    );
  }

  const infoRows: InfoRow[] = [
    { label: "Serial Number", value: device.serial_number, icon: Smartphone, mono: true, copyable: true },
    { label: "Depot", value: device.depot_name || "N/A", icon: MapPin },
    { label: "Status", value: device.paired ? "Paired" : "Awaiting pairing", icon: Activity, badge: true },
    ...(device.paired && device.device_name
      ? [{ label: "Device Name", value: device.device_name, icon: Smartphone }]
      : []),
    ...(device.paired && device.device_model
      ? [{ label: "Model", value: device.device_model, icon: Smartphone }]
      : []),
    ...(device.paired && device.app_version
      ? [{ label: "App Version", value: device.app_version, icon: Activity }]
      : []),
    ...(device.paired_at
      ? [{ label: "Paired At", value: new Date(device.paired_at).toLocaleString(), icon: Calendar }]
      : []),
    ...(device.last_seen
      ? [{ label: "Last Seen", value: new Date(device.last_seen).toLocaleString(), icon: Clock }]
      : []),
    ...(device.last_agent
      ? [
          {
            label: "Last Conductor",
            value: `${device.last_agent.full_name} (${device.last_agent.agent_code})`,
            icon: User,
          },
        ]
      : []),
    ...(device.last_agent_login_at
      ? [{ label: "Last Sign In", value: new Date(device.last_agent_login_at).toLocaleString(), icon: Calendar }]
      : []),
  ];

  const activeSessionCount = device.paired
    ? sessions.filter((s) => !s.ended_at).length
    : 0;
  const showPairingPanel = !device.paired;

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-[560px] gap-0 p-0 overflow-hidden max-h-[90vh] flex flex-col">
        <DialogHeader className="px-6 pt-6 pb-4 space-y-3 border-b border-border/60">
          <div className="flex items-start gap-3">
            <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-primary/10">
              <Smartphone className="h-5 w-5 text-primary" />
            </div>
            <div className="min-w-0 flex-1 pt-0.5">
              <DialogTitle className="text-left text-lg leading-tight">Device Details</DialogTitle>
              <DialogDescription className="text-left font-mono text-sm mt-1">
                {device.serial_number}
              </DialogDescription>
            </div>
            <Badge
              className={`shrink-0 text-xs ${
                device.paired
                  ? "bg-success/10 text-success border border-success/20"
                  : "bg-muted text-muted-foreground border border-border"
              }`}
            >
              {device.paired ? "Paired" : "Unpaired"}
            </Badge>
          </div>
        </DialogHeader>

        <Tabs value={activeTab} onValueChange={setActiveTab} className="flex flex-col flex-1 min-h-0 overflow-hidden">
          <div className="px-6 pt-4">
            <TabsList className="grid w-full grid-cols-2 bg-muted/50 h-10">
              <TabsTrigger value="overview" className="text-sm">
                Overview
              </TabsTrigger>
              <TabsTrigger value="sessions" className="text-sm gap-1.5">
                <History className="h-3.5 w-3.5" />
                Conductor Sessions
                {!sessionsLoading && sessions.length > 0 && (
                  <Badge variant="secondary" className="h-5 min-w-5 px-1.5 text-[10px] font-semibold">
                    {sessions.length}
                  </Badge>
                )}
              </TabsTrigger>
            </TabsList>
          </div>

          <TabsContent value="overview" className="mt-0 px-6 py-4 space-y-4 max-h-[min(60vh,420px)] overflow-y-auto">
            {showPairingPanel && (
              <div className="rounded-xl border border-primary/20 bg-primary/5 p-4 space-y-3">
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <div className="flex items-center gap-2 mb-1">
                      <Key className="h-4 w-4 text-primary" />
                      <p className="text-sm font-semibold">Pairing code</p>
                    </div>
                    <p className="text-xs text-muted-foreground">
                      Visible while this device is unpaired. Share it with the agent to activate the app.
                    </p>
                  </div>
                </div>

                {pairingCode ? (
                  <div className="flex gap-2">
                    <Input
                      value={pairingCode}
                      readOnly
                      className="font-mono text-lg text-center tracking-wider bg-background"
                    />
                    <Button
                      type="button"
                      size="icon"
                      variant="outline"
                      onClick={() => copyToClipboard(pairingCode, "Pairing code")}
                      className="shrink-0"
                    >
                      <Copy className="h-4 w-4" />
                    </Button>
                  </div>
                ) : (
                  <Alert className="py-2.5 bg-background">
                    <AlertCircle className="h-4 w-4" />
                    <AlertDescription className="text-sm">
                      No pairing code on file. Regenerate one to continue setup.
                    </AlertDescription>
                  </Alert>
                )}

                {canManage && (
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    className="gap-2"
                    onClick={() => setShowRegenerateConfirm(true)}
                  >
                    <RefreshCw className="h-3.5 w-3.5" />
                    Regenerate code
                  </Button>
                )}
              </div>
            )}

            {device.active_session?.agent && (
              <div className="rounded-lg border border-success/25 bg-success/5 p-3">
                <div className="flex items-center gap-2 mb-1">
                  <Activity className="h-3.5 w-3.5 text-success" />
                  <p className="text-xs font-medium text-success uppercase tracking-wide">Active session</p>
                </div>
                <p className="text-sm font-semibold">
                  {device.active_session.agent.full_name}{" "}
                  <span className="font-normal text-muted-foreground">
                    ({device.active_session.agent.agent_code})
                  </span>
                </p>
                <p className="text-xs text-muted-foreground mt-1">
                  Since {new Date(device.active_session.started_at).toLocaleString()}
                </p>
              </div>
            )}

            <div className="grid grid-cols-2 gap-2.5">
              {infoRows.map((item) => {
                const Icon = item.icon;
                return (
                  <div
                    key={item.label}
                    className={`rounded-lg border border-border/80 bg-muted/20 p-3 relative ${
                      item.fullWidth ? "col-span-2" : ""
                    }`}
                  >
                    <div className="flex items-center gap-1.5 mb-1.5">
                      <Icon className="h-3.5 w-3.5 text-muted-foreground" />
                      <p className="text-[11px] font-medium uppercase tracking-wide text-muted-foreground">
                        {item.label}
                      </p>
                    </div>
                    <div className={`text-sm font-semibold leading-snug pr-6 ${item.mono ? "font-mono" : ""}`}>
                      {item.badge ? (
                        <Badge
                          className={`text-xs ${
                            device.paired
                              ? "bg-success/10 text-success border border-success/20"
                              : "bg-muted text-muted-foreground border border-border"
                          }`}
                        >
                          {item.value}
                        </Badge>
                      ) : (
                        item.value
                      )}
                    </div>
                    {item.copyable && (
                      <Button
                        type="button"
                        variant="ghost"
                        size="icon"
                        className="h-6 w-6 absolute top-2 right-2 text-muted-foreground"
                        onClick={() => copyToClipboard(item.value, item.label)}
                      >
                        <Copy className="h-3 w-3" />
                      </Button>
                    )}
                  </div>
                );
              })}
            </div>
          </TabsContent>

          <TabsContent
            value="sessions"
            className="mt-0 flex flex-col flex-1 min-h-0 overflow-hidden px-6 py-4 data-[state=inactive]:hidden"
          >
            {sessionsLoading ? (
              <div className="flex flex-col items-center justify-center gap-2 py-12 text-sm text-muted-foreground">
                <Loader2 className="h-6 w-6 animate-spin" />
                Loading sessions...
              </div>
            ) : sessions.length === 0 ? (
              <div className="flex flex-col items-center justify-center gap-2 py-12 text-center">
                <div className="flex h-12 w-12 items-center justify-center rounded-full bg-muted">
                  <History className="h-5 w-5 text-muted-foreground" />
                </div>
                <p className="text-sm font-medium">No sessions yet</p>
                <p className="text-xs text-muted-foreground max-w-[240px]">
                  {device.paired
                    ? 'Conductor sign-ins on this device will appear here.'
                    : 'No conductor sessions recorded for this device yet. Past sessions remain visible after unpairing.'}
                </p>
              </div>
            ) : (
              <>
                {activeSessionCount > 0 && (
                  <p className="text-xs text-muted-foreground mb-3 shrink-0">
                    {activeSessionCount} active · {sessions.length} total recorded
                  </p>
                )}
                <div className="min-h-0 flex-1 overflow-y-auto overscroll-contain pr-1 -mr-1 max-h-[min(50vh,360px)] space-y-2">
                  {sessions.map((session) => {
                  // Unpaired devices cannot have a live conductor session.
                  const isActive = Boolean(device.paired && !session.ended_at);
                  const loginLabel =
                    session.login_type === 'offline'
                      ? 'Offline login'
                      : session.login_type === 'online'
                        ? 'Online login'
                        : session.login_type
                          ? `${session.login_type} login`
                          : null;
                  return (
                    <div
                      key={session.id}
                      className={`rounded-lg border p-3 transition-colors ${
                        isActive
                          ? "border-success/30 bg-success/5"
                          : "border-border/80 bg-muted/15"
                      }`}
                    >
                      <div className="flex items-start justify-between gap-3">
                        <div className="min-w-0">
                          <p className="text-sm font-semibold truncate">
                            {session.agent?.full_name ?? "Unknown conductor"}
                          </p>
                          <p className="text-xs text-muted-foreground font-mono">
                            {session.agent?.agent_code ?? "—"}
                          </p>
                        </div>
                        <Badge
                          variant="outline"
                          className={`shrink-0 text-[10px] uppercase tracking-wide ${
                            isActive
                              ? "border-success/40 text-success bg-success/10"
                              : ""
                          }`}
                        >
                          {isActive ? "Active" : "Ended"}
                        </Badge>
                      </div>
                      <div className="mt-2.5 flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-muted-foreground">
                        <span className="inline-flex items-center gap-1">
                          <Clock className="h-3 w-3" />
                          {new Date(session.started_at).toLocaleString()}
                          {session.ended_at
                            ? ` → ${new Date(session.ended_at).toLocaleString()}`
                            : isActive
                              ? " → now"
                              : ""}
                        </span>
                        {session.end_reason && (
                          <span className="capitalize">· {formatSessionReason(session.end_reason)}</span>
                        )}
                        {loginLabel && <span>· {loginLabel}</span>}
                      </div>
                    </div>
                  );
                })}
                </div>
              </>
            )}
          </TabsContent>
        </Tabs>

        <DialogFooter className="gap-2 px-6 py-4 border-t border-border/60 bg-muted/20 shrink-0">
          {canManage && device.paired && (
            <Button
              variant="destructive"
              onClick={() => setShowUnpairConfirm(true)}
              className="gap-2 mr-auto"
            >
              <AlertTriangle className="h-4 w-4" />
              Unpair Device
            </Button>
          )}
          <Button onClick={handleClose} variant={canManage && device.paired ? "outline" : "default"}>
            Close
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};

export default DeviceInfoDialog;

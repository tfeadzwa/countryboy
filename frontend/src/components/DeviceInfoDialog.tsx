import { useState, useEffect } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from "@/components/ui/dialog";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import {
  Copy,
  Smartphone,
  MapPin,
  Calendar,
  Activity,
  AlertTriangle,
  CheckCircle2,
  Loader2,
  AlertCircle,
  User,
  History,
  Clock,
  RefreshCw,
  Pencil,
  Trash2,
} from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { Badge } from "@/components/ui/badge";
import { deviceService } from "@/lib/api/device.service";
import { depotService } from "@/lib/api/depot.service";
import { canManageDevices, isSuperAdmin } from "@/lib/permissions";
import { useAuth } from "@/contexts/AuthContext";
import PairingCodeDisplay from "@/components/PairingCodeDisplay";
import type { Device, DeviceSession, Depot } from "@/types";

interface DeviceInfoDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  device: Device | null;
  onUpdated?: () => void;
  onDeleted?: () => void;
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

type ViewMode = "details" | "edit" | "unpair" | "regenerate" | "delete" | "success";

const formatSessionReason = (reason: string | null | undefined) => {
  if (!reason) return null;
  return reason.replace(/_/g, " ");
};

const DeviceInfoDialog = ({ open, onOpenChange, device, onUpdated, onDeleted }: DeviceInfoDialogProps) => {
  const { user } = useAuth();
  const { toast } = useToast();
  const [activeTab, setActiveTab] = useState("overview");
  const [view, setView] = useState<ViewMode>("details");
  const [actionLoading, setActionLoading] = useState(false);
  const [successPairingCode, setSuccessPairingCode] = useState<string | null>(null);
  const [successTitle, setSuccessTitle] = useState("Pairing code ready");
  const [pairingCode, setPairingCode] = useState<string | null>(null);
  const [sessions, setSessions] = useState<DeviceSession[]>([]);
  const [sessionsLoading, setSessionsLoading] = useState(false);

  const [editSerial, setEditSerial] = useState("");
  const [editDepotId, setEditDepotId] = useState("");
  const [depots, setDepots] = useState<Depot[]>([]);
  const [editError, setEditError] = useState<string | null>(null);

  const canManage = user ? canManageDevices(user.roles || []) : false;
  const isSuperAdminUser = user ? isSuperAdmin(user.roles || []) : false;
  const depotIdForMutations = isSuperAdminUser ? device?.depot_id : undefined;

  useEffect(() => {
    if (!open || !device) {
      setPairingCode(null);
      setView("details");
      setActiveTab("overview");
      setSuccessPairingCode(null);
      setEditError(null);
      return;
    }
    const paired = device.paired === true;
    setPairingCode(!paired && device.pairing_code ? device.pairing_code : null);
    setEditSerial(device.serial_number);
    setEditDepotId(device.depot_id);
  }, [open, device?.id, device?.paired, device?.pairing_code, device?.serial_number, device?.depot_id]);

  useEffect(() => {
    if (!open || !isSuperAdminUser) return;
    let cancelled = false;
    depotService
      .getAll()
      .then((list) => {
        if (!cancelled) setDepots(list);
      })
      .catch(() => {
        if (!cancelled) setDepots([]);
      });
    return () => {
      cancelled = true;
    };
  }, [open, isSuperAdminUser]);

  useEffect(() => {
    if (!open || !device?.id || view !== "details") return;
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
  }, [open, device?.id, view]);

  if (!device) return null;

  const copyToClipboard = (text: string, label: string) => {
    navigator.clipboard.writeText(text);
    toast({ title: "Copied!", description: `${label} copied to clipboard.` });
  };

  const handleClose = () => {
    setView("details");
    setSuccessPairingCode(null);
    setSessions([]);
    setActiveTab("overview");
    setEditError(null);
    onOpenChange(false);
  };

  const handleUnpair = async () => {
    setActionLoading(true);
    try {
      const result = await deviceService.unpair(device.id, depotIdForMutations);
      setSuccessPairingCode(result.pairing_code);
      setSuccessTitle("Device Unpaired Successfully!");
      setPairingCode(result.pairing_code);
      setView("success");
      toast({
        title: "Device Unpaired",
        description: "New pairing code generated. It stays visible while the device is unpaired.",
      });
      onUpdated?.();
    } catch (error) {
      toast({
        title: "Error",
        description: error instanceof Error ? error.message : "Failed to unpair device",
        variant: "destructive",
      });
    } finally {
      setActionLoading(false);
    }
  };

  const handleRegenerate = async () => {
    setActionLoading(true);
    try {
      const result = await deviceService.regeneratePairingCode(device.id, depotIdForMutations);
      setPairingCode(result.pairing_code);
      setView("details");
      toast({
        title: "Pairing code regenerated",
        description: "The previous code no longer works. Share the new code with the agent.",
      });
      onUpdated?.();
    } catch (error) {
      toast({
        title: "Error",
        description: error instanceof Error ? error.message : "Failed to regenerate pairing code",
        variant: "destructive",
      });
    } finally {
      setActionLoading(false);
    }
  };

  const handleSaveEdit = async () => {
    setEditError(null);
    const serial = editSerial.trim();
    if (!serial) {
      setEditError("Serial number is required");
      return;
    }

    const payload: { serial_number?: string; depot_id?: string } = {};
    if (serial !== device.serial_number) payload.serial_number = serial;
    if (isSuperAdminUser && editDepotId && editDepotId !== device.depot_id) {
      payload.depot_id = editDepotId;
    }

    if (!payload.serial_number && !payload.depot_id) {
      setView("details");
      return;
    }

    setActionLoading(true);
    try {
      await deviceService.update(device.id, payload, depotIdForMutations);
      toast({
        title: "Device updated",
        description: "Serial number and depot changes were saved.",
      });
      setView("details");
      onUpdated?.();
    } catch (error) {
      setEditError(error instanceof Error ? error.message : "Failed to update device");
    } finally {
      setActionLoading(false);
    }
  };

  const handleDelete = async () => {
    setActionLoading(true);
    try {
      await deviceService.remove(device.id, depotIdForMutations);
      toast({
        title: "Device deleted",
        description: `${device.serial_number} was removed.`,
      });
      onDeleted?.();
      onUpdated?.();
      handleClose();
    } catch (error) {
      toast({
        title: "Could not delete",
        description: error instanceof Error ? error.message : "Failed to delete device",
        variant: "destructive",
      });
      setView("details");
    } finally {
      setActionLoading(false);
    }
  };

  if (view === "success" && successPairingCode) {
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
          <div className="py-2">
            <PairingCodeDisplay
              code={successPairingCode}
              onCopy={() => copyToClipboard(successPairingCode, "Pairing code")}
            />
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

  if (view === "edit") {
    return (
      <Dialog open={open} onOpenChange={() => !actionLoading && setView("details")}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>Edit device</DialogTitle>
            <DialogDescription>
              Update the serial number{isSuperAdminUser ? " or move the device to another depot" : ""}.
              {device.paired && isSuperAdminUser
                ? " Depot can only be changed after unpairing."
                : null}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-1">
            {editError && (
              <Alert variant="destructive" className="py-2.5">
                <AlertCircle className="h-4 w-4" />
                <AlertDescription className="text-sm">{editError}</AlertDescription>
              </Alert>
            )}
            <div className="space-y-1.5">
              <Label htmlFor="edit-serial">Serial number</Label>
              <Input
                id="edit-serial"
                value={editSerial}
                onChange={(e) => setEditSerial(e.target.value)}
                className="font-mono"
                disabled={actionLoading}
              />
            </div>
            {isSuperAdminUser && (
              <div className="space-y-1.5">
                <Label>Depot</Label>
                <Select
                  value={editDepotId}
                  onValueChange={setEditDepotId}
                  disabled={actionLoading || device.paired}
                >
                  <SelectTrigger>
                    <SelectValue placeholder="Select depot" />
                  </SelectTrigger>
                  <SelectContent>
                    {depots.map((d) => (
                      <SelectItem key={d.id} value={d.id}>
                        {d.name} ({d.merchant_code})
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                {device.paired && (
                  <p className="text-xs text-muted-foreground">
                    Unpair this device first to move it to another depot.
                  </p>
                )}
              </div>
            )}
          </div>

          <DialogFooter className="gap-2">
            <Button variant="outline" onClick={() => setView("details")} disabled={actionLoading}>
              Cancel
            </Button>
            <Button onClick={handleSaveEdit} disabled={actionLoading} className="gap-2">
              {actionLoading ? <Loader2 className="h-4 w-4 animate-spin" /> : null}
              Save changes
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    );
  }

  if (view === "regenerate") {
    return (
      <Dialog open={open} onOpenChange={() => !actionLoading && setView("details")}>
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
          <Alert className="py-2">
            <AlertCircle className="h-4 w-4" />
            <AlertDescription className="text-sm">
              Use this if the code was lost or shared wrongly. The device stays unpaired.
            </AlertDescription>
          </Alert>
          <DialogFooter className="gap-2">
            <Button variant="outline" onClick={() => setView("details")} disabled={actionLoading}>
              Cancel
            </Button>
            <Button onClick={handleRegenerate} disabled={actionLoading} className="gap-2">
              {actionLoading ? <Loader2 className="h-4 w-4 animate-spin" /> : <RefreshCw className="h-4 w-4" />}
              Regenerate code
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    );
  }

  if (view === "unpair") {
    return (
      <Dialog open={open} onOpenChange={() => !actionLoading && setView("details")}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <div className="mx-auto mb-1 flex h-10 w-10 items-center justify-center rounded-full bg-amber-100 dark:bg-amber-900/20">
              <AlertTriangle className="h-5 w-5 text-amber-600 dark:text-amber-500" />
            </div>
            <DialogTitle className="text-center text-lg">Unpair Device?</DialogTitle>
            <DialogDescription className="text-center text-sm">
              This resets the device and generates a new pairing code.
            </DialogDescription>
          </DialogHeader>
          <Alert className="py-2">
            <AlertCircle className="h-4 w-4" />
            <AlertDescription className="text-sm">
              <ul className="list-disc list-inside space-y-1">
                <li>Device returns to unpaired status</li>
                <li>A new pairing code is generated</li>
                <li>Active conductor sessions end</li>
              </ul>
            </AlertDescription>
          </Alert>
          <DialogFooter className="gap-2">
            <Button variant="outline" onClick={() => setView("details")} disabled={actionLoading}>
              Cancel
            </Button>
            <Button variant="destructive" onClick={handleUnpair} disabled={actionLoading} className="gap-2">
              {actionLoading ? <Loader2 className="h-4 w-4 animate-spin" /> : null}
              Unpair Device
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    );
  }

  if (view === "delete") {
    return (
      <Dialog open={open} onOpenChange={() => !actionLoading && setView("details")}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <div className="mx-auto mb-1 flex h-10 w-10 items-center justify-center rounded-full bg-destructive/10">
              <Trash2 className="h-5 w-5 text-destructive" />
            </div>
            <DialogTitle className="text-center text-lg">Delete device?</DialogTitle>
            <DialogDescription className="text-center text-sm">
              This permanently removes <span className="font-mono font-medium">{device.serial_number}</span>.
            </DialogDescription>
          </DialogHeader>
          <Alert className="py-2">
            <AlertCircle className="h-4 w-4" />
            <AlertDescription className="text-sm">
              Only unpaired devices without ticket or trip history can be deleted.
            </AlertDescription>
          </Alert>
          <DialogFooter className="gap-2">
            <Button variant="outline" onClick={() => setView("details")} disabled={actionLoading}>
              Cancel
            </Button>
            <Button variant="destructive" onClick={handleDelete} disabled={actionLoading} className="gap-2">
              {actionLoading ? <Loader2 className="h-4 w-4 animate-spin" /> : <Trash2 className="h-4 w-4" />}
              Delete device
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    );
  }

  const paired = device.paired === true;
  const lastConductor =
    device.last_agent
      ? `${device.last_agent.full_name} (${device.last_agent.agent_code})`
      : device.active_session?.agent
        ? `${device.active_session.agent.full_name} (${device.active_session.agent.agent_code})`
        : null;

  const infoRows: InfoRow[] = [
    { label: "Serial Number", value: device.serial_number, icon: Smartphone, mono: true, copyable: true },
    { label: "Depot", value: device.depot_name || "N/A", icon: MapPin },
    { label: "Status", value: paired ? "Paired" : "Awaiting pairing", icon: Activity, badge: true },
    ...(paired && device.device_name
      ? [{ label: "Device Name", value: device.device_name, icon: Smartphone }]
      : []),
    ...(paired && device.device_model
      ? [{ label: "Model", value: device.device_model, icon: Smartphone }]
      : []),
    ...(paired && device.app_version
      ? [{ label: "App Version", value: device.app_version, icon: Activity }]
      : []),
    ...(device.paired_at
      ? [{ label: "Paired At", value: new Date(device.paired_at).toLocaleString(), icon: Calendar }]
      : []),
    ...(device.last_seen
      ? [{ label: "Last Seen", value: new Date(device.last_seen).toLocaleString(), icon: Clock }]
      : []),
    ...(lastConductor
      ? [{ label: "Last Conductor", value: lastConductor, icon: User }]
      : []),
    ...(device.last_agent_login_at
      ? [{ label: "Last Sign In", value: new Date(device.last_agent_login_at).toLocaleString(), icon: Calendar }]
      : []),
  ];

  const activeSessionCount = paired
    ? sessions.filter((s) => !s.ended_at).length
    : 0;

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
                paired
                  ? "bg-success/10 text-success border border-success/20"
                  : "bg-muted text-muted-foreground border border-border"
              }`}
            >
              {paired ? "Paired" : "Unpaired"}
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

          <TabsContent value="overview" className="mt-0 px-6 py-4 space-y-4 max-h-[min(60vh,480px)] overflow-y-auto">
            {!paired && (
              <div className="space-y-3">
                {pairingCode ? (
                  <PairingCodeDisplay
                    code={pairingCode}
                    onCopy={() => copyToClipboard(pairingCode, "Pairing code")}
                    hint="Visible while unpaired — share with the agent to activate the app"
                  />
                ) : (
                  <Alert className="py-2.5">
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
                    onClick={() => setView("regenerate")}
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
                            paired
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
                  {paired
                    ? "Conductor sign-ins on this device will appear here."
                    : "No conductor sessions recorded for this device yet. Past sessions remain visible after unpairing."}
                </p>
              </div>
            ) : (
              <>
                {activeSessionCount > 0 && (
                  <p className="text-xs text-muted-foreground mb-3 shrink-0">
                    {activeSessionCount} active · {sessions.length} total recorded
                  </p>
                )}
                {activeSessionCount === 0 && (
                  <p className="text-xs text-muted-foreground mb-3 shrink-0">
                    {sessions.length} session{sessions.length === 1 ? "" : "s"} recorded
                  </p>
                )}
                <div className="min-h-0 flex-1 overflow-y-auto overscroll-contain pr-1 -mr-1 max-h-[min(50vh,360px)] space-y-2">
                  {sessions.map((session) => {
                    const isActive = Boolean(paired && !session.ended_at);
                    const loginLabel =
                      session.login_type === "offline"
                        ? "Offline login"
                        : session.login_type === "online"
                          ? "Online login"
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
                              isActive ? "border-success/40 text-success bg-success/10" : ""
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

        <DialogFooter className="gap-2 px-6 py-4 border-t border-border/60 bg-muted/20 shrink-0 flex-wrap sm:justify-between">
          <div className="flex flex-wrap gap-2 mr-auto">
            {canManage && (
              <Button variant="outline" size="sm" className="gap-1.5" onClick={() => setView("edit")}>
                <Pencil className="h-3.5 w-3.5" />
                Edit
              </Button>
            )}
            {canManage && paired && (
              <Button
                variant="destructive"
                size="sm"
                className="gap-1.5"
                onClick={() => setView("unpair")}
              >
                <AlertTriangle className="h-3.5 w-3.5" />
                Unpair
              </Button>
            )}
            {canManage && !paired && (
              <Button
                variant="outline"
                size="sm"
                className="gap-1.5 text-destructive border-destructive/30 hover:bg-destructive/10"
                onClick={() => setView("delete")}
              >
                <Trash2 className="h-3.5 w-3.5" />
                Delete
              </Button>
            )}
          </div>
          <Button onClick={handleClose} variant="outline">
            Close
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};

export default DeviceInfoDialog;

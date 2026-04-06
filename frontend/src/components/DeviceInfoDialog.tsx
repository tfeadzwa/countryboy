import { useState } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Copy, Smartphone, MapPin, Calendar, Activity, AlertTriangle, CheckCircle2, Key, Loader2, AlertCircle } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { Badge } from "@/components/ui/badge";
import { deviceService } from "@/lib/api/device.service";
import { canManageDevices, isSuperAdmin } from "@/lib/permissions";
import { useAuth } from "@/contexts/AuthContext";
import type { Device } from "@/types";

interface DeviceInfoDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  device: Device | null;
  onUpdated?: () => void;
}

const DeviceInfoDialog = ({ open, onOpenChange, device, onUpdated }: DeviceInfoDialogProps) => {
  const { user } = useAuth();
  const { toast } = useToast();
  const [showUnpairConfirm, setShowUnpairConfirm] = useState(false);
  const [unpairLoading, setUnpairLoading] = useState(false);
  const [newPairingCode, setNewPairingCode] = useState<string | null>(null);
  
  const canManage = user ? canManageDevices(user.roles || []) : false;

  if (!device) return null;

  const copyToClipboard = (text: string, label: string) => {
    navigator.clipboard.writeText(text);
    toast({ title: "Copied!", description: `${label} copied to clipboard.` });
  };

  const handleUnpair = async () => {
    if (!device) return;
    
    setUnpairLoading(true);
    try {
      // For SUPER_ADMIN, pass depot ID for depot context
      const isSuperAdminUser = user ? isSuperAdmin(user.roles || []) : false;
      const result = await deviceService.unpair(
        device.id,
        isSuperAdminUser ? device.depot_id : undefined
      );
      setNewPairingCode(result.pairing_code);
      setShowUnpairConfirm(false);
      
      toast({
        title: "Device Unpaired",
        description: "New pairing code generated successfully.",
      });
      
      onUpdated?.();
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Failed to unpair device';
      toast({
        title: "Error",
        description: errorMessage,
        variant: "destructive",
      });
    } finally {
      setUnpairLoading(false);
    }
  };

  const handleClose = () => {
    setShowUnpairConfirm(false);
    setNewPairingCode(null);
    onOpenChange(false);
  };

  // If showing new pairing code after unpair
  if (newPairingCode) {
    return (
      <Dialog open={open} onOpenChange={handleClose}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <div className="mx-auto mb-1 flex h-10 w-10 items-center justify-center rounded-full bg-green-100 dark:bg-green-900/20">
              <CheckCircle2 className="h-5 w-5 text-green-600 dark:text-green-500" />
            </div>
            <DialogTitle className="text-center text-lg">Device Unpaired Successfully!</DialogTitle>
            <DialogDescription className="text-center text-sm">
              New pairing code generated. Save it securely.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-3 py-2">
            <Alert className="border-amber-200 bg-amber-50 dark:border-amber-900 dark:bg-amber-900/20 py-2">
              <Key className="h-4 w-4 text-amber-600 dark:text-amber-500" />
              <AlertDescription className="text-amber-800 dark:text-amber-200 text-sm">
                <strong>Important:</strong> This pairing code cannot be retrieved later. The agent must use it to pair the device again.
              </AlertDescription>
            </Alert>

            <div className="space-y-1.5">
              <Label>New Pairing Code</Label>
              <div className="flex gap-2">
                <Input
                  value={newPairingCode}
                  readOnly
                  className="font-mono text-lg text-center tracking-wider"
                />
                <Button
                  type="button"
                  size="icon"
                  variant="outline"
                  onClick={() => copyToClipboard(newPairingCode, "Pairing code")}
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

  // If showing unpair confirmation
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
                  <li>The agent must pair the device again using the new code</li>
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

  // Main device info display
  const infoRows = [
    { label: "Serial Number", value: device.serial_number, icon: Smartphone, mono: true, copyable: true },
    { label: "Depot", value: device.depot_name || "N/A", icon: MapPin },
    { label: "Status", value: device.paired ? "Paired" : "Unpaired", icon: Activity, badge: true },
    ...(device.paired && device.device_name ? [{ label: "Device Name", value: device.device_name, icon: Smartphone }] : []),
    ...(device.paired && device.device_model ? [{ label: "Model", value: device.device_model, icon: Smartphone }] : []),
    ...(device.paired && device.app_version ? [{ label: "App Version", value: device.app_version, icon: Activity }] : []),
    ...(device.paired_at ? [{ label: "Paired At", value: new Date(device.paired_at).toLocaleString(), icon: Calendar }] : []),
    ...(device.last_seen ? [{ label: "Last Seen", value: new Date(device.last_seen).toLocaleString(), icon: Activity }] : []),
  ];

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-[500px]">
        <DialogHeader>
          <div className="mx-auto mb-1 flex h-10 w-10 items-center justify-center rounded-full bg-primary/10">
            <Smartphone className="h-5 w-5 text-primary" />
          </div>
          <DialogTitle className="text-center text-lg">Device Details</DialogTitle>
          <DialogDescription className="text-center text-sm">
            {device.serial_number}
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-2.5">
          <div className="rounded-lg border border-border bg-muted/30 p-3">
            <div className="grid grid-cols-2 gap-2">
              {infoRows.map((item) => {
                const Icon = item.icon;
                return (
                  <div key={item.label} className="rounded-md border border-border bg-background p-2 relative">
                    <div className="flex items-center gap-1 mb-0.5">
                      <Icon className="h-3 w-3 text-muted-foreground" />
                      <p className="text-xs text-muted-foreground">{item.label}</p>
                    </div>
                    <div className={`text-sm font-semibold ${item.mono ? "font-mono" : ""}`}>
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
                        className="h-5 w-5 absolute top-1 right-1"
                        onClick={() => copyToClipboard(item.value, item.label)}
                      >
                        <Copy className="h-2.5 w-2.5" />
                      </Button>
                    )}
                  </div>
                );
              })}
            </div>
          </div>

          {!device.paired && (
            <Alert className="py-2">
              <AlertCircle className="h-4 w-4" />
              <AlertDescription className="text-sm">
                This device has not been paired yet. The agent needs to use the pairing code to activate the device.
              </AlertDescription>
            </Alert>
          )}
        </div>

        <DialogFooter className="gap-2 pt-1">
          {canManage && device.paired && (
            <Button
              variant="destructive"
              onClick={() => setShowUnpairConfirm(true)}
              className="gap-2"
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

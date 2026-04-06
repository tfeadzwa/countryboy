import { useState, useEffect } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Smartphone, Loader2, AlertCircle, Copy, CheckCircle2, Key } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { deviceService } from "@/lib/api/device.service";
import { depotService } from "@/lib/api/depot.service";
import { useAuth } from "@/contexts/AuthContext";
import { isSuperAdmin } from "@/lib/permissions";
import type { Depot } from "@/types";

interface RegisterDeviceDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSuccess?: () => void;
}

const RegisterDeviceDialog = ({ open, onOpenChange, onSuccess }: RegisterDeviceDialogProps) => {
  const { user } = useAuth();
  const [serialNumber, setSerialNumber] = useState("");
  const [selectedDepotId, setSelectedDepotId] = useState("");
  const [depots, setDepots] = useState<Depot[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [pairingCode, setPairingCode] = useState<string | null>(null);
  const { toast } = useToast();
  
  const isSuperAdminUser = user ? isSuperAdmin(user.roles || []) : false;

  // Load depots for SUPER_ADMIN
  useEffect(() => {
    const loadDepots = async () => {
      if (isSuperAdminUser && open) {
        try {
          const depotList = await depotService.getAll();
          setDepots(depotList);
          if (depotList.length > 0 && !selectedDepotId) {
            setSelectedDepotId(depotList[0].id);
          }
        } catch (err) {
          console.error('Failed to load depots:', err);
        }
      }
    };
    loadDepots();
  }, [isSuperAdminUser, open, selectedDepotId]);

  // Reset form when closing
  useEffect(() => {
    if (!open) {
      setSerialNumber("");
      setSelectedDepotId("");
      setError(null);
      setPairingCode(null);
    }
  }, [open]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    if (!serialNumber.trim()) {
      setError("Serial number is required");
      return;
    }

    if (isSuperAdminUser && !selectedDepotId) {
      setError("Please select a depot");
      return;
    }

    setLoading(true);

    try {
      const device = await deviceService.create(
        { serial_number: serialNumber.trim() },
        isSuperAdminUser ? selectedDepotId : undefined
      );
      
      // Show pairing code
      setPairingCode(device.pairing_code || "");
      
      toast({
        title: "Device Registered!",
        description: `Serial number ${serialNumber} registered successfully.`,
      });

      onSuccess?.();
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to register device';
      if (errorMessage.includes('Depot context')) {
        setError('Unable to register device. Please try again.');
      } else if (errorMessage.includes('duplicate') || errorMessage.includes('already exists')) {
        setError('A device with this serial number already exists.');
      } else {
        setError(errorMessage);
      }
    } finally {
      setLoading(false);
    }
  };

  const copyPairingCode = () => {
    if (pairingCode) {
      navigator.clipboard.writeText(pairingCode);
      toast({ title: "Copied!", description: "Pairing code copied to clipboard." });
    }
  };

  const handleClose = () => {
    setSerialNumber("");
    setSelectedDepotId("");
    setError(null);
    setPairingCode(null);
    onOpenChange(false);
  };

  return (
    <Dialog open={open} onOpenChange={handleClose}>
      <DialogContent className="sm:max-w-md">
        {!pairingCode ? (
          <>
            <DialogHeader>
              <div className="mx-auto mb-1 flex h-10 w-10 items-center justify-center rounded-full bg-primary/10">
                <Smartphone className="h-5 w-5 text-primary" />
              </div>
              <DialogTitle className="text-center text-lg">Register New Device</DialogTitle>
              <DialogDescription className="text-center text-sm">
                Add a new ticketing device to a depot.
              </DialogDescription>
            </DialogHeader>

            <form onSubmit={handleSubmit} className="space-y-4 pt-2">
              {error && (
                <Alert variant="destructive" className="py-2">
                  <AlertCircle className="h-4 w-4" />
                  <AlertDescription className="text-sm">{error}</AlertDescription>
                </Alert>
              )}

              <div className="space-y-2">
                <Label htmlFor="serial-number">Serial Number</Label>
                <Input
                  id="serial-number"
                  placeholder="e.g. DEV-A1B2C3"
                  value={serialNumber}
                  onChange={(e) => setSerialNumber(e.target.value)}
                  required
                  disabled={loading}
                />
                <p className="text-xs text-muted-foreground">
                  The unique serial number found on the device.
                </p>
              </div>

              {isSuperAdminUser && (
                <div className="space-y-2">
                  <Label htmlFor="depot">Assign to Depot</Label>
                  <Select value={selectedDepotId} onValueChange={setSelectedDepotId} required disabled={loading}>
                    <SelectTrigger id="depot">
                      <SelectValue placeholder="Select a depot" />
                    </SelectTrigger>
                    <SelectContent>
                      {depots.map((d) => (
                        <SelectItem key={d.id} value={d.id}>
                          {d.name} — {d.location}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              )}

              <DialogFooter className="pt-1">
                <Button type="button" variant="outline" onClick={handleClose} disabled={loading}>
                  Cancel
                </Button>
                <Button 
                  type="submit" 
                  disabled={loading || !serialNumber.trim() || (isSuperAdminUser && !selectedDepotId)} 
                  className="gap-2"
                >
                  {loading ? (
                    <>
                      <Loader2 className="h-4 w-4 animate-spin" />
                      Registering…
                    </>
                  ) : (
                    "Register Device"
                  )}
                </Button>
              </DialogFooter>
            </form>
          </>
        ) : (
          <>
            <DialogHeader>
              <div className="mx-auto mb-1 flex h-10 w-10 items-center justify-center rounded-full bg-green-100 dark:bg-green-900/20">
                <CheckCircle2 className="h-5 w-5 text-green-600 dark:text-green-500" />
              </div>
              <DialogTitle className="text-center text-lg">Device Registered Successfully!</DialogTitle>
              <DialogDescription className="text-center text-sm">
                Save the pairing code below. It will only be displayed once.
              </DialogDescription>
            </DialogHeader>

            <div className="space-y-3 py-2">
              <Alert className="border-amber-200 bg-amber-50 dark:border-amber-900 dark:bg-amber-900/20 py-2">
                <Key className="h-4 w-4 text-amber-600 dark:text-amber-500" />
                <AlertDescription className="text-amber-800 dark:text-amber-200 text-sm">
                  <strong>Important:</strong> This pairing code cannot be retrieved later. The agent must use it to pair the device with the mobile app.
                </AlertDescription>
              </Alert>

              <div className="space-y-1.5">
                <Label>Pairing Code</Label>
                <div className="flex gap-2">
                  <Input
                    value={pairingCode}
                    readOnly
                    className="font-mono text-lg text-center tracking-wider"
                  />
                  <Button
                    type="button"
                    size="icon"
                    variant="outline"
                    onClick={copyPairingCode}
                    className="shrink-0"
                  >
                    <Copy className="h-4 w-4" />
                  </Button>
                </div>
              </div>

              <div className="rounded-md bg-muted p-2.5 text-sm text-muted-foreground">
                <p className="font-medium mb-1 text-xs">Next Steps:</p>
                <ol className="list-decimal list-inside space-y-0.5 text-xs">
                  <li>Share this pairing code with the agent</li>
                  <li>Agent opens the mobile app</li>
                  <li>Agent enters the pairing code when prompted</li>
                  <li>Device will be activated and ready to use</li>
                </ol>
              </div>
            </div>

            <DialogFooter>
              <Button onClick={handleClose} className="w-full">
                Close
              </Button>
            </DialogFooter>
          </>
        )}
      </DialogContent>
    </Dialog>
  );
};

export default RegisterDeviceDialog;

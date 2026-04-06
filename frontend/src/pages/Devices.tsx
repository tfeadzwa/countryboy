import { useState, useEffect } from "react";
import { motion } from "framer-motion";
import PageHeader from "@/components/PageHeader";
import { deviceService } from "@/lib/api/device.service";
import { TableCell, TableRow } from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { Plus, Smartphone, Wifi, WifiOff, Eye, Clock, Loader2 } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { ResponsiveTable } from "@/components/ResponsiveTable";
import RegisterDeviceDialog from "@/components/RegisterDeviceDialog";
import DeviceInfoDialog from "@/components/DeviceInfoDialog";
import ErrorAlert from "@/components/ErrorAlert";
import { canManageDevices } from "@/lib/permissions";
import { useAuth } from "@/contexts/AuthContext";
import type { Device } from "@/types";

const statusConfig = {
  paired: { class: "bg-success/10 text-success border border-success/20", dot: "bg-success", icon: Wifi, label: "Paired" },
  unpaired: { class: "bg-muted text-muted-foreground border border-border", dot: "bg-muted-foreground", icon: WifiOff, label: "Unpaired" },
};

const columns = [
  { header: "Serial Number" },
  { header: "Depot" },
  { header: "Status" },
  { header: "Last Seen" },
  { header: "Paired At" },
  { header: "Actions", className: "text-right" },
];

const Devices = () => {
  const { user } = useAuth();
  const [devices, setDevices] = useState<Device[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [selectedDevice, setSelectedDevice] = useState<Device | null>(null);
  
  const canManage = user ? canManageDevices(user.roles || []) : false;

  const fetchDevices = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await deviceService.getAll();
      setDevices(data);
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to load devices';
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDevices();
  }, []);

  const handleDeviceRegistered = () => {
    fetchDevices();
  };

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.3 }}>
      <PageHeader title="Devices" description="Manage registered ticketing devices across depots">
        {canManage && (
          <Button size="sm" className="gap-2 shadow-sm" onClick={() => setDialogOpen(true)}>
            <Plus className="h-4 w-4" /> Register Device
          </Button>
        )}
      </PageHeader>
      
      <RegisterDeviceDialog 
        open={dialogOpen} 
        onOpenChange={setDialogOpen} 
        onSuccess={handleDeviceRegistered}
      />
      
      <DeviceInfoDialog
        open={!!selectedDevice}
        onOpenChange={(open) => { if (!open) setSelectedDevice(null); }}
        device={selectedDevice}
        onUpdated={fetchDevices}
      />

      {loading ? (
        <div className="flex items-center justify-center py-12">
          <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
        </div>
      ) : (
        <>
          <ErrorAlert error={error} />
          {devices.length === 0 ? (
        <div className="text-center py-12">
          <Smartphone className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
          <p className="text-muted-foreground">No devices registered yet.</p>
          {canManage && (
            <Button size="sm" className="gap-2 mt-4" onClick={() => setDialogOpen(true)}>
              <Plus className="h-4 w-4" /> Register First Device
            </Button>
          )}
        </div>
      ) : (
          <ResponsiveTable<Device>
          columns={columns}
          data={devices}
          keyExtractor={(d) => d.id}
          renderRow={(d) => {
            const config = d.paired ? statusConfig.paired : statusConfig.unpaired;
            const StatusIcon = config.icon;
            return (
              <TableRow key={d.id} className="group cursor-pointer hover:bg-muted/30 transition-colors" onClick={() => setSelectedDevice(d)}>
                <TableCell>
                  <div className="flex items-center gap-2.5">
                    <div className={`h-8 w-8 rounded-lg flex items-center justify-center ${d.paired ? "bg-success/10" : "bg-muted"}`}>
                      <Smartphone className={`h-4 w-4 ${d.paired ? "text-success" : "text-muted-foreground"}`} />
                    </div>
                    <span className="font-mono font-medium text-sm">{d.serial_number}</span>
                  </div>
                </TableCell>
                <TableCell className="text-muted-foreground text-sm">{d.depot_name || 'N/A'}</TableCell>
                <TableCell>
                  <Badge className={`text-xs gap-1.5 ${config.class}`}>
                    <StatusIcon className="h-3 w-3" />{config.label}
                  </Badge>
                </TableCell>
                <TableCell>
                  <span className="flex items-center gap-1.5 text-sm text-muted-foreground">
                    <Clock className="h-3.5 w-3.5" />
                    {d.last_seen ? new Date(d.last_seen).toLocaleString() : "Never"}
                  </span>
                </TableCell>
                <TableCell className="text-sm text-muted-foreground">
                  {d.paired_at ? new Date(d.paired_at).toLocaleDateString() : "—"}
                </TableCell>
                <TableCell className="text-right space-x-1">
                  <Button variant="ghost" size="sm" className="gap-1" onClick={(e) => { e.stopPropagation(); setSelectedDevice(d); }}>
                    <Eye className="h-3.5 w-3.5" /> Details
                  </Button>
                </TableCell>
              </TableRow>
            );
          }}
          renderCard={(d) => {
            const config = d.paired ? statusConfig.paired : statusConfig.unpaired;
            const StatusIcon = config.icon;
            return (
              <div className="space-y-3 cursor-pointer" onClick={() => setSelectedDevice(d)}>
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2.5">
                    <div className={`h-9 w-9 rounded-lg flex items-center justify-center ${d.paired ? "bg-success/10" : "bg-muted"}`}>
                      <Smartphone className={`h-4 w-4 ${d.paired ? "text-success" : "text-muted-foreground"}`} />
                    </div>
                    <div>
                      <p className="font-mono font-medium text-sm">{d.serial_number}</p>
                      <p className="text-xs text-muted-foreground">{d.depot_name || 'N/A'}</p>
                    </div>
                  </div>
                  <Badge className={`text-xs gap-1.5 ${config.class}`}>
                    <StatusIcon className="h-3 w-3" />{config.label}
                  </Badge>
                </div>
                <div className="grid grid-cols-2 gap-2 text-sm">
                  <div>
                    <p className="text-muted-foreground text-xs">Last Seen</p>
                    <p className="font-medium">{d.last_seen ? new Date(d.last_seen).toLocaleDateString() : "Never"}</p>
                  </div>
                  <div>
                    <p className="text-muted-foreground text-xs">Paired At</p>
                    <p>{d.paired_at ? new Date(d.paired_at).toLocaleDateString() : "—"}</p>
                  </div>
                </div>
                <div className="flex justify-between items-center pt-2 border-t border-border/40">
                  <Button variant="ghost" size="sm" className="gap-1 text-accent" onClick={(e) => { e.stopPropagation(); setSelectedDevice(d); }}>
                    <Eye className="h-3.5 w-3.5" /> View Details
                  </Button>
                </div>
              </div>
            );
          }}
          />
        )}
        </>
      )}
    </motion.div>
  );
};

export default Devices;

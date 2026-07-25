import { useState, useEffect, useCallback, useMemo } from "react";
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

const PRESENCE_POLL_MS = 30_000;

const pairConfig = {
  paired: { class: "bg-success/10 text-success border border-success/20", icon: Wifi, label: "Paired" },
  unpaired: { class: "bg-muted text-muted-foreground border border-border", icon: WifiOff, label: "Unpaired" },
};

const presenceConfig = {
  online: { class: "bg-success/10 text-success border border-success/20 uppercase tracking-wide", label: "Online" },
  offline: { class: "bg-muted text-muted-foreground border border-border uppercase tracking-wide", label: "Offline" },
};

const columns = [
  { header: "Serial Number" },
  { header: "Depot" },
  { header: "Device" },
  { header: "Conductor" },
  { header: "Presence" },
  { header: "Last Seen" },
  { header: "Paired At" },
  { header: "Actions", className: "text-right" },
];

const isPaired = (device: Device) => device.paired === true;

const formatDateTime = (value?: string | null) => {
  if (!value) return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return null;
  return date.toLocaleString();
};

const formatDate = (value?: string | null) => {
  if (!value) return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return null;
  return date.toLocaleDateString();
};

const lastConductorLabel = (device: Device) => {
  if (device.last_agent) {
    return `${device.last_agent.full_name} (${device.last_agent.agent_code})`;
  }
  if (device.active_session?.agent) {
    return `${device.active_session.agent.full_name} (${device.active_session.agent.agent_code})`;
  }
  return null;
};

const conductorPresence = (device: Device): "online" | "offline" | null => {
  if (device.conductor_status === "online" || device.conductor_status === "offline") {
    return device.conductor_status;
  }
  if (device.is_online) return "online";
  if (device.active_session) return "offline";
  return null;
};

const hasAssignedConductor = (device: Device) =>
  Boolean(device.active_session?.agent || device.last_agent);

const toTimestamp = (value?: string | null) => {
  if (!value) return 0;
  const time = new Date(value).getTime();
  return Number.isNaN(time) ? 0 : time;
};

/** Lower rank sorts first: online → offline → paired+conductor → paired → unpaired. */
const deviceSortRank = (device: Device) => {
  const presence = conductorPresence(device);
  if (presence === "online") return 0;
  if (presence === "offline") return 1;
  if (isPaired(device) && hasAssignedConductor(device)) return 2;
  if (isPaired(device)) return 3;
  return 4;
};

const compareDevices = (a: Device, b: Device) => {
  const rankDiff = deviceSortRank(a) - deviceSortRank(b);
  if (rankDiff !== 0) return rankDiff;

  const lastSeenDiff = toTimestamp(b.last_seen) - toTimestamp(a.last_seen);
  if (lastSeenDiff !== 0) return lastSeenDiff;

  const pairedAtDiff = toTimestamp(b.paired_at) - toTimestamp(a.paired_at);
  if (pairedAtDiff !== 0) return pairedAtDiff;

  return a.serial_number.localeCompare(b.serial_number);
};

const Devices = () => {
  const { user } = useAuth();
  const [devices, setDevices] = useState<Device[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [selectedDevice, setSelectedDevice] = useState<Device | null>(null);

  const canManage = user ? canManageDevices(user.roles || []) : false;

  const fetchDevices = useCallback(async (opts?: { silent?: boolean }) => {
    if (!opts?.silent) {
      setLoading(true);
    }
    setError(null);
    try {
      const data = await deviceService.getAll();
      setDevices(data);
      setSelectedDevice((current) => {
        if (!current) return null;
        return data.find((d) => d.id === current.id) ?? null;
      });
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : "Failed to load devices";
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchDevices();
    const id = window.setInterval(() => fetchDevices({ silent: true }), PRESENCE_POLL_MS);
    return () => window.clearInterval(id);
  }, [fetchDevices]);

  const handleDeviceRegistered = () => {
    fetchDevices();
  };

  const sortedDevices = useMemo(
    () => [...devices].sort(compareDevices),
    [devices],
  );

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
        onOpenChange={(open) => {
          if (!open) setSelectedDevice(null);
        }}
        device={selectedDevice}
        onUpdated={() => fetchDevices()}
        onDeleted={() => setSelectedDevice(null)}
      />

      {loading && devices.length === 0 ? (
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
              data={sortedDevices}
              keyExtractor={(d) => d.id}
              renderRow={(d) => {
                const paired = isPaired(d);
                const config = paired ? pairConfig.paired : pairConfig.unpaired;
                const StatusIcon = config.icon;
                const conductor = lastConductorLabel(d);
                const presence = conductorPresence(d);
                const lastSeen = formatDateTime(d.last_seen);
                const pairedAt = formatDate(d.paired_at);
                return (
                  <TableRow
                    key={d.id}
                    className="group cursor-pointer hover:bg-muted/30 transition-colors"
                    onClick={() => setSelectedDevice(d)}
                  >
                    <TableCell>
                      <div className="flex items-center gap-2.5">
                        <div
                          className={`h-8 w-8 rounded-lg flex items-center justify-center ${
                            paired ? "bg-success/10" : "bg-muted"
                          }`}
                        >
                          <Smartphone
                            className={`h-4 w-4 ${paired ? "text-success" : "text-muted-foreground"}`}
                          />
                        </div>
                        <span className="font-mono font-medium text-sm">{d.serial_number}</span>
                      </div>
                    </TableCell>
                    <TableCell className="text-muted-foreground text-sm">{d.depot_name || "N/A"}</TableCell>
                    <TableCell>
                      <Badge className={`text-xs gap-1.5 ${config.class}`}>
                        <StatusIcon className="h-3 w-3" />
                        {config.label}
                      </Badge>
                    </TableCell>
                    <TableCell className="text-sm text-muted-foreground">{conductor ?? "—"}</TableCell>
                    <TableCell>
                      {presence ? (
                        <Badge className={`text-xs ${presenceConfig[presence].class}`}>
                          {presenceConfig[presence].label}
                        </Badge>
                      ) : (
                        <span className="text-sm text-muted-foreground">—</span>
                      )}
                    </TableCell>
                    <TableCell>
                      <span className="flex items-center gap-1.5 text-sm text-muted-foreground">
                        <Clock className="h-3.5 w-3.5" />
                        {lastSeen ?? "Never"}
                      </span>
                    </TableCell>
                    <TableCell className="text-sm text-muted-foreground">{pairedAt ?? "—"}</TableCell>
                    <TableCell className="text-right space-x-1">
                      <Button
                        variant="ghost"
                        size="sm"
                        className="gap-1"
                        onClick={(e) => {
                          e.stopPropagation();
                          setSelectedDevice(d);
                        }}
                      >
                        <Eye className="h-3.5 w-3.5" /> Details
                      </Button>
                    </TableCell>
                  </TableRow>
                );
              }}
              renderCard={(d) => {
                const paired = isPaired(d);
                const config = paired ? pairConfig.paired : pairConfig.unpaired;
                const StatusIcon = config.icon;
                const conductor = lastConductorLabel(d);
                const presence = conductorPresence(d);
                const lastSeen = formatDate(d.last_seen);
                const pairedAt = formatDate(d.paired_at);
                return (
                  <div className="space-y-3 cursor-pointer" onClick={() => setSelectedDevice(d)}>
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2.5">
                        <div
                          className={`h-9 w-9 rounded-lg flex items-center justify-center ${
                            paired ? "bg-success/10" : "bg-muted"
                          }`}
                        >
                          <Smartphone
                            className={`h-4 w-4 ${paired ? "text-success" : "text-muted-foreground"}`}
                          />
                        </div>
                        <div>
                          <p className="font-mono font-medium text-sm">{d.serial_number}</p>
                          <p className="text-xs text-muted-foreground">{d.depot_name || "N/A"}</p>
                        </div>
                      </div>
                      <div className="flex flex-col items-end gap-1">
                        <Badge className={`text-xs gap-1.5 ${config.class}`}>
                          <StatusIcon className="h-3 w-3" />
                          {config.label}
                        </Badge>
                        {presence && (
                          <Badge className={`text-xs ${presenceConfig[presence].class}`}>
                            {presenceConfig[presence].label}
                          </Badge>
                        )}
                      </div>
                    </div>
                    <div className="grid grid-cols-2 gap-2 text-sm">
                      <div>
                        <p className="text-muted-foreground text-xs">Conductor</p>
                        <p className="font-medium">{conductor ?? "—"}</p>
                      </div>
                      <div>
                        <p className="text-muted-foreground text-xs">Last Seen</p>
                        <p className="font-medium">{lastSeen ?? "Never"}</p>
                      </div>
                      <div>
                        <p className="text-muted-foreground text-xs">Paired At</p>
                        <p>{pairedAt ?? "—"}</p>
                      </div>
                    </div>
                    <div className="flex justify-between items-center pt-2 border-t border-border/40">
                      <Button
                        variant="ghost"
                        size="sm"
                        className="gap-1 text-accent"
                        onClick={(e) => {
                          e.stopPropagation();
                          setSelectedDevice(d);
                        }}
                      >
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

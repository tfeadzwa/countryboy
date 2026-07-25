import { useCallback, useEffect, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import { Bus, Eye, Loader2, Pencil, Plus, Trash2, UserRound } from "lucide-react";
import PageHeader from "@/components/PageHeader";
import { ResponsiveTable } from "@/components/ResponsiveTable";
import { TableCell, TableRow } from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import AddDriverDialog from "@/components/AddDriverDialog";
import ConfirmDeleteDialog from "@/components/ConfirmDeleteDialog";
import TablePagination from "@/components/TablePagination";
import ErrorAlert from "@/components/ErrorAlert";
import { driverService } from "@/lib/api/driver.service";
import { useAuth } from "@/contexts/AuthContext";
import { canManageDrivers, isSuperAdmin } from "@/lib/permissions";
import { useToast } from "@/hooks/use-toast";
import { DEFAULT_PAGE_SIZE } from "@/types/pagination";
import type { Driver, DriverDutyStatus } from "@/types";

const PRESENCE_POLL_MS = 30_000;

const accountStatusConfig: Record<string, { class: string; dot: string }> = {
  ACTIVE: { class: "bg-success/10 text-success border border-success/20", dot: "bg-success" },
  SUSPENDED: { class: "bg-destructive/10 text-destructive border border-destructive/20", dot: "bg-destructive" },
  INACTIVE: { class: "bg-muted text-muted-foreground", dot: "bg-muted-foreground" },
};

const dutyConfig: Record<DriverDutyStatus, { class: string; label: string }> = {
  on_trip: {
    class: "bg-amber-500/15 text-amber-800 border border-amber-500/35 uppercase tracking-wide",
    label: "On trip",
  },
  available: {
    class: "bg-success/10 text-success border border-success/20 uppercase tracking-wide",
    label: "Available",
  },
  off_duty: {
    class: "bg-muted text-muted-foreground border border-border uppercase tracking-wide",
    label: "Off duty",
  },
};

const columns = [
  { header: "Full Name" },
  { header: "Phone" },
  { header: "Depot" },
  { header: "Duty" },
  { header: "Account" },
  { header: "Actions", className: "text-right" },
];

const dutyOf = (driver: Driver): DriverDutyStatus => {
  if (driver.duty_status) return driver.duty_status;
  if (driver.status !== "ACTIVE") return "off_duty";
  return driver.on_trip || driver.active_trip ? "on_trip" : "available";
};

const tripLabel = (driver: Driver) => {
  const trip = driver.active_trip;
  if (!trip) return null;
  const bus = trip.fleet_number ? `Bus ${trip.fleet_number}` : "Bus —";
  const corridor = `${trip.origin} → ${trip.destination}`;
  const conductor = trip.agent_name ? ` · ${trip.agent_name}` : "";
  return `${bus} · ${corridor}${conductor}`;
};

const toTimestamp = (value?: string | null) => {
  if (!value) return 0;
  const time = new Date(value).getTime();
  return Number.isNaN(time) ? 0 : time;
};

const driverSortRank = (driver: Driver) => {
  const duty = dutyOf(driver);
  if (duty === "on_trip") return 0;
  if (duty === "available") return 1;
  return 2;
};

const compareDrivers = (a: Driver, b: Driver) => {
  const rankDiff = driverSortRank(a) - driverSortRank(b);
  if (rankDiff !== 0) return rankDiff;

  const tripDiff =
    toTimestamp(b.active_trip?.started_at) - toTimestamp(a.active_trip?.started_at);
  if (tripDiff !== 0) return tripDiff;

  return a.full_name.localeCompare(b.full_name);
};

const Drivers = () => {
  const { user } = useAuth();
  const { toast } = useToast();
  const navigate = useNavigate();
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingDriver, setEditingDriver] = useState<Driver | undefined>(undefined);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [totalPages, setTotalPages] = useState(1);
  const [deleteTarget, setDeleteTarget] = useState<Driver | null>(null);
  const [deleting, setDeleting] = useState(false);

  const userRoles = user?.roles || [];
  const canManage = canManageDrivers(userRoles);
  const isSuperAdminUser = isSuperAdmin(userRoles);

  const fetchDrivers = useCallback(async (opts?: { silent?: boolean }) => {
    try {
      if (!opts?.silent) setLoading(true);
      setError(null);
      const data = await driverService.listPaginated(page, DEFAULT_PAGE_SIZE);
      setDrivers(data.items ?? []);
      setTotal(data.total ?? 0);
      setTotalPages(data.totalPages ?? 1);
    } catch (err) {
      const message = err instanceof Error ? err.message : "Failed to load drivers";
      // Empty depot / legacy "not found" responses should show the empty state, not an error.
      if (/not found/i.test(message)) {
        setDrivers([]);
        setTotal(0);
        setTotalPages(1);
        setError(null);
      } else {
        setError(message);
      }
    } finally {
      setLoading(false);
    }
  }, [page]);

  useEffect(() => {
    void fetchDrivers();
    const id = window.setInterval(() => void fetchDrivers({ silent: true }), PRESENCE_POLL_MS);
    return () => window.clearInterval(id);
  }, [fetchDrivers]);

  const sortedDrivers = useMemo(() => [...drivers].sort(compareDrivers), [drivers]);

  const handleDialogClose = (open: boolean) => {
    setDialogOpen(open);
    if (!open) setEditingDriver(undefined);
  };

  const handleSaved = () => {
    if (page !== 1 && !editingDriver) setPage(1);
    else void fetchDrivers();
  };

  const handleDelete = async () => {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      await driverService.remove(
        deleteTarget.id,
        isSuperAdminUser ? deleteTarget.depot_id : undefined,
      );
      toast({ title: "Driver deleted", description: `${deleteTarget.full_name} was removed.` });
      setDeleteTarget(null);
      if (drivers.length === 1 && page > 1) setPage((p) => p - 1);
      else void fetchDrivers();
    } catch (err) {
      toast({
        title: "Could not delete driver",
        description: err instanceof Error ? err.message : "Try again",
        variant: "destructive",
      });
    } finally {
      setDeleting(false);
    }
  };

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.3 }}>
      <PageHeader title="Drivers" description="Manage bus drivers assigned to each depot">
        {canManage && (
          <Button size="sm" className="gap-2 shadow-sm" onClick={() => setDialogOpen(true)}>
            <Plus className="h-4 w-4" /> Add Driver
          </Button>
        )}
      </PageHeader>

      <ErrorAlert error={error} />

      <AddDriverDialog
        open={dialogOpen}
        onOpenChange={handleDialogClose}
        onSuccess={handleSaved}
        driver={editingDriver}
      />

      <ConfirmDeleteDialog
        open={!!deleteTarget}
        onOpenChange={(open) => {
          if (!open) setDeleteTarget(null);
        }}
        title="Delete driver?"
        description={
          deleteTarget
            ? `This will permanently remove ${deleteTarget.full_name}. Drivers with trip history cannot be deleted.`
            : ""
        }
        loading={deleting}
        onConfirm={handleDelete}
      />

      {loading && drivers.length === 0 ? (
        <div className="flex items-center justify-center py-16 text-muted-foreground">
          <Loader2 className="mr-2 h-5 w-5 animate-spin" />
          Loading drivers…
        </div>
      ) : total === 0 ? (
        <div className="rounded-3xl border border-dashed border-border/80 bg-muted/20 px-6 py-16 text-center">
          <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-primary/10">
            <UserRound className="h-6 w-6 text-primary" />
          </div>
          <p className="text-base font-semibold">No drivers yet</p>
          <p className="mt-1 text-sm text-muted-foreground">
            Add drivers for this depot so conductors can assign them when starting a trip.
          </p>
          {canManage && (
            <Button size="sm" className="mt-5 gap-2" onClick={() => setDialogOpen(true)}>
              <Plus className="h-4 w-4" /> Add first driver
            </Button>
          )}
        </div>
      ) : (
        <div className="space-y-4">
          <ResponsiveTable
            columns={columns}
            data={sortedDrivers}
            keyExtractor={(d) => d.id}
            renderRow={(driver) => {
              const account = accountStatusConfig[driver.status] ?? accountStatusConfig.INACTIVE;
              const duty = dutyConfig[dutyOf(driver)];
              const trip = tripLabel(driver);
              return (
                <TableRow key={driver.id} className="group hover:bg-muted/30 transition-colors">
                  <TableCell>
                    <div className="flex items-center gap-2.5">
                      <div className="h-8 w-8 rounded-full bg-primary/10 flex items-center justify-center">
                        <UserRound className="h-4 w-4 text-primary" />
                      </div>
                      <div>
                        <span className="font-medium">{driver.full_name}</span>
                        {driver.licence_number && (
                          <p className="text-xs text-muted-foreground">
                            Licence {driver.licence_number}
                          </p>
                        )}
                      </div>
                    </div>
                  </TableCell>
                  <TableCell className="text-muted-foreground">{driver.phone || "—"}</TableCell>
                  <TableCell className="text-muted-foreground text-sm">
                    {driver.depot_name || "—"}
                  </TableCell>
                  <TableCell>
                    <div className="space-y-1.5">
                      <Badge className={`text-xs gap-1.5 ${duty.class}`}>
                        {dutyOf(driver) === "on_trip" && <Bus className="h-3 w-3" />}
                        {duty.label}
                      </Badge>
                      {trip && (
                        <p className="text-[11px] text-muted-foreground max-w-[220px] truncate" title={trip}>
                          {trip}
                        </p>
                      )}
                      {driver.active_trip?.id && (
                        <Button
                          variant="outline"
                          size="sm"
                          className="h-7 gap-1 text-xs"
                          onClick={() => navigate(`/trips/${driver.active_trip!.id}`)}
                        >
                          <Eye className="h-3 w-3" /> View trip
                        </Button>
                      )}
                    </div>
                  </TableCell>
                  <TableCell>
                    <Badge className={`text-xs gap-1.5 ${account.class}`}>
                      <span className={`h-1.5 w-1.5 rounded-full ${account.dot}`} />
                      {driver.status}
                    </Badge>
                  </TableCell>
                  <TableCell className="text-right space-x-1">
                    {canManage ? (
                      <>
                        <Button
                          variant="ghost"
                          size="sm"
                          className="gap-1"
                          onClick={() => {
                            setEditingDriver(driver);
                            setDialogOpen(true);
                          }}
                        >
                          <Pencil className="h-3.5 w-3.5" /> Edit
                        </Button>
                        <Button
                          variant="ghost"
                          size="sm"
                          className="text-destructive hover:text-destructive hover:bg-destructive/10"
                          onClick={() => setDeleteTarget(driver)}
                        >
                          <Trash2 className="h-3.5 w-3.5" />
                        </Button>
                      </>
                    ) : (
                      <span className="text-xs text-muted-foreground">View only</span>
                    )}
                  </TableCell>
                </TableRow>
              );
            }}
            renderCard={(driver) => {
              const account = accountStatusConfig[driver.status] ?? accountStatusConfig.INACTIVE;
              const duty = dutyConfig[dutyOf(driver)];
              const trip = tripLabel(driver);
              return (
                <div className="space-y-3">
                  <div className="flex items-center justify-between gap-2">
                    <div className="flex items-center gap-2.5 min-w-0">
                      <div className="h-9 w-9 rounded-full bg-primary/10 flex items-center justify-center shrink-0">
                        <UserRound className="h-4 w-4 text-primary" />
                      </div>
                      <div className="min-w-0">
                        <p className="font-medium text-sm truncate">{driver.full_name}</p>
                        <p className="text-xs text-muted-foreground">{driver.phone || "No phone"}</p>
                      </div>
                    </div>
                    <div className="flex flex-col items-end gap-1 shrink-0">
                      <Badge className={`text-xs gap-1.5 ${duty.class}`}>{duty.label}</Badge>
                      <Badge className={`text-xs gap-1.5 ${account.class}`}>
                        <span className={`h-1.5 w-1.5 rounded-full ${account.dot}`} />
                        {driver.status}
                      </Badge>
                    </div>
                  </div>
                  {trip && (
                    <p className="text-xs text-muted-foreground flex items-start gap-1.5">
                      <Bus className="h-3.5 w-3.5 mt-0.5 shrink-0" />
                      <span>{trip}</span>
                    </p>
                  )}
                  {driver.active_trip?.id && (
                    <Button
                      variant="outline"
                      size="sm"
                      className="w-full gap-1.5"
                      onClick={() => navigate(`/trips/${driver.active_trip!.id}`)}
                    >
                      <Eye className="h-3.5 w-3.5" /> View trip details
                    </Button>
                  )}
                  <div className="grid grid-cols-2 gap-2 text-sm">
                    <div>
                      <p className="text-muted-foreground text-xs">Phone</p>
                      <p className="font-medium">{driver.phone || "—"}</p>
                    </div>
                    <div>
                      <p className="text-muted-foreground text-xs">Depot</p>
                      <p className="font-medium">{driver.depot_name || "—"}</p>
                    </div>
                  </div>
                  {canManage && (
                    <div className="flex justify-end gap-1 pt-2 border-t border-border/40">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => {
                          setEditingDriver(driver);
                          setDialogOpen(true);
                        }}
                      >
                        Edit
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        className="text-destructive"
                        onClick={() => setDeleteTarget(driver)}
                      >
                        <Trash2 className="h-3.5 w-3.5" />
                      </Button>
                    </div>
                  )}
                </div>
              );
            }}
          />
          <TablePagination
            page={page}
            pageSize={DEFAULT_PAGE_SIZE}
            total={total}
            totalPages={totalPages}
            onPageChange={setPage}
          />
        </div>
      )}
    </motion.div>
  );
};

export default Drivers;

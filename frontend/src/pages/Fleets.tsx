import { useState, useEffect, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import PageHeader from "@/components/PageHeader";
import { fleetService } from "@/lib/api/fleet.service";
import { TableCell, TableRow } from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import {
  Plus,
  Bus,
  Loader2,
  Users,
  ShieldAlert,
  ShieldCheck,
  AlertTriangle,
  Trash2,
} from "lucide-react";
import { ResponsiveTable } from "@/components/ResponsiveTable";
import AddFleetDialog from "@/components/AddFleetDialog";
import ConfirmDeleteDialog from "@/components/ConfirmDeleteDialog";
import TablePagination from "@/components/TablePagination";
import ErrorAlert from "@/components/ErrorAlert";
import { canManageFleets, isSuperAdmin } from "@/lib/permissions";
import { useAuth } from "@/contexts/AuthContext";
import { useToast } from "@/hooks/use-toast";
import { frequencyStyles, severityStyles } from "@/lib/fleet-compliance";
import { DEFAULT_PAGE_SIZE } from "@/types/pagination";
import type { Fleet, FleetComplianceItem } from "@/types";

const columns = [
  { header: "Fleet Number" },
  { header: "Registration" },
  { header: "Depot" },
  { header: "Status" },
  { header: "Capacity" },
  { header: "Compliance" },
  { header: "Actions", className: "text-right" },
];

function ComplianceCell({ fleet }: { fleet: Fleet }) {
  const items = fleet.compliance || [];
  const worst = fleet.compliance_summary?.worst_severity || "ok";
  const attention = fleet.compliance_summary?.items_needing_attention || 0;
  const styles = severityStyles[worst] || severityStyles.ok;

  if (items.length === 0) {
    return <span className="text-xs text-muted-foreground">—</span>;
  }

  if (attention === 0 && worst !== "expired" && worst !== "urgent") {
    return (
      <Badge variant="outline" className={`text-[10px] gap-1 ${styles.badge}`}>
        <ShieldCheck className="h-3 w-3" />
        All documents valid
      </Badge>
    );
  }

  const urgentItems = items.filter(
    (i) => i.severity === "expired" || i.severity === "urgent" || i.severity === "warning"
  );

  return (
    <div className="flex flex-col gap-1.5 min-w-[160px]">
      <Badge variant="outline" className={`text-[10px] w-fit gap-1 ${styles.badge}`}>
        {worst === "expired" || worst === "urgent" ? (
          <ShieldAlert className="h-3 w-3" />
        ) : (
          <AlertTriangle className="h-3 w-3" />
        )}
        {attention} need{attention === 1 ? "s" : ""} attention
      </Badge>
      <div className="flex flex-wrap gap-1">
        {urgentItems.slice(0, 3).map((item: FleetComplianceItem) => (
          <Badge
            key={item.key}
            variant="outline"
            className={`text-[9px] font-medium ${
              item.frequency ? frequencyStyles[item.frequency] : styles.badge
            }`}
            title={`${item.label}: ${item.status_label}`}
          >
            {item.shortLabel}
            {item.frequency ? ` · ${item.frequency}` : ""}
          </Badge>
        ))}
        {urgentItems.length > 3 && (
          <span className="text-[10px] text-muted-foreground">+{urgentItems.length - 3}</span>
        )}
      </div>
    </div>
  );
}

const Fleets = () => {
  const navigate = useNavigate();
  const { user } = useAuth();
  const { toast } = useToast();
  const [fleets, setFleets] = useState<Fleet[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [totalPages, setTotalPages] = useState(1);
  const [deleteTarget, setDeleteTarget] = useState<Fleet | null>(null);
  const [deleting, setDeleting] = useState(false);

  const canManage = user ? canManageFleets(user.roles || []) : false;
  const isSuperAdminUser = user ? isSuperAdmin(user.roles || []) : false;

  const fetchFleets = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await fleetService.listPaginated(page, DEFAULT_PAGE_SIZE);
      setFleets(data.items ?? []);
      setTotal(data.total ?? 0);
      setTotalPages(data.totalPages ?? 1);
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : "Failed to load fleets";
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  }, [page]);

  useEffect(() => {
    fetchFleets();
  }, [fetchFleets]);

  const handleFleetSaved = () => {
    if (page !== 1) setPage(1);
    else fetchFleets();
  };

  const handleEdit = (fleet: Fleet) => {
    navigate(`/fleets/${fleet.id}/edit`);
  };

  const handleDialogClose = (open: boolean) => {
    setDialogOpen(open);
  };

  const handleDeleteConfirm = async () => {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      await fleetService.delete(
        deleteTarget.id,
        isSuperAdminUser ? deleteTarget.depot_id : undefined
      );
      toast({
        title: "Fleet deleted",
        description: `${deleteTarget.number} was removed successfully.`,
      });
      setDeleteTarget(null);
      if (fleets.length === 1 && page > 1) {
        setPage(page - 1);
      } else {
        fetchFleets();
      }
    } catch (err) {
      toast({
        title: "Delete failed",
        description: err instanceof Error ? err.message : "Could not delete fleet",
        variant: "destructive",
      });
    } finally {
      setDeleting(false);
    }
  };

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.3 }}>
      <PageHeader title="Buses" description="Manage buses, compliance documents, and expiry tracking">
        {canManage && (
          <Button
            size="sm"
            className="gap-2 shadow-sm"
            onClick={() => setDialogOpen(true)}
          >
            <Plus className="h-4 w-4" /> Add Fleet
          </Button>
        )}
      </PageHeader>

      <AddFleetDialog
        open={dialogOpen}
        onOpenChange={handleDialogClose}
        onSuccess={handleFleetSaved}
      />

      <ConfirmDeleteDialog
        open={!!deleteTarget}
        onOpenChange={(open) => !open && setDeleteTarget(null)}
        title="Delete fleet?"
        description={
          deleteTarget
            ? `This will permanently remove fleet ${deleteTarget.number}. Fleets with trip history cannot be deleted.`
            : ""
        }
        loading={deleting}
        onConfirm={handleDeleteConfirm}
      />

      {loading ? (
        <div className="flex items-center justify-center py-12">
          <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
        </div>
      ) : (
        <>
          <ErrorAlert error={error} />
          {total === 0 ? (
            <div className="text-center py-12">
              <Bus className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
              <p className="text-muted-foreground">No fleets registered yet.</p>
              {canManage && (
                <Button size="sm" className="gap-2 mt-4" onClick={() => setDialogOpen(true)}>
                  <Plus className="h-4 w-4" /> Add First Fleet
                </Button>
              )}
            </div>
          ) : (
            <div className="space-y-4">
              <ResponsiveTable<Fleet>
                columns={columns}
                data={fleets}
                keyExtractor={(f) => f.id}
                renderRow={(f) => (
                  <TableRow
                    key={f.id}
                    className={`group hover:bg-muted/30 transition-colors ${canManage ? "cursor-pointer" : ""}`}
                    onClick={() => {
                      if (canManage) handleEdit(f);
                    }}
                  >
                    <TableCell>
                      <div className="flex items-center gap-2.5">
                        <div className="h-8 w-8 rounded-lg flex items-center justify-center bg-primary/10">
                          <Bus className="h-4 w-4 text-primary" />
                        </div>
                        <span className="font-mono font-medium">{f.number}</span>
                      </div>
                    </TableCell>
                    <TableCell className="font-mono text-sm text-muted-foreground">
                      {f.registration_number || "—"}
                    </TableCell>
                    <TableCell className="text-muted-foreground text-sm">{f.depot_name || "N/A"}</TableCell>
                    <TableCell>
                      <Badge
                        variant={
                          f.status === "ACTIVE"
                            ? "default"
                            : f.status === "MAINTENANCE"
                              ? "secondary"
                              : "outline"
                        }
                        className={`text-xs ${
                          f.status === "ACTIVE"
                            ? "bg-green-500/10 text-green-700 border-green-500/20"
                            : f.status === "MAINTENANCE"
                              ? "bg-yellow-500/10 text-yellow-700 border-yellow-500/20"
                              : f.status === "OUT_OF_SERVICE"
                                ? "bg-red-500/10 text-red-700 border-red-500/20"
                                : "bg-gray-500/10 text-gray-700 border-gray-500/20"
                        }`}
                      >
                        {f.status.replace(/_/g, " ")}
                      </Badge>
                    </TableCell>
                    <TableCell className="text-sm text-muted-foreground">
                      <span className="flex items-center gap-1.5">
                        <Users className="h-3.5 w-3.5" />
                        {f.capacity} seats
                      </span>
                    </TableCell>
                    <TableCell>
                      <ComplianceCell fleet={f} />
                    </TableCell>
                    <TableCell className="text-right">
                      {canManage && (
                        <div className="flex justify-end gap-1" onClick={(e) => e.stopPropagation()}>
                          <Button variant="ghost" size="sm" onClick={() => handleEdit(f)}>
                            Edit
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            className="text-destructive hover:text-destructive hover:bg-destructive/10"
                            onClick={() => setDeleteTarget(f)}
                          >
                            <Trash2 className="h-3.5 w-3.5" />
                          </Button>
                        </div>
                      )}
                    </TableCell>
                  </TableRow>
                )}
                renderCard={(f) => (
                  <div
                    className={`space-y-3 ${canManage ? "cursor-pointer" : ""}`}
                    onClick={() => {
                      if (canManage) handleEdit(f);
                    }}
                  >
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2.5">
                        <div className="h-9 w-9 rounded-lg flex items-center justify-center bg-primary/10">
                          <Bus className="h-4 w-4 text-primary" />
                        </div>
                        <div>
                          <p className="font-mono font-medium text-sm">{f.number}</p>
                          <p className="text-xs text-muted-foreground">
                            {f.registration_number
                              ? `${f.registration_number} · ${f.depot_name || "N/A"}`
                              : f.depot_name || "N/A"}
                          </p>
                        </div>
                      </div>
                      <Badge
                        variant={
                          f.status === "ACTIVE"
                            ? "default"
                            : f.status === "MAINTENANCE"
                              ? "secondary"
                              : "outline"
                        }
                        className={`text-xs ${
                          f.status === "ACTIVE"
                            ? "bg-green-500/10 text-green-700 border-green-500/20"
                            : f.status === "MAINTENANCE"
                              ? "bg-yellow-500/10 text-yellow-700 border-yellow-500/20"
                              : f.status === "OUT_OF_SERVICE"
                                ? "bg-red-500/10 text-red-700 border-red-500/20"
                                : "bg-gray-500/10 text-gray-700 border-gray-500/20"
                        }`}
                      >
                        {f.status.replace(/_/g, " ")}
                      </Badge>
                    </div>
                    <div className="grid grid-cols-2 gap-2 text-sm">
                      <div>
                        <p className="text-muted-foreground text-xs">Capacity</p>
                        <p className="font-medium flex items-center gap-1">
                          <Users className="h-3 w-3 text-muted-foreground" />
                          {f.capacity} seats
                        </p>
                      </div>
                      <div>
                        <p className="text-muted-foreground text-xs">Compliance</p>
                        <ComplianceCell fleet={f} />
                      </div>
                    </div>
                    {canManage && (
                      <div
                        className="flex justify-end gap-1 pt-2 border-t border-border/40"
                        onClick={(e) => e.stopPropagation()}
                      >
                        <Button variant="ghost" size="sm" onClick={() => handleEdit(f)}>
                          Edit
                        </Button>
                        <Button
                          variant="ghost"
                          size="sm"
                          className="text-destructive"
                          onClick={() => setDeleteTarget(f)}
                        >
                          <Trash2 className="h-3.5 w-3.5" />
                        </Button>
                      </div>
                    )}
                  </div>
                )}
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
        </>
      )}
    </motion.div>
  );
};

export default Fleets;

import { useMemo, useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import PageHeader from "@/components/PageHeader";
import { routeService } from "@/lib/api/route.service";
import { fareService } from "@/lib/api/fare.service";
import { TableCell, TableRow } from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Plus, ArrowRight, Loader2, MapPin, Ruler, Search, Trash2 } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { ResponsiveTable } from "@/components/ResponsiveTable";
import AddRouteDialog from "@/components/AddRouteDialog";
import ConfirmDeleteDialog from "@/components/ConfirmDeleteDialog";
import TablePagination from "@/components/TablePagination";
import ErrorAlert from "@/components/ErrorAlert";
import { canManageRoutes, isSuperAdmin } from "@/lib/permissions";
import { useAuth } from "@/contexts/AuthContext";
import { useToast } from "@/hooks/use-toast";
import { DEFAULT_PAGE_SIZE } from "@/types/pagination";
import type { RouteInfo, Fare } from "@/types";

const routeColumns = [
  { header: "Departure" },
  { header: "Destination" },
  { header: "Fare" },
  { header: "Distance" },
  { header: "Status" },
  { header: "Depot" },
  { header: "Actions", className: "text-right" },
];

const formatAmount = (amount: Fare["amount"]) =>
  typeof amount === "number" ? amount.toFixed(2) : String(amount);

const RoutesPage = () => {
  const navigate = useNavigate();
  const { user } = useAuth();
  const { toast } = useToast();
  const [routes, setRoutes] = useState<RouteInfo[]>([]);
  const [fares, setFares] = useState<Fare[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [routeDialogOpen, setRouteDialogOpen] = useState(false);
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const [deleteTarget, setDeleteTarget] = useState<RouteInfo | null>(null);
  const [deleting, setDeleting] = useState(false);

  const canManageRoutesPermission = user ? canManageRoutes(user.roles || []) : false;
  const isSuperAdminUser = user ? isSuperAdmin(user.roles || []) : false;

  const faresByRouteId = useMemo(() => {
    const map = new Map<string, Fare[]>();
    for (const fare of fares) {
      const existing = map.get(fare.route_id) ?? [];
      existing.push(fare);
      map.set(fare.route_id, existing);
    }
    for (const [, routeFares] of map) {
      routeFares.sort((a, b) => a.currency.localeCompare(b.currency));
    }
    return map;
  }, [fares]);

  const filteredRoutes = useMemo(() => {
    const query = search.trim().toLowerCase();
    if (!query) return routes;

    return routes.filter((r) => {
      const routeFares = faresByRouteId.get(r.id) ?? [];
      const fields = [
        r.origin,
        r.destination,
        `${r.origin} ${r.destination}`,
        `${r.origin} -> ${r.destination}`,
        `${r.origin} → ${r.destination}`,
        ...(r.parent_route_labels ?? []),
        ...(r.child_route_labels ?? []),
        r.parent_route_label,
        ...routeFares.map((f) => f.currency),
        ...routeFares.map((f) => String(f.amount)),
        (r.parent_route_ids?.length ?? (r.parent_route_id ? 1 : 0)) > 0
          ? "linked segment"
          : (r.child_route_ids?.length ?? 0) > 0
            ? "parent route"
            : "route",
        r.is_active ? "active" : "inactive",
      ];

      return fields
        .filter(Boolean)
        .some((value) => String(value).toLowerCase().includes(query));
    });
  }, [routes, search, faresByRouteId]);

  const totalPages = Math.max(1, Math.ceil(filteredRoutes.length / DEFAULT_PAGE_SIZE));

  const paginatedRoutes = useMemo(() => {
    const start = (page - 1) * DEFAULT_PAGE_SIZE;
    return filteredRoutes.slice(start, start + DEFAULT_PAGE_SIZE);
  }, [filteredRoutes, page]);

  useEffect(() => {
    setPage(1);
  }, [search]);

  useEffect(() => {
    if (page > totalPages) setPage(totalPages);
  }, [page, totalPages]);

  const fetchData = async () => {
    setLoading(true);
    setError(null);
    try {
      const [routeData, fareData] = await Promise.all([
        routeService.getAll(),
        fareService.getAll(),
      ]);
      setRoutes(routeData);
      setFares(fareData);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load routes");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handleRouteEdit = (route: RouteInfo) => {
    navigate(`/routes/${route.id}/edit`);
  };

  const handleDeleteConfirm = async () => {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      await routeService.delete(
        deleteTarget.id,
        isSuperAdminUser ? deleteTarget.depot_id : undefined
      );
      toast({
        title: "Route deleted",
        description: `${deleteTarget.origin} → ${deleteTarget.destination} was removed.`,
      });
      setDeleteTarget(null);
      fetchData();
    } catch (err) {
      toast({
        title: "Delete failed",
        description: err instanceof Error ? err.message : "Could not delete route",
        variant: "destructive",
      });
    } finally {
      setDeleting(false);
    }
  };

  const renderFares = (routeId: string) => {
    const routeFares = faresByRouteId.get(routeId) ?? [];
    if (routeFares.length === 0) {
      return <span className="text-sm text-muted-foreground">—</span>;
    }

    if (routeFares.length === 1) {
      const fare = routeFares[0];
      return (
        <span className="font-mono text-sm font-medium tabular-nums">
          <span className="text-muted-foreground">{fare.currency}</span>{" "}
          {formatAmount(fare.amount)}
        </span>
      );
    }

    return (
      <div className="flex flex-col gap-1">
        {routeFares.map((fare) => (
          <span key={fare.id} className="font-mono text-sm font-medium tabular-nums">
            <span className="text-muted-foreground">{fare.currency}</span>{" "}
            {formatAmount(fare.amount)}
          </span>
        ))}
      </div>
    );
  };

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.3 }}>
      <AddRouteDialog
        open={routeDialogOpen}
        onOpenChange={setRouteDialogOpen}
        onSuccess={() => {
          fetchData();
          setRouteDialogOpen(false);
        }}
      />

      <ConfirmDeleteDialog
        open={!!deleteTarget}
        onOpenChange={(open) => !open && setDeleteTarget(null)}
        title="Delete route?"
        description={
          deleteTarget
            ? `This will permanently remove ${deleteTarget.origin} → ${deleteTarget.destination} and its fares. Routes with trip history cannot be deleted.`
            : ""
        }
        loading={deleting}
        onConfirm={handleDeleteConfirm}
      />

      <PageHeader title="Routes" description="Manage routes, fares, and linked segments in one place">
        {canManageRoutesPermission && (
          <Button size="sm" className="gap-2 shadow-sm" onClick={() => setRouteDialogOpen(true)}>
            <Plus className="h-4 w-4" /> Add Route
          </Button>
        )}
      </PageHeader>

      {loading ? (
        <div className="flex items-center justify-center py-12">
          <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
        </div>
      ) : (
        <>
          <ErrorAlert error={error} />
          {routes.length === 0 ? (
            <div className="text-center py-12">
              <MapPin className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
              <p className="text-muted-foreground">No routes registered yet.</p>
              {canManageRoutesPermission && (
                <Button size="sm" className="gap-2 mt-4" onClick={() => setRouteDialogOpen(true)}>
                  <Plus className="h-4 w-4" /> Add First Route
                </Button>
              )}
            </div>
          ) : (
            <>
              <div className="mb-4 flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
                <div className="relative w-full sm:max-w-md">
                  <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground pointer-events-none" />
                  <Input
                    value={search}
                    onChange={(e) => setSearch(e.target.value)}
                    placeholder="Search routes, fares, or currency…"
                    className="pl-9"
                    aria-label="Search routes"
                  />
                </div>
                <p className="text-xs text-muted-foreground sm:text-right">
                  {search.trim()
                    ? `${filteredRoutes.length} match${filteredRoutes.length === 1 ? "" : "es"} of ${routes.length}`
                    : `${routes.length} route${routes.length === 1 ? "" : "s"}`}
                </p>
              </div>

              {filteredRoutes.length === 0 ? (
                <div className="text-center py-12">
                  <Search className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
                  <p className="text-muted-foreground">No routes match “{search.trim()}”.</p>
                  <Button
                    size="sm"
                    variant="outline"
                    className="mt-4"
                    onClick={() => setSearch("")}
                  >
                    Clear search
                  </Button>
                </div>
              ) : (
                <div className="space-y-4">
                  <ResponsiveTable
                    columns={routeColumns}
                    data={paginatedRoutes}
                    keyExtractor={(r) => r.id}
                    renderRow={(r) => (
                      <TableRow key={r.id} className="group hover:bg-muted/30 transition-colors">
                        <TableCell>
                          <div className="flex items-center gap-2">
                            <div className="h-8 w-8 rounded-lg flex items-center justify-center bg-primary/10">
                              <MapPin className="h-4 w-4 text-primary" />
                            </div>
                            <span className="font-medium text-sm">{r.origin}</span>
                          </div>
                        </TableCell>
                        <TableCell>
                          <span className="font-medium text-sm flex items-center gap-1.5">
                            <ArrowRight className="h-3.5 w-3.5 text-muted-foreground" />
                            {r.destination}
                          </span>
                        </TableCell>
                        <TableCell>{renderFares(r.id)}</TableCell>
                        <TableCell>
                          {r.distance_km ? (
                            <span className="flex items-center gap-1.5 text-muted-foreground text-sm">
                              <Ruler className="h-3.5 w-3.5" />
                              {typeof r.distance_km === "number" ? r.distance_km.toFixed(1) : r.distance_km} km
                            </span>
                          ) : (
                            <span className="text-muted-foreground text-sm">—</span>
                          )}
                        </TableCell>
                        <TableCell>
                          <Badge
                            variant={r.is_active ? "default" : "outline"}
                            className={`text-xs gap-1.5 ${
                              r.is_active
                                ? "bg-green-500/10 text-green-700 border-green-500/20"
                                : "bg-gray-500/10 text-gray-700 border-gray-500/20"
                            }`}
                          >
                            <span className={`h-1.5 w-1.5 rounded-full ${r.is_active ? "bg-green-700" : "bg-gray-700"}`} />
                            {r.is_active ? "Active" : "Inactive"}
                          </Badge>
                        </TableCell>
                        <TableCell className="text-muted-foreground text-sm">{r.depot_name || "N/A"}</TableCell>
                        <TableCell className="text-right">
                          {canManageRoutesPermission && (
                            <div className="flex justify-end gap-1">
                              <Button variant="ghost" size="sm" onClick={() => handleRouteEdit(r)}>
                                Edit
                              </Button>
                              <Button
                                variant="ghost"
                                size="sm"
                                className="text-destructive hover:text-destructive hover:bg-destructive/10"
                                onClick={() => setDeleteTarget(r)}
                              >
                                <Trash2 className="h-3.5 w-3.5" />
                              </Button>
                            </div>
                          )}
                        </TableCell>
                      </TableRow>
                    )}
                    renderCard={(r) => {
                      const routeFares = faresByRouteId.get(r.id) ?? [];
                      return (
                        <div className="space-y-3">
                          <div className="flex items-center justify-between">
                            <div className="flex items-center gap-2.5">
                              <div className="h-9 w-9 rounded-lg flex items-center justify-center bg-primary/10">
                                <MapPin className="h-4 w-4 text-primary" />
                              </div>
                              <div>
                                <p className="font-medium text-sm flex items-center gap-1.5">
                                  {r.origin} <ArrowRight className="h-3.5 w-3.5 text-muted-foreground" /> {r.destination}
                                </p>
                                <p className="text-xs text-muted-foreground">{r.depot_name || "N/A"}</p>
                              </div>
                            </div>
                            <Badge
                              variant={r.is_active ? "default" : "outline"}
                              className={`text-xs gap-1.5 ${
                                r.is_active
                                  ? "bg-green-500/10 text-green-700 border-green-500/20"
                                  : "bg-gray-500/10 text-gray-700 border-gray-500/20"
                              }`}
                            >
                              <span className={`h-1.5 w-1.5 rounded-full ${r.is_active ? "bg-green-700" : "bg-gray-700"}`} />
                              {r.is_active ? "Active" : "Inactive"}
                            </Badge>
                          </div>

                          <div className="text-sm">
                            <p className="text-muted-foreground text-xs">Fare</p>
                            <div className="mt-1">{renderFares(r.id)}</div>
                          </div>

                          {r.distance_km && (
                            <div className="text-sm">
                              <span className="text-muted-foreground text-xs">Distance</span>
                              <p className="flex items-center gap-1.5 text-muted-foreground">
                                <Ruler className="h-3 w-3" />
                                {typeof r.distance_km === "number" ? r.distance_km.toFixed(1) : r.distance_km} km
                              </p>
                            </div>
                          )}

                          {routeFares.length === 0 && (
                            <p className="text-xs text-amber-700 bg-amber-500/10 border border-amber-500/20 rounded-md px-2 py-1.5">
                              No fare set — edit this route to add pricing.
                            </p>
                          )}

                          {canManageRoutesPermission && (
                            <div className="flex justify-end gap-1 pt-2 border-t border-border/40">
                              <Button variant="ghost" size="sm" onClick={() => handleRouteEdit(r)}>
                                Edit
                              </Button>
                              <Button
                                variant="ghost"
                                size="sm"
                                className="text-destructive"
                                onClick={() => setDeleteTarget(r)}
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
                    total={filteredRoutes.length}
                    totalPages={totalPages}
                    onPageChange={setPage}
                  />
                </div>
              )}
            </>
          )}
        </>
      )}
    </motion.div>
  );
};

export default RoutesPage;

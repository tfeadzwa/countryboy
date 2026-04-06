import { useState, useEffect } from "react";
import { motion } from "framer-motion";
import PageHeader from "@/components/PageHeader";
import { routeService } from "@/lib/api/route.service";
import { fareService } from "@/lib/api/fare.service";
import { TableCell, TableRow } from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { Plus, ArrowRight, Loader2, DollarSign, MapPin, Ruler } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { ResponsiveTable } from "@/components/ResponsiveTable";
import AddRouteDialog from "@/components/AddRouteDialog";
import AddFareDialog from "@/components/AddFareDialog";
import ErrorAlert from "@/components/ErrorAlert";
import { canManageRoutes, canManageFares } from "@/lib/permissions";
import { useAuth } from "@/contexts/AuthContext";
import type { RouteInfo, Fare } from "@/types";

const routeColumns = [
  { header: "Departure" },
  { header: "Destination" },
  { header: "Distance" },
  { header: "Status" },
  { header: "Depot" },
  { header: "Actions", className: "text-right" },
];

const fareColumns = [
  { header: "Route" },
  { header: "Depot" },
  { header: "Currency" },
  { header: "Amount" },
  { header: "Actions", className: "text-right" },
];

const RoutesPage = () => {
  const { user } = useAuth();
  const [routes, setRoutes] = useState<RouteInfo[]>([]);
  const [fares, setFares] = useState<Fare[]>([]);
  const [loadingRoutes, setLoadingRoutes] = useState(true);
  const [loadingFares, setLoadingFares] = useState(true);
  const [routeError, setRouteError] = useState<string | null>(null);
  const [fareError, setFareError] = useState<string | null>(null);
  const [routeDialogOpen, setRouteDialogOpen] = useState(false);
  const [fareDialogOpen, setFareDialogOpen] = useState(false);
  const [editingRoute, setEditingRoute] = useState<RouteInfo | null>(null);
  const [editingFare, setEditingFare] = useState<Fare | null>(null);

  const canManageRoutesPermission = user ? canManageRoutes(user.roles || []) : false;
  const canManageFaresPermission = user ? canManageFares(user.roles || []) : false;

  const fetchRoutes = async () => {
    setLoadingRoutes(true);
    setRouteError(null);
    try {
      const data = await routeService.getAll();
      setRoutes(data);
    } catch (err) {
      setRouteError(err instanceof Error ? err.message : 'Failed to load routes');
    } finally {
      setLoadingRoutes(false);
    }
  };

  const fetchFares = async () => {
    setLoadingFares(true);
    setFareError(null);
    try {
      const data = await fareService.getAll();
      setFares(data);
    } catch (err) {
      setFareError(err instanceof Error ? err.message : 'Failed to load fares');
    } finally {
      setLoadingFares(false);
    }
  };

  useEffect(() => {
    fetchRoutes();
  }, []);

  useEffect(() => {
    fetchFares();
  }, []);

  const handleRouteEdit = (route: RouteInfo) => {
    setEditingRoute(route);
    setRouteDialogOpen(true);
  };

  const handleFareEdit = (fare: Fare) => {
    setEditingFare(fare);
    setFareDialogOpen(true);
  };

  const handleRouteDialogClose = () => {
    setRouteDialogOpen(false);
    setEditingRoute(null);
  };

  const handleFareDialogClose = () => {
    setFareDialogOpen(false);
    setEditingFare(null);
  };

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.3 }}>
      <AddRouteDialog
        open={routeDialogOpen}
        onOpenChange={setRouteDialogOpen}
        onSuccess={() => {
          fetchRoutes();
          handleRouteDialogClose();
        }}
        route={editingRoute}
      />

      <AddFareDialog
        open={fareDialogOpen}
        onOpenChange={setFareDialogOpen}
        onSuccess={() => {
          fetchFares();
          handleFareDialogClose();
        }}
        fare={editingFare}
      />

      <PageHeader title="Routes & Fares" description="Manage travel routes and fare schedules">
        {canManageRoutesPermission && (
          <Button size="sm" className="gap-2 shadow-sm" onClick={() => setRouteDialogOpen(true)}>
            <Plus className="h-4 w-4" /> Add Route
          </Button>
        )}
      </PageHeader>

      <Tabs defaultValue="routes" className="space-y-4">
        <TabsList className="bg-muted/50">
          <TabsTrigger value="routes">Routes</TabsTrigger>
          <TabsTrigger value="fares">Fares</TabsTrigger>
        </TabsList>

        <TabsContent value="routes">
          {loadingRoutes ? (
            <div className="flex items-center justify-center py-12">
              <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
            </div>
          ) : (
            <>
              <ErrorAlert error={routeError} />
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
                <ResponsiveTable
                  columns={routeColumns}
                  data={routes}
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
                      <TableCell>
                        {r.distance_km ? (
                          <span className="flex items-center gap-1.5 text-muted-foreground text-sm">
                            <Ruler className="h-3.5 w-3.5" />
                            {typeof r.distance_km === 'number' ? r.distance_km.toFixed(1) : r.distance_km} km
                          </span>
                        ) : (
                          <span className="text-muted-foreground text-sm">—</span>
                        )}
                      </TableCell>
                      <TableCell>
                        <Badge 
                          variant={r.is_active ? 'default' : 'outline'}
                          className={`text-xs gap-1.5 ${
                            r.is_active 
                              ? 'bg-green-500/10 text-green-700 border-green-500/20' 
                              : 'bg-gray-500/10 text-gray-700 border-gray-500/20'
                          }`}
                        >
                          <span className={`h-1.5 w-1.5 rounded-full ${r.is_active ? 'bg-green-700' : 'bg-gray-700'}`} />
                          {r.is_active ? 'Active' : 'Inactive'}
                        </Badge>
                      </TableCell>
                      <TableCell className="text-muted-foreground text-sm">{r.depot_name || 'N/A'}</TableCell>
                      <TableCell className="text-right">
                        {canManageRoutesPermission && (
                          <Button variant="ghost" size="sm" onClick={() => handleRouteEdit(r)}>
                            Edit
                          </Button>
                        )}
                      </TableCell>
                    </TableRow>
                  )}
                  renderCard={(r) => (
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
                            <p className="text-xs text-muted-foreground">{r.depot_name || 'N/A'}</p>
                          </div>
                        </div>
                        <Badge 
                          variant={r.is_active ? 'default' : 'outline'}
                          className={`text-xs gap-1.5 ${
                            r.is_active 
                              ? 'bg-green-500/10 text-green-700 border-green-500/20' 
                              : 'bg-gray-500/10 text-gray-700 border-gray-500/20'
                          }`}
                        >
                          <span className={`h-1.5 w-1.5 rounded-full ${r.is_active ? 'bg-green-700' : 'bg-gray-700'}`} />
                          {r.is_active ? 'Active' : 'Inactive'}
                        </Badge>
                      </div>
                      {r.distance_km && (
                        <div className="text-sm">
                          <span className="text-muted-foreground text-xs">Distance</span>
                          <p className="flex items-center gap-1.5 text-muted-foreground">
                            <Ruler className="h-3 w-3" />
                            {typeof r.distance_km === 'number' ? r.distance_km.toFixed(1) : r.distance_km} km
                          </p>
                        </div>
                      )}
                      {canManageRoutesPermission && (
                        <div className="flex justify-end pt-2 border-t border-border/40">
                          <Button variant="ghost" size="sm" onClick={() => handleRouteEdit(r)}>
                            Edit
                          </Button>
                        </div>
                      )}
                    </div>
                  )}
                />
              )}
            </>
          )}
        </TabsContent>

        <TabsContent value="fares">
          {canManageFaresPermission && (
            <div className="flex justify-end mb-4">
              <Button size="sm" variant="outline" className="gap-2 shadow-sm" onClick={() => setFareDialogOpen(true)}>
                <Plus className="h-4 w-4" /> Add Fare
              </Button>
            </div>
          )}

          {loadingFares ? (
            <div className="flex items-center justify-center py-12">
              <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
            </div>
          ) : (
            <>
              <ErrorAlert error={fareError} />
              {fares.length === 0 ? (
                <div className="text-center py-12">
                  <DollarSign className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
                  <p className="text-muted-foreground">No fares configured yet.</p>
                  {canManageFaresPermission && (
                    <Button size="sm" className="gap-2 mt-4" onClick={() => setFareDialogOpen(true)}>
                      <Plus className="h-4 w-4" /> Add First Fare
                    </Button>
                  )}
                </div>
              ) : (
                <ResponsiveTable
                  columns={fareColumns}
                  data={fares}
                  keyExtractor={(f) => f.id}
                  renderRow={(f) => (
                    <TableRow key={f.id} className="hover:bg-muted/30 transition-colors">
                      <TableCell>
                        <div className="flex items-center gap-2">
                          <div className="h-8 w-8 rounded-lg flex items-center justify-center bg-primary/10">
                            <DollarSign className="h-4 w-4 text-primary" />
                          </div>
                          <span className="font-medium text-sm">{f.route_label}</span>
                        </div>
                      </TableCell>
                      <TableCell className="text-muted-foreground text-sm">{f.depot_name || 'N/A'}</TableCell>
                      <TableCell>
                        <Badge variant="outline" className="text-xs font-mono">
                          {f.currency}
                        </Badge>
                      </TableCell>
                      <TableCell className="font-mono font-semibold text-sm">
                        {typeof f.amount === 'number' ? f.amount.toFixed(2) : f.amount}
                      </TableCell>
                      <TableCell className="text-right">
                        {canManageFaresPermission && (
                          <Button variant="ghost" size="sm" onClick={() => handleFareEdit(f)}>
                            Edit
                          </Button>
                        )}
                      </TableCell>
                    </TableRow>
                  )}
                  renderCard={(f) => (
                    <div className="space-y-3">
                      <div className="flex items-center gap-2.5">
                        <div className="h-9 w-9 rounded-lg flex items-center justify-center bg-primary/10">
                          <DollarSign className="h-4 w-4 text-primary" />
                        </div>
                        <div className="flex-1">
                          <p className="font-medium text-sm">{f.route_label}</p>
                          <p className="text-xs text-muted-foreground">{f.depot_name || 'N/A'}</p>
                        </div>
                      </div>
                      <div className="grid grid-cols-2 gap-2 text-sm">
                        <div>
                          <p className="text-muted-foreground text-xs">Currency</p>
                          <p className="font-medium">
                            <Badge variant="outline" className="text-xs font-mono">
                              {f.currency}
                            </Badge>
                          </p>
                        </div>
                        <div>
                          <p className="text-muted-foreground text-xs">Amount</p>
                          <p className="font-mono font-semibold">
                            {typeof f.amount === 'number' ? f.amount.toFixed(2) : f.amount}
                          </p>
                        </div>
                      </div>
                      {canManageFaresPermission && (
                        <div className="flex justify-end pt-2 border-t border-border/40">
                          <Button variant="ghost" size="sm" onClick={() => handleFareEdit(f)}>
                            Edit
                          </Button>
                        </div>
                      )}
                    </div>
                  )}
                />
              )}
            </>
          )}
        </TabsContent>
      </Tabs>
    </motion.div>
  );
};

export default RoutesPage;

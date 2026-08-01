import { useState, useEffect, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import PageHeader from "@/components/PageHeader";
import TripBatchPrintDialog from "@/components/TripBatchPrintDialog";
import { tripService } from "@/lib/api/trip.service";
import { TableCell, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Input } from "@/components/ui/input";
import { Card, CardContent } from "@/components/ui/card";
import { ResponsiveTable } from "@/components/ResponsiveTable";
import TablePagination from "@/components/TablePagination";
import {
  ArrowRight,
  Clock,
  Filter,
  Loader2,
  Printer,
  Route,
  Square,
} from "lucide-react";
import ErrorAlert from "@/components/ErrorAlert";
import EndTripConfirmDialog from "@/components/EndTripConfirmDialog";
import { useAuth } from "@/contexts/AuthContext";
import { canEndTrips, canPrintTicketBatches, isSuperAdmin } from "@/lib/permissions";
import { useToast } from "@/hooks/use-toast";
import { DEFAULT_PAGE_SIZE } from "@/types/pagination";
import { sortTrips } from "@/lib/trip-sort";
import type { Trip } from "@/types";

const statusConfig: Record<string, { class: string; dot: string; label: string }> = {
  ACTIVE: { class: "bg-success/10 text-success border border-success/20", dot: "bg-success", label: "Active" },
  ENDED: { class: "bg-muted text-muted-foreground", dot: "bg-muted-foreground", label: "Ended" },
  COMPLETED: { class: "bg-muted text-muted-foreground", dot: "bg-muted-foreground", label: "Ended" },
  CANCELLED: { class: "bg-destructive/10 text-destructive border border-destructive/20", dot: "bg-destructive", label: "Cancelled" },
};

const isConductorOnline = (trip: Pick<Trip, "conductor_is_online" | "conductor_presence">) =>
  Boolean(trip.conductor_is_online) || trip.conductor_presence === "online";

const columns = [
  { header: "Fleet" },
  { header: "Conductor" },
  { header: "Corridor" },
  { header: "Started" },
  { header: "Tickets" },
  { header: "Revenue" },
  { header: "Status" },
  { header: "Actions", className: "text-right" },
];

const Trips = () => {
  const { user } = useAuth();
  const { toast } = useToast();
  const navigate = useNavigate();
  const userRoles = user?.roles || [];
  const canEnd = canEndTrips(userRoles);
  const canPrint = canPrintTicketBatches(userRoles);
  const canForceEnd = isSuperAdmin(userRoles);

  const [trips, setTrips] = useState<Trip[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [endingId, setEndingId] = useState<string | null>(null);
  const [endConfirmTrip, setEndConfirmTrip] = useState<Trip | null>(null);
  const [printTrip, setPrintTrip] = useState<Trip | null>(null);

  const [statusFilter, setStatusFilter] = useState("all");
  const [agentFilter, setAgentFilter] = useState("all");
  const [fleetFilter, setFleetFilter] = useState("all");
  const [dateFromFilter, setDateFromFilter] = useState("");
  const [dateToFilter, setDateToFilter] = useState("");
  const [page, setPage] = useState(1);

  useEffect(() => {
    void loadTrips();
  }, [statusFilter, agentFilter, fleetFilter, dateFromFilter, dateToFilter]);

  useEffect(() => {
    setPage(1);
  }, [statusFilter, agentFilter, fleetFilter, dateFromFilter, dateToFilter]);

  const loadTrips = async () => {
    setLoading(true);
    setError(null);
    try {
      const filters: Record<string, string> = {};
      if (statusFilter !== "all") filters.status = statusFilter;
      if (agentFilter !== "all") filters.agent_id = agentFilter;
      if (fleetFilter !== "all") filters.fleet_id = fleetFilter;
      if (dateFromFilter) filters.date_from = dateFromFilter;
      if (dateToFilter) filters.date_to = dateToFilter;

      const data = await tripService.getAll(filters);
      setTrips(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load trips");
    } finally {
      setLoading(false);
    }
  };

  const handleEndTrip = async (closingMileage: number) => {
    const trip = endConfirmTrip;
    if (!canEnd || !trip || trip.status !== "ACTIVE") return;

    const online = isConductorOnline(trip);
    if (!online && !canForceEnd) return;

    setEndingId(trip.id);
    try {
      await tripService.end(trip.id, trip.depot_id, {
        force: !online && canForceEnd,
        closingMileage,
      });
      setEndConfirmTrip(null);
      toast({
        title: "Trip ended",
        description: `${trip.fleet_number || "Trip"} closed successfully.`,
      });
      await loadTrips();
    } catch (err) {
      toast({
        title: "Could not end trip",
        description: err instanceof Error ? err.message : "Try again",
        variant: "destructive",
      });
    } finally {
      setEndingId(null);
    }
  };

  const uniqueAgents = Array.from(
    new Map(trips.map((t) => [t.agent_id, { id: t.agent_id, name: t.agent_name || "Unknown" }])).values(),
  );
  const uniqueFleets = Array.from(
    new Map(trips.map((t) => [t.fleet_id, { id: t.fleet_id, number: t.fleet_number || "Unknown" }])).values(),
  );

  const totalRevenue = trips.reduce((sum, t) => sum + (t.total_revenue || 0), 0);
  const totalTickets = trips.reduce((sum, t) => sum + (t.ticket_count || 0), 0);
  const activeCount = trips.filter((t) => t.status === "ACTIVE").length;

  const sortedTrips = useMemo(() => sortTrips(trips), [trips]);

  const totalPages = Math.max(1, Math.ceil(sortedTrips.length / DEFAULT_PAGE_SIZE));

  const paginated = useMemo(() => {
    const start = (page - 1) * DEFAULT_PAGE_SIZE;
    return sortedTrips.slice(start, start + DEFAULT_PAGE_SIZE);
  }, [sortedTrips, page]);

  const renderStatus = (status: string) => {
    const config = statusConfig[status] || statusConfig.ENDED;
    return (
      <Badge className={`text-xs gap-1.5 ${config.class}`}>
        <span className={`h-1.5 w-1.5 rounded-full ${config.dot}`} />
        {config.label}
      </Badge>
    );
  };

  const renderActions = (t: Trip) => (
    <div className="flex flex-wrap justify-end gap-1">
      {canPrint && (
        <Button
          variant="ghost"
          size="sm"
          className="gap-1.5"
          onClick={(e) => {
            e.stopPropagation();
            setPrintTrip(t);
          }}
        >
          <Printer className="h-3.5 w-3.5" />
          <span className="hidden sm:inline">Print</span>
        </Button>
      )}
      {canEnd && t.status === "ACTIVE" && (
        <Button
          variant="outline"
          size="sm"
          className="gap-1.5 border-destructive/30 text-destructive hover:bg-destructive/10 hover:text-destructive disabled:opacity-60"
          disabled={
            endingId === t.id || (!isConductorOnline(t) && !canForceEnd)
          }
          title={
            !isConductorOnline(t) && !canForceEnd
              ? "Conductor must be online to end this trip"
              : !isConductorOnline(t) && canForceEnd
                ? "Conductor offline — force end available"
                : undefined
          }
          onClick={(e) => {
            e.stopPropagation();
            setEndConfirmTrip(t);
          }}
        >
          {endingId === t.id ? (
            <Loader2 className="h-3.5 w-3.5 animate-spin" />
          ) : (
            <Square className="h-3.5 w-3.5" />
          )}
          End
        </Button>
      )}
    </div>
  );

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.3 }}>
      <PageHeader
        title="Trips"
        description={
          canEnd
            ? "Close active trips and print ticket batches for your depot"
            : "View trips and their revenue totals"
        }
      />

      {error && <ErrorAlert error={error} />}

      <TripBatchPrintDialog
        open={!!printTrip}
        onOpenChange={(open) => {
          if (!open) setPrintTrip(null);
        }}
        trip={printTrip}
      />

      <EndTripConfirmDialog
        open={!!endConfirmTrip}
        onOpenChange={(open) => {
          if (!open && !endingId) setEndConfirmTrip(null);
        }}
        loading={!!endingId}
        forceMode={
          !!endConfirmTrip && !isConductorOnline(endConfirmTrip) && canForceEnd
        }
        canConfirm={
          !!endConfirmTrip &&
          (isConductorOnline(endConfirmTrip) || canForceEnd)
        }
        onConfirm={(closingMileage) => void handleEndTrip(closingMileage)}
        trip={
          endConfirmTrip
            ? {
                fleet_number: endConfirmTrip.fleet_number,
                origin: endConfirmTrip.origin,
                destination: endConfirmTrip.destination,
                route_label: endConfirmTrip.route_label,
                agent_name: endConfirmTrip.agent_name,
                ticket_count: endConfirmTrip.ticket_count ?? 0,
                revenue_label:
                  endConfirmTrip.total_revenue != null
                    ? `USD ${Number(endConfirmTrip.total_revenue).toFixed(2)}`
                    : null,
                conductor_presence: endConfirmTrip.conductor_presence,
                conductor_is_online: endConfirmTrip.conductor_is_online,
                starting_mileage: endConfirmTrip.starting_mileage,
                waybill_no: endConfirmTrip.waybill_no,
              }
            : null
        }
      />

      {loading ? (
        <div className="flex items-center justify-center py-12">
          <Loader2 className="h-8 w-8 animate-spin text-primary" />
        </div>
      ) : (
        <>
          <motion.div
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.3, delay: 0.1 }}
          >
            <Card className="shadow-sm border-border/60 mb-6">
              <CardContent className="p-4">
                <div className="flex items-center gap-2 mb-3">
                  <Filter className="h-4 w-4 text-muted-foreground" />
                  <span className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">
                    Filters
                  </span>
                </div>
                <div className="grid grid-cols-2 sm:flex sm:flex-wrap items-center gap-2 sm:gap-3">
                  <div className="flex gap-2 w-full sm:w-auto">
                    <Input
                      type="date"
                      value={dateFromFilter}
                      onChange={(e) => setDateFromFilter(e.target.value)}
                      className="w-full sm:w-40"
                    />
                    <Input
                      type="date"
                      value={dateToFilter}
                      onChange={(e) => setDateToFilter(e.target.value)}
                      className="w-full sm:w-40"
                    />
                  </div>
                  <Select value={statusFilter} onValueChange={setStatusFilter}>
                    <SelectTrigger className="w-full sm:w-40">
                      <SelectValue placeholder="All Status" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All Status</SelectItem>
                      <SelectItem value="ACTIVE">Active</SelectItem>
                      <SelectItem value="ENDED">Ended</SelectItem>
                      <SelectItem value="CANCELLED">Cancelled</SelectItem>
                    </SelectContent>
                  </Select>
                  <Select value={agentFilter} onValueChange={setAgentFilter}>
                    <SelectTrigger className="w-full sm:w-44">
                      <SelectValue placeholder="All Conductors" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All Conductors</SelectItem>
                      {uniqueAgents.map((a) => (
                        <SelectItem key={a.id} value={a.id}>
                          {a.name}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  <Select value={fleetFilter} onValueChange={setFleetFilter}>
                    <SelectTrigger className="w-full sm:w-40">
                      <SelectValue placeholder="All Fleets" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All Fleets</SelectItem>
                      {uniqueFleets.map((f) => (
                        <SelectItem key={f.id} value={f.id}>
                          {f.number}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </CardContent>
            </Card>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.3, delay: 0.15 }}
            className="flex flex-wrap gap-2 sm:gap-3 mb-6"
          >
            {canEnd && (
              <Badge className="text-sm px-3 py-1.5 bg-success/10 text-success border border-success/20">
                {activeCount} active
              </Badge>
            )}
            <Badge variant="secondary" className="text-sm px-3 py-1.5 font-mono shadow-sm">
              Revenue: ${totalRevenue.toFixed(2)}
            </Badge>
            <Badge variant="secondary" className="text-sm px-3 py-1.5 shadow-sm">
              Tickets: {totalTickets}
            </Badge>
            <Badge variant="outline" className="text-sm px-3 py-1.5">
              {trips.length} trips
            </Badge>
          </motion.div>

          {trips.length === 0 ? (
            <div className="text-center py-12">
              <Route className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
              <p className="text-muted-foreground">No trips found.</p>
            </div>
          ) : (
            <div className="space-y-4">
              <ResponsiveTable
                columns={columns}
                data={paginated}
                keyExtractor={(t) => t.id}
                renderRow={(t) => (
                  <TableRow
                    key={t.id}
                    className="cursor-pointer hover:bg-muted/30 transition-colors"
                    onClick={() => navigate(`/trips/${t.id}`)}
                  >
                    <TableCell className="font-mono font-medium">{t.fleet_number || "—"}</TableCell>
                    <TableCell className="text-sm">{t.agent_name || "—"}</TableCell>
                    <TableCell className="text-sm text-muted-foreground max-w-[180px] truncate">
                      {t.route_label || "—"}
                    </TableCell>
                    <TableCell className="text-sm">
                      <span className="flex items-center gap-1.5 text-muted-foreground">
                        <Clock className="h-3.5 w-3.5" />
                        {new Date(t.started_at).toLocaleString()}
                      </span>
                    </TableCell>
                    <TableCell>
                      <span className="font-display font-semibold">{t.ticket_count ?? 0}</span>
                    </TableCell>
                    <TableCell>
                      <span className="font-mono font-semibold">
                        ${(t.total_revenue ?? 0).toFixed(2)}
                      </span>
                    </TableCell>
                    <TableCell>{renderStatus(t.status)}</TableCell>
                    <TableCell className="text-right" onClick={(e) => e.stopPropagation()}>
                      {renderActions(t)}
                    </TableCell>
                  </TableRow>
                )}
                renderCard={(t) => (
                  <div
                    className="space-y-3 cursor-pointer"
                    onClick={() => navigate(`/trips/${t.id}`)}
                  >
                    <div className="flex items-center justify-between gap-2">
                      <div>
                        <p className="font-mono font-medium text-sm">{t.fleet_number || "—"}</p>
                        <p className="text-xs text-muted-foreground">{t.agent_name || "—"}</p>
                      </div>
                      {renderStatus(t.status)}
                    </div>
                    <p className="text-sm font-medium">{t.route_label || "Corridor"}</p>
                    <div className="grid grid-cols-2 gap-2 text-sm">
                      <div>
                        <p className="text-muted-foreground text-xs">Tickets</p>
                        <p className="font-display font-semibold">{t.ticket_count ?? 0}</p>
                      </div>
                      <div>
                        <p className="text-muted-foreground text-xs">Revenue</p>
                        <p className="font-mono font-semibold">${(t.total_revenue ?? 0).toFixed(2)}</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2 text-xs text-muted-foreground border-t border-border/40 pt-2">
                      <Clock className="h-3 w-3" />
                      {new Date(t.started_at).toLocaleString()}
                      <ArrowRight className="h-3 w-3" />
                      {t.ended_at ? new Date(t.ended_at).toLocaleString() : "Ongoing"}
                    </div>
                    {(canEnd || canPrint) && (
                      <div
                        className="flex justify-end gap-2 border-t border-border/40 pt-2"
                        onClick={(e) => e.stopPropagation()}
                      >
                        {renderActions(t)}
                      </div>
                    )}
                  </div>
                )}
              />

              <TablePagination
                page={page}
                pageSize={DEFAULT_PAGE_SIZE}
                total={trips.length}
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

export default Trips;

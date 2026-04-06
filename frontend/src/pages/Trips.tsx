import { useState, useEffect } from "react";
import { motion } from "framer-motion";
import PageHeader from "@/components/PageHeader";
import { tripService } from "@/lib/api/trip.service";
import { TableCell, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Input } from "@/components/ui/input";
import { Card, CardContent } from "@/components/ui/card";
import { ResponsiveTable } from "@/components/ResponsiveTable";
import { ArrowRight, Clock, Filter, Loader2, Route } from "lucide-react";
import ErrorAlert from "@/components/ErrorAlert";
import type { Trip } from "@/types";

const statusConfig: Record<string, { class: string; dot: string }> = {
  ACTIVE: { class: "bg-success/10 text-success border border-success/20", dot: "bg-success" },
  ENDED: { class: "bg-muted text-muted-foreground", dot: "bg-muted-foreground" },
  CANCELLED: { class: "bg-destructive/10 text-destructive border border-destructive/20", dot: "bg-destructive" },
};

const columns = [
  { header: "Fleet" },
  { header: "Agent" },
  { header: "Depot" },
  { header: "Started" },
  { header: "Ended" },
  { header: "Tickets" },
  { header: "Revenue" },
  { header: "Status" },
];

const Trips = () => {
  const [trips, setTrips] = useState<Trip[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  const [statusFilter, setStatusFilter] = useState("all");
  const [agentFilter, setAgentFilter] = useState("all");
  const [fleetFilter, setFleetFilter] = useState("all");
  const [dateFromFilter, setDateFromFilter] = useState("");
  const [dateToFilter, setDateToFilter] = useState("");

  useEffect(() => {
    loadTrips();
  }, [statusFilter, agentFilter, fleetFilter, dateFromFilter, dateToFilter]);

  const loadTrips = async () => {
    setLoading(true);
    setError(null);
    try {
      const filters: any = {};
      if (statusFilter !== "all") filters.status = statusFilter;
      if (agentFilter !== "all") filters.agent_id = agentFilter;
      if (fleetFilter !== "all") filters.fleet_id = fleetFilter;
      if (dateFromFilter) filters.date_from = dateFromFilter;
      if (dateToFilter) filters.date_to = dateToFilter;

      const data = await tripService.getAll(filters);
      setTrips(data);
    } catch (err) {
      console.error('Failed to load trips:', err);
      setError(err instanceof Error ? err.message : 'Failed to load trips');
    } finally {
      setLoading(false);
    }
  };

  // Get unique agents and fleets for filters
  const uniqueAgents = Array.from(
    new Map(trips.map(t => [t.agent_id, { id: t.agent_id, name: t.agent_name || 'Unknown' }])).values()
  );
  const uniqueFleets = Array.from(
    new Map(trips.map(t => [t.fleet_id, { id: t.fleet_id, number: t.fleet_number || 'Unknown' }])).values()
  );

  // Calculate totals
  const totalRevenue = trips.reduce((sum, t) => sum + (t.total_revenue || 0), 0);
  const totalTickets = trips.reduce((sum, t) => sum + (t.ticket_count || 0), 0);

  const renderStatus = (status: string) => {
    const config = statusConfig[status] || statusConfig.ENDED;
    return (
      <Badge className={`text-xs gap-1.5 ${config.class}`}>
        <span className={`h-1.5 w-1.5 rounded-full ${config.dot}`} />
        {status}
      </Badge>
    );
  };

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.3 }}>
      <PageHeader title="Trips" description="View all trips and their revenue totals" />

      {error && <ErrorAlert error={error} />}

      {loading ? (
        <div className="flex items-center justify-center py-12">
          <Loader2 className="h-8 w-8 animate-spin text-primary" />
        </div>
      ) : (
        <>
          {/* Filters */}
          <motion.div
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.3, delay: 0.1 }}
          >
            <Card className="shadow-sm border-border/60 mb-6">
              <CardContent className="p-4">
                <div className="flex items-center gap-2 mb-3">
                  <Filter className="h-4 w-4 text-muted-foreground" />
                  <span className="text-xs font-semibold text-muted-foreground uppercase tracking-wider">Filters</span>
                </div>
                <div className="grid grid-cols-2 sm:flex sm:flex-wrap items-center gap-2 sm:gap-3">
                  <div className="flex gap-2 w-full sm:w-auto">
                    <Input 
                      type="date" 
                      value={dateFromFilter} 
                      onChange={(e) => setDateFromFilter(e.target.value)} 
                      placeholder="From date"
                      className="w-full sm:w-40" 
                    />
                    <Input 
                      type="date" 
                      value={dateToFilter} 
                      onChange={(e) => setDateToFilter(e.target.value)} 
                      placeholder="To date"
                      className="w-full sm:w-40" 
                    />
                  </div>
                  <Select value={statusFilter} onValueChange={setStatusFilter}>
                    <SelectTrigger className="w-full sm:w-40"><SelectValue placeholder="All Status" /></SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All Status</SelectItem>
                      <SelectItem value="ACTIVE">Active</SelectItem>
                      <SelectItem value="ENDED">Ended</SelectItem>
                      <SelectItem value="CANCELLED">Cancelled</SelectItem>
                    </SelectContent>
                  </Select>
                  <Select value={agentFilter} onValueChange={setAgentFilter}>
                    <SelectTrigger className="w-full sm:w-44"><SelectValue placeholder="All Agents" /></SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All Agents</SelectItem>
                      {uniqueAgents.map((a) => <SelectItem key={a.id} value={a.id}>{a.name}</SelectItem>)}
                    </SelectContent>
                  </Select>
                  <Select value={fleetFilter} onValueChange={setFleetFilter}>
                    <SelectTrigger className="w-full sm:w-40"><SelectValue placeholder="All Fleets" /></SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All Fleets</SelectItem>
                      {uniqueFleets.map((f) => <SelectItem key={f.id} value={f.id}>{f.number}</SelectItem>)}
                    </SelectContent>
                  </Select>
                </div>
              </CardContent>
            </Card>
          </motion.div>

          {/* Summary Stats */}
          <motion.div
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.3, delay: 0.15 }}
            className="flex flex-wrap gap-2 sm:gap-3 mb-6"
          >
            <Badge variant="secondary" className="text-sm px-3 py-1.5 font-mono shadow-sm">
              Total Revenue: ${totalRevenue.toFixed(2)}
            </Badge>
            <Badge variant="secondary" className="text-sm px-3 py-1.5 shadow-sm">
              Total Tickets: {totalTickets}
            </Badge>
            <Badge variant="outline" className="text-sm px-3 py-1.5">{trips.length} trips</Badge>
          </motion.div>

          {trips.length === 0 ? (
            <div className="text-center py-12">
              <Route className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
              <p className="text-muted-foreground">No trips found.</p>
            </div>
          ) : (
            <ResponsiveTable
              columns={columns}
              data={trips}
              keyExtractor={(t) => t.id}
              renderRow={(t) => (
                <TableRow key={t.id} className="hover:bg-muted/30 transition-colors">
                  <TableCell className="font-mono font-medium">{t.fleet_number || "—"}</TableCell>
                  <TableCell className="text-sm">{t.agent_name || "—"}</TableCell>
                  <TableCell className="text-muted-foreground text-sm">{t.depot_name || "—"}</TableCell>
                  <TableCell className="text-sm">
                    <span className="flex items-center gap-1.5 text-muted-foreground">
                      <Clock className="h-3.5 w-3.5" />{new Date(t.started_at).toLocaleString()}
                    </span>
                  </TableCell>
                  <TableCell className="text-sm text-muted-foreground">{t.ended_at ? new Date(t.ended_at).toLocaleString() : "—"}</TableCell>
                  <TableCell>
                    <span className="font-display font-semibold">{t.ticket_count ?? 0}</span>
                  </TableCell>
                  <TableCell>
                    <span className="font-mono font-semibold text-foreground">${(t.total_revenue ?? 0).toFixed(2)}</span>
                  </TableCell>
                  <TableCell>{renderStatus(t.status)}</TableCell>
                </TableRow>
              )}
              renderCard={(t) => (
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <div>
                      <p className="font-mono font-medium text-sm">{t.fleet_number || "—"}</p>
                      <p className="text-xs text-muted-foreground">{t.agent_name || "—"}</p>
                    </div>
                    {renderStatus(t.status)}
                  </div>
                  <div className="grid grid-cols-3 gap-2 text-sm">
                    <div>
                      <p className="text-muted-foreground text-xs">Depot</p>
                      <p className="font-medium">{t.depot_name || "—"}</p>
                    </div>
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
                </div>
              )}
            />
          )}
        </>
      )}
    </motion.div>
  );
};

export default Trips;

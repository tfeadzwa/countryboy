import { useState, useEffect } from "react";
import { motion } from "framer-motion";
import PageHeader from "@/components/PageHeader";
import { ticketService } from "@/lib/api/ticket.service";
import { TableCell, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Input } from "@/components/ui/input";
import { ResponsiveTable } from "@/components/ResponsiveTable";
import { Card, CardContent } from "@/components/ui/card";
import { Filter, ArrowRight, Loader2, Receipt } from "lucide-react";
import ErrorAlert from "@/components/ErrorAlert";
import type { Ticket } from "@/types";

const columns = [
  { header: "Serial" },
  { header: "Category" },
  { header: "Route" },
  { header: "Agent" },
  { header: "Fleet" },
  { header: "Currency" },
  { header: "Amount" },
  { header: "Issued At" },
  { header: "Status" },
];

const Tickets = () => {
  const [tickets, setTickets] = useState<Ticket[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  
  const [agentFilter, setAgentFilter] = useState("all");
  const [categoryFilter, setCategoryFilter] = useState("all");
  const [currencyFilter, setCurrencyFilter] = useState("all");
  const [dateFilter, setDateFilter] = useState("");

  useEffect(() => {
    loadTickets();
  }, []);

  const loadTickets = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await ticketService.getAll();
      setTickets(data);
    } catch (err) {
      console.error('Failed to load tickets:', err);
      setError(err instanceof Error ? err.message : 'Failed to load tickets');
    } finally {
      setLoading(false);
    }
  };

  const filtered = tickets.filter((t) => {
    if (agentFilter !== "all" && t.agent_id !== agentFilter) return false;
    if (categoryFilter !== "all" && t.ticket_category !== categoryFilter) return false;
    if (currencyFilter !== "all" && t.currency !== currencyFilter) return false;
    if (dateFilter) {
      const issued = new Date(t.issued_at);
      const filterDate = new Date(dateFilter);
      if (issued.toDateString() !== filterDate.toDateString()) return false;
    }
    return true;
  });

  const totals = filtered.reduce<Record<string, number>>((acc, t) => {
    if (!t.is_voided) acc[t.currency] = (acc[t.currency] || 0) + Number(t.amount);
    return acc;
  }, {});

  // Get unique agents for filter
  const uniqueAgents = Array.from(
    new Map(tickets.map(t => [t.agent_id, { id: t.agent_id, name: t.agent_name || 'Unknown' }])).values()
  );

  const renderStatus = (t: Ticket) => {
    if (t.is_voided) return <Badge className="bg-destructive/10 text-destructive border border-destructive/20 text-xs">VOIDED</Badge>;
    if (t.linked_passenger_ticket_id) return <Badge variant="secondary" className="text-xs">LINKED</Badge>;
    return <Badge className="bg-success/10 text-success border border-success/20 text-xs">VALID</Badge>;
  };

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.3 }}>
      <PageHeader title="Tickets" description="View and filter all issued tickets" />

      {error && (
        <div className="mb-6">
          <ErrorAlert message={error} onRetry={loadTickets} />
        </div>
      )}

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
                  <Input type="date" value={dateFilter} onChange={(e) => setDateFilter(e.target.value)} className="w-full sm:w-40" />
                  <Select value={agentFilter} onValueChange={setAgentFilter}>
                    <SelectTrigger className="w-full sm:w-44"><SelectValue placeholder="All Agents" /></SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All Agents</SelectItem>
                      {uniqueAgents.map((a) => <SelectItem key={a.id} value={a.id}>{a.name}</SelectItem>)}
                    </SelectContent>
                  </Select>
                  <Select value={categoryFilter} onValueChange={setCategoryFilter}>
                    <SelectTrigger className="w-full sm:w-40"><SelectValue placeholder="All Types" /></SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All Types</SelectItem>
                      <SelectItem value="PASSENGER">Passenger</SelectItem>
                      <SelectItem value="PASSENGER_WITH_LUGGAGE">Passenger + Luggage</SelectItem>
                      <SelectItem value="LUGGAGE">Luggage Only</SelectItem>
                    </SelectContent>
                  </Select>
                  <Select value={currencyFilter} onValueChange={setCurrencyFilter}>
                    <SelectTrigger className="w-full sm:w-32"><SelectValue placeholder="Currency" /></SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All</SelectItem>
                      <SelectItem value="USD">USD</SelectItem>
                      <SelectItem value="ZWL">ZWL</SelectItem>
                      <SelectItem value="ZAR">ZAR</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </CardContent>
            </Card>
          </motion.div>

          {/* Totals */}
          <motion.div
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.3, delay: 0.15 }}
            className="flex flex-wrap gap-2 sm:gap-3 mb-6"
          >
            {Object.entries(totals).map(([cur, total]) => (
              <Badge key={cur} variant="secondary" className="text-sm px-3 py-1.5 font-mono shadow-sm">
                {cur}: {total.toLocaleString(undefined, { minimumFractionDigits: 2 })}
              </Badge>
            ))}
            <Badge variant="outline" className="text-sm px-3 py-1.5">{filtered.length} tickets</Badge>
          </motion.div>

          {tickets.length === 0 ? (
            <div className="text-center py-12">
              <Receipt className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
              <p className="text-muted-foreground">No tickets issued yet.</p>
            </div>
          ) : (
            <ResponsiveTable
              columns={columns}
              data={filtered}
              keyExtractor={(t) => t.id}
              renderRow={(t) => (
                <TableRow key={t.id} className={`hover:bg-muted/30 transition-colors ${t.is_voided ? "opacity-50" : ""}`}>
                  <TableCell className="font-mono text-xs">{t.serial_number ?? "—"}</TableCell>
                  <TableCell><Badge variant="outline" className="text-[10px]">{t.ticket_category}</Badge></TableCell>
                  <TableCell className="text-sm">
                    {t.departure && t.destination ? (
                      <span className="flex items-center gap-1.5">
                        {t.departure} <ArrowRight className="h-3 w-3 text-muted-foreground" /> {t.destination}
                      </span>
                    ) : (
                      <span className="text-muted-foreground">{t.route_label || "—"}</span>
                    )}
                  </TableCell>
                  <TableCell className="text-sm">{t.agent_name || "—"}</TableCell>
                  <TableCell className="font-mono text-sm">{t.fleet_number || "—"}</TableCell>
                  <TableCell className="text-sm">{t.currency}</TableCell>
                  <TableCell className="font-mono font-semibold">{Number(t.amount).toFixed(2)}</TableCell>
                  <TableCell className="text-sm text-muted-foreground">{new Date(t.issued_at).toLocaleString()}</TableCell>
                  <TableCell>{renderStatus(t)}</TableCell>
                </TableRow>
              )}
              renderCard={(t) => (
                <div className={`space-y-3 ${t.is_voided ? "opacity-50" : ""}`}>
                  <div className="flex items-center justify-between">
                    <div>
                      {t.departure && t.destination ? (
                        <p className="text-sm font-medium flex items-center gap-1.5">
                          {t.departure} <ArrowRight className="h-3 w-3 text-muted-foreground" /> {t.destination}
                        </p>
                      ) : (
                        <p className="text-sm font-medium">{t.route_label || "Route not available"}</p>
                      )}
                      <p className="text-xs text-muted-foreground font-mono">{t.serial_number ?? "—"}</p>
                    </div>
                    {renderStatus(t)}
                  </div>
                  <div className="grid grid-cols-3 gap-2 text-sm">
                    <div>
                      <p className="text-muted-foreground text-xs">Amount</p>
                      <p className="font-mono font-semibold">{t.currency} {Number(t.amount).toFixed(2)}</p>
                    </div>
                    <div>
                      <p className="text-muted-foreground text-xs">Agent</p>
                      <p className="font-medium">{t.agent_name || "—"}</p>
                    </div>
                    <div>
                      <p className="text-muted-foreground text-xs">Fleet</p>
                      <p className="font-mono">{t.fleet_number || "—"}</p>
                    </div>
                  </div>
                  <div className="flex items-center justify-between text-xs text-muted-foreground border-t border-border/40 pt-2">
                    <Badge variant="outline" className="text-[10px]">{t.ticket_category}</Badge>
                    <span>{new Date(t.issued_at).toLocaleString()}</span>
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

export default Tickets;

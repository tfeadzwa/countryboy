import { useState, useEffect, useMemo } from "react";
import { motion } from "framer-motion";
import PageHeader from "@/components/PageHeader";
import { ticketService } from "@/lib/api/ticket.service";
import { TableCell, TableRow } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { ResponsiveTable } from "@/components/ResponsiveTable";
import TablePagination from "@/components/TablePagination";
import { Card, CardContent } from "@/components/ui/card";
import {
  Filter,
  ArrowRight,
  Loader2,
  Receipt,
  Search,
  X,
  Banknote,
  Printer,
} from "lucide-react";
import ErrorAlert from "@/components/ErrorAlert";
import TripBatchPrintDialog from "@/components/TripBatchPrintDialog";
import { DEFAULT_PAGE_SIZE } from "@/types/pagination";
import { useAuth } from "@/contexts/AuthContext";
import { canPrintTicketBatches } from "@/lib/permissions";
import type { Ticket, Trip } from "@/types";
import { tripService } from "@/lib/api/trip.service";

const columns = [
  { header: "Serial" },
  { header: "Category" },
  { header: "Route" },
  { header: "Agent" },
  { header: "Fleet" },
  { header: "Amount" },
  { header: "Issued At" },
];

const categoryLabel = (category: string) => {
  switch (category) {
    case "PASSENGER":
      return "Passenger";
    case "PASSENGER_WITH_LUGGAGE":
      return "Passenger + Luggage";
    case "LUGGAGE":
      return "Luggage";
    default:
      return category;
  }
};

const Tickets = () => {
  const { user } = useAuth();
  const canPrint = canPrintTicketBatches(user?.roles || []);
  const [tickets, setTickets] = useState<Ticket[]>([]);
  const [trips, setTrips] = useState<Trip[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [printTrip, setPrintTrip] = useState<Trip | null>(null);

  const [search, setSearch] = useState("");
  const [agentFilter, setAgentFilter] = useState("all");
  const [tripFilter, setTripFilter] = useState("all");
  const [categoryFilter, setCategoryFilter] = useState("all");
  const [currencyFilter, setCurrencyFilter] = useState("all");
  const [dateFilter, setDateFilter] = useState("");
  const [page, setPage] = useState(1);

  useEffect(() => {
    loadTickets();
  }, []);

  const loadTickets = async () => {
    setLoading(true);
    setError(null);
    try {
      const [ticketData, tripData] = await Promise.all([
        ticketService.getAll(),
        tripService.getAll().catch(() => [] as Trip[]),
      ]);
      setTickets(ticketData);
      setTrips(tripData);
    } catch (err) {
      console.error("Failed to load tickets:", err);
      setError(err instanceof Error ? err.message : "Failed to load tickets");
    } finally {
      setLoading(false);
    }
  };

  const uniqueAgents = useMemo(
    () =>
      Array.from(
        new Map(
          tickets.map((t) => [
            t.agent_id,
            { id: t.agent_id, name: t.agent_name || "Unknown" },
          ]),
        ).values(),
      ),
    [tickets],
  );

  const filtered = useMemo(() => {
    const query = search.trim().toLowerCase();

    return tickets.filter((t) => {
      if (agentFilter !== "all" && t.agent_id !== agentFilter) return false;
      if (tripFilter !== "all" && t.trip_id !== tripFilter) return false;
      if (categoryFilter !== "all" && t.ticket_category !== categoryFilter)
        return false;
      if (currencyFilter !== "all" && t.currency !== currencyFilter)
        return false;
      if (dateFilter) {
        const issued = new Date(t.issued_at);
        const filterDate = new Date(dateFilter);
        if (issued.toDateString() !== filterDate.toDateString()) return false;
      }

      if (!query) return true;

      const serial =
        t.serial_number != null
          ? String(t.serial_number).padStart(3, "0")
          : "";
      const fields = [
        serial,
        String(t.serial_number ?? ""),
        t.ticket_category,
        categoryLabel(t.ticket_category),
        t.departure,
        t.destination,
        t.route_label,
        t.departure && t.destination
          ? `${t.departure} ${t.destination}`
          : "",
        t.departure && t.destination
          ? `${t.departure} -> ${t.destination}`
          : "",
        t.agent_name,
        t.fleet_number,
        t.currency,
        String(t.amount),
        t.depot_name,
      ];

      return fields
        .filter(Boolean)
        .some((value) => String(value).toLowerCase().includes(query));
    });
  }, [
    tickets,
    search,
    agentFilter,
    tripFilter,
    categoryFilter,
    currencyFilter,
    dateFilter,
  ]);

  const totals = useMemo(
    () =>
      filtered.reduce<Record<string, number>>((acc, t) => {
        if (!t.is_voided) {
          acc[t.currency] = (acc[t.currency] || 0) + Number(t.amount);
        }
        return acc;
      }, {}),
    [filtered],
  );

  const totalPages = Math.max(1, Math.ceil(filtered.length / DEFAULT_PAGE_SIZE));

  const paginated = useMemo(() => {
    const start = (page - 1) * DEFAULT_PAGE_SIZE;
    return filtered.slice(start, start + DEFAULT_PAGE_SIZE);
  }, [filtered, page]);

  const hasActiveFilters =
    search.trim() !== "" ||
    agentFilter !== "all" ||
    tripFilter !== "all" ||
    categoryFilter !== "all" ||
    currencyFilter !== "all" ||
    dateFilter !== "";

  useEffect(() => {
    setPage(1);
  }, [search, agentFilter, tripFilter, categoryFilter, currencyFilter, dateFilter]);

  useEffect(() => {
    if (page > totalPages) setPage(totalPages);
  }, [page, totalPages]);

  const clearFilters = () => {
    setSearch("");
    setAgentFilter("all");
    setTripFilter("all");
    setCategoryFilter("all");
    setCurrencyFilter("all");
    setDateFilter("");
  };

  const formatIssuedAt = (iso: string) =>
    new Date(iso).toLocaleString(undefined, {
      dateStyle: "medium",
      timeStyle: "short",
    });

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{ duration: 0.3 }}
    >
      <PageHeader
        title="Tickets"
        description="Search and browse issued tickets across your depot"
      >
        {canPrint && tripFilter !== "all" && (
          <Button
            size="sm"
            className="gap-2 shadow-sm"
            onClick={() => {
              const trip = trips.find((t) => t.id === tripFilter) ?? null;
              if (trip) setPrintTrip(trip);
            }}
          >
            <Printer className="h-4 w-4" /> Print trip batch
          </Button>
        )}
      </PageHeader>

      <TripBatchPrintDialog
        open={!!printTrip}
        onOpenChange={(open) => {
          if (!open) setPrintTrip(null);
        }}
        trip={printTrip}
      />

      {error && (
        <div className="mb-6">
          <ErrorAlert error={error} />
        </div>
      )}

      {loading ? (
        <div className="flex items-center justify-center py-16">
          <Loader2 className="h-8 w-8 animate-spin text-primary" />
        </div>
      ) : tickets.length === 0 ? (
        <div className="rounded-2xl border border-dashed border-border/70 bg-muted/20 px-6 py-16 text-center">
          <Receipt className="mx-auto mb-4 h-12 w-12 text-muted-foreground" />
          <p className="text-base font-medium">No tickets issued yet</p>
          <p className="mt-1 text-sm text-muted-foreground">
            Tickets will appear here once conductors start selling.
          </p>
        </div>
      ) : (
        <div className="space-y-5">
          <motion.div
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.3, delay: 0.05 }}
          >
            <Card className="border-border/60 shadow-sm">
              <CardContent className="space-y-4 p-4 sm:p-5">
                <div className="flex items-center gap-2">
                  <Filter className="h-3.5 w-3.5 text-muted-foreground" />
                  <span className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
                    Filters
                  </span>
                  {hasActiveFilters && (
                    <Button
                      type="button"
                      variant="ghost"
                      size="sm"
                      className="ml-auto h-7 px-2 text-xs"
                      onClick={clearFilters}
                    >
                      Clear all
                    </Button>
                  )}
                </div>

                <div className="grid grid-cols-2 gap-2 sm:flex sm:flex-wrap sm:items-center sm:gap-3">
                  <Input
                    type="date"
                    value={dateFilter}
                    onChange={(e) => setDateFilter(e.target.value)}
                    className="h-9 w-full sm:w-40"
                  />
                  <Select value={agentFilter} onValueChange={setAgentFilter}>
                    <SelectTrigger className="h-9 w-full sm:w-44">
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
                  <Select value={tripFilter} onValueChange={setTripFilter}>
                    <SelectTrigger className="h-9 w-full sm:w-52">
                      <SelectValue placeholder="All Trips" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All Trips</SelectItem>
                      {trips.map((t) => (
                        <SelectItem key={t.id} value={t.id}>
                          {(t.fleet_number || "Bus")} · {t.route_label || t.id.slice(0, 8)}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                  <Select
                    value={categoryFilter}
                    onValueChange={setCategoryFilter}
                  >
                    <SelectTrigger className="h-9 w-full sm:w-44">
                      <SelectValue placeholder="All Types" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All Types</SelectItem>
                      <SelectItem value="PASSENGER">Passenger</SelectItem>
                      <SelectItem value="PASSENGER_WITH_LUGGAGE">
                        Passenger + Luggage
                      </SelectItem>
                      <SelectItem value="LUGGAGE">Luggage</SelectItem>
                    </SelectContent>
                  </Select>
                  <Select
                    value={currencyFilter}
                    onValueChange={setCurrencyFilter}
                  >
                    <SelectTrigger className="h-9 w-full sm:w-32">
                      <SelectValue placeholder="Currency" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All</SelectItem>
                      <SelectItem value="USD">USD</SelectItem>
                      <SelectItem value="ZWL">ZWL</SelectItem>
                      <SelectItem value="ZAR">ZAR</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div className="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
                  <div className="relative w-full lg:max-w-md">
                    <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
                    <Input
                      value={search}
                      onChange={(e) => setSearch(e.target.value)}
                      placeholder="Search serial, route, agent, fleet…"
                      className="h-10 pl-9 pr-9"
                      aria-label="Search tickets"
                    />
                    {search.trim() && (
                      <button
                        type="button"
                        onClick={() => setSearch("")}
                        className="absolute right-2.5 top-1/2 -translate-y-1/2 rounded-md p-1 text-muted-foreground hover:bg-muted hover:text-foreground"
                        aria-label="Clear search"
                      >
                        <X className="h-3.5 w-3.5" />
                      </button>
                    )}
                  </div>
                  <p className="text-xs text-muted-foreground lg:text-right">
                    {hasActiveFilters
                      ? `${filtered.length} match${filtered.length === 1 ? "" : "es"} of ${tickets.length}`
                      : `${tickets.length} ticket${tickets.length === 1 ? "" : "s"}`}
                  </p>
                </div>
              </CardContent>
            </Card>
          </motion.div>

          {Object.keys(totals).length > 0 && (
            <motion.div
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.3, delay: 0.08 }}
              className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4"
            >
              {Object.entries(totals).map(([cur, total]) => (
                <Card
                  key={cur}
                  className="border-border/60 shadow-sm overflow-hidden"
                >
                  <CardContent className="flex items-center gap-3 p-4">
                    <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-primary/10">
                      <Banknote className="h-4 w-4 text-primary" />
                    </div>
                    <div className="min-w-0">
                      <p className="text-[11px] font-medium uppercase tracking-wide text-muted-foreground">
                        {cur} total
                      </p>
                      <p className="truncate font-mono text-base font-semibold tabular-nums">
                        {total.toLocaleString(undefined, {
                          minimumFractionDigits: 2,
                          maximumFractionDigits: 2,
                        })}
                      </p>
                    </div>
                  </CardContent>
                </Card>
              ))}
              <Card className="border-border/60 shadow-sm overflow-hidden">
                <CardContent className="flex items-center gap-3 p-4">
                  <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-muted">
                    <Receipt className="h-4 w-4 text-muted-foreground" />
                  </div>
                  <div className="min-w-0">
                    <p className="text-[11px] font-medium uppercase tracking-wide text-muted-foreground">
                      Tickets
                    </p>
                    <p className="font-mono text-base font-semibold tabular-nums">
                      {filtered.length}
                    </p>
                  </div>
                </CardContent>
              </Card>
            </motion.div>
          )}

          {filtered.length === 0 ? (
            <div className="rounded-2xl border border-dashed border-border/70 bg-muted/20 px-6 py-14 text-center">
              <Search className="mx-auto mb-4 h-11 w-11 text-muted-foreground" />
              <p className="text-base font-medium">No tickets match</p>
              <p className="mt-1 text-sm text-muted-foreground">
                Try a different search or clear your filters.
              </p>
              <Button
                size="sm"
                variant="outline"
                className="mt-4"
                onClick={clearFilters}
              >
                Clear filters
              </Button>
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
                    className={`transition-colors hover:bg-muted/30 ${
                      t.is_voided ? "opacity-50" : ""
                    }`}
                  >
                    <TableCell className="font-mono text-xs font-bold tabular-nums">
                      {t.serial_number != null
                        ? String(t.serial_number).padStart(3, "0")
                        : "—"}
                    </TableCell>
                    <TableCell>
                      <Badge variant="outline" className="text-[10px] font-medium">
                        {categoryLabel(t.ticket_category)}
                      </Badge>
                    </TableCell>
                    <TableCell className="text-sm">
                      {t.departure && t.destination ? (
                        <span className="inline-flex items-center gap-1.5">
                          <span className="font-medium">{t.departure}</span>
                          <ArrowRight className="h-3 w-3 shrink-0 text-muted-foreground" />
                          <span className="font-medium">{t.destination}</span>
                        </span>
                      ) : (
                        <span className="text-muted-foreground">
                          {t.route_label || "—"}
                        </span>
                      )}
                    </TableCell>
                    <TableCell className="text-sm">
                      {t.agent_name || "—"}
                    </TableCell>
                    <TableCell className="font-mono text-sm">
                      {t.fleet_number || "—"}
                    </TableCell>
                    <TableCell>
                      <span className="font-mono text-sm font-semibold tabular-nums">
                        <span className="text-muted-foreground font-normal">
                          {t.currency}
                        </span>{" "}
                        {Number(t.amount).toFixed(2)}
                      </span>
                    </TableCell>
                    <TableCell className="whitespace-nowrap text-sm text-muted-foreground">
                      {formatIssuedAt(t.issued_at)}
                    </TableCell>
                  </TableRow>
                )}
                renderCard={(t) => (
                  <div
                    className={`space-y-3 ${t.is_voided ? "opacity-50" : ""}`}
                  >
                    <div className="flex items-start justify-between gap-3">
                      <div className="min-w-0">
                        {t.departure && t.destination ? (
                          <p className="flex items-center gap-1.5 text-sm font-medium">
                            {t.departure}
                            <ArrowRight className="h-3 w-3 shrink-0 text-muted-foreground" />
                            {t.destination}
                          </p>
                        ) : (
                          <p className="text-sm font-medium">
                            {t.route_label || "Route not available"}
                          </p>
                        )}
                        <p className="mt-0.5 font-mono text-xs font-bold text-muted-foreground">
                          #{t.serial_number != null
                            ? String(t.serial_number).padStart(3, "0")
                            : "—"}
                        </p>
                      </div>
                      <Badge variant="outline" className="shrink-0 text-[10px]">
                        {categoryLabel(t.ticket_category)}
                      </Badge>
                    </div>
                    <div className="grid grid-cols-2 gap-3 text-sm sm:grid-cols-3">
                      <div>
                        <p className="text-xs text-muted-foreground">Amount</p>
                        <p className="font-mono font-semibold tabular-nums">
                          {t.currency} {Number(t.amount).toFixed(2)}
                        </p>
                      </div>
                      <div>
                        <p className="text-xs text-muted-foreground">Agent</p>
                        <p className="font-medium">{t.agent_name || "—"}</p>
                      </div>
                      <div>
                        <p className="text-xs text-muted-foreground">Fleet</p>
                        <p className="font-mono">{t.fleet_number || "—"}</p>
                      </div>
                    </div>
                    <div className="border-t border-border/40 pt-2 text-xs text-muted-foreground">
                      {formatIssuedAt(t.issued_at)}
                    </div>
                  </div>
                )}
              />

              <TablePagination
                page={page}
                pageSize={DEFAULT_PAGE_SIZE}
                total={filtered.length}
                totalPages={totalPages}
                onPageChange={setPage}
              />
            </div>
          )}
        </div>
      )}
    </motion.div>
  );
};

export default Tickets;

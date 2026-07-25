import { useState, useEffect, useCallback, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { motion } from "framer-motion";
import PageHeader from "@/components/PageHeader";
import { TableCell, TableRow } from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import {
  Plus,
  Eye,
  Loader2,
  KeyRound,
  AlertTriangle,
  Trash2,
  Bus,
  MoreHorizontal,
  Pencil,
  MapPin,
  Wifi,
  WifiOff,
} from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { ResponsiveTable } from "@/components/ResponsiveTable";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from "@/components/ui/dialog";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import AddAgentDialog from "@/components/AddAgentDialog";
import AgentCredentialsDialog from "@/components/AgentCredentialsDialog";
import ConductorTripDialog from "@/components/ConductorTripDialog";
import ConfirmDeleteDialog from "@/components/ConfirmDeleteDialog";
import TablePagination from "@/components/TablePagination";
import ErrorAlert from "@/components/ErrorAlert";
import { agentService } from "@/lib/api/agent.service";
import { useAuth } from "@/contexts/AuthContext";
import { canManageAgents, isSuperAdmin } from "@/lib/permissions";
import { useToast } from "@/hooks/use-toast";
import { DEFAULT_PAGE_SIZE } from "@/types/pagination";
import type { Agent } from "@/types";

const PRESENCE_POLL_MS = 30_000;

const statusConfig: Record<string, { class: string; dot: string; label: string }> = {
  ACTIVE: { class: "bg-emerald-500/10 text-emerald-700 border border-emerald-500/20", dot: "bg-emerald-600", label: "Active" },
  SUSPENDED: { class: "bg-destructive/10 text-destructive border border-destructive/20", dot: "bg-destructive", label: "Suspended" },
  INACTIVE: { class: "bg-muted text-muted-foreground border border-border", dot: "bg-muted-foreground", label: "Inactive" },
  TERMINATED: { class: "bg-muted text-muted-foreground border border-border", dot: "bg-muted-foreground", label: "Terminated" },
};

const columns = [
  { header: "Conductor" },
  { header: "Depot" },
  { header: "Status" },
  { header: "Trip" },
  { header: "Account" },
  { header: "", className: "text-right w-[1%]" },
];

const initials = (name: string) =>
  name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase() ?? "")
    .join("") || "?";

const conductorPresence = (agent: Agent): "online" | "offline" | "signed_out" => {
  if (agent.conductor_status === "online" || agent.is_online) return "online";
  if (agent.conductor_status === "offline" || agent.active_session) return "offline";
  return "signed_out";
};

const toTimestamp = (value?: string | null) => {
  if (!value) return 0;
  const time = new Date(value).getTime();
  return Number.isNaN(time) ? 0 : time;
};

const conductorSortRank = (agent: Agent) => {
  const presence = conductorPresence(agent);
  const onTrip = Boolean(agent.active_trip);
  if (onTrip && presence === "online") return 0;
  if (onTrip) return 1;
  if (presence === "online") return 2;
  if (presence === "offline") return 3;
  return 4;
};

const compareConductors = (a: Agent, b: Agent) => {
  const rankDiff = conductorSortRank(a) - conductorSortRank(b);
  if (rankDiff !== 0) return rankDiff;

  const tripDiff =
    toTimestamp(b.active_trip?.started_at) - toTimestamp(a.active_trip?.started_at);
  if (tripDiff !== 0) return tripDiff;

  const seenDiff = toTimestamp(b.last_seen) - toTimestamp(a.last_seen);
  if (seenDiff !== 0) return seenDiff;

  return a.full_name.localeCompare(b.full_name);
};

const Agents = () => {
  const { user } = useAuth();
  const { toast } = useToast();
  const navigate = useNavigate();
  const [agents, setAgents] = useState<Agent[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [selectedAgent, setSelectedAgent] = useState<Agent | null>(null);
  const [editingAgent, setEditingAgent] = useState<Agent | undefined>(undefined);
  const [newAgentCredentials, setNewAgentCredentials] = useState<{
    full_name: string;
    username: string;
    merchant_code: string;
    agent_code: string;
    pin: string;
    depot_name?: string;
  } | null>(null);
  const [showNewAgentCredentials, setShowNewAgentCredentials] = useState(false);
  const [resetPinAgent, setResetPinAgent] = useState<Agent | null>(null);
  const [showResetConfirm, setShowResetConfirm] = useState(false);
  const [resettingPin, setResettingPin] = useState(false);
  const [resetPinResult, setResetPinResult] = useState<{
    full_name: string;
    username: string;
    merchant_code: string;
    agent_code: string;
    pin: string;
    depot_name?: string;
  } | null>(null);
  const [showResetPinResult, setShowResetPinResult] = useState(false);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [totalPages, setTotalPages] = useState(1);
  const [deleteTarget, setDeleteTarget] = useState<Agent | null>(null);
  const [deleting, setDeleting] = useState(false);
  const [tripAgent, setTripAgent] = useState<Agent | null>(null);

  const userRoles = user?.roles || [];
  const canManage = canManageAgents(userRoles);
  const isSuperAdminUser = isSuperAdmin(userRoles);

  const fetchAgents = useCallback(
    async (opts?: { silent?: boolean }) => {
      try {
        if (!opts?.silent) setLoading(true);
        setError(null);
        const data = await agentService.listPaginated(page, DEFAULT_PAGE_SIZE);
        setAgents(data.items ?? []);
        setTotal(data.total ?? 0);
        setTotalPages(data.totalPages ?? 1);
        setTripAgent((current) => {
          if (!current) return null;
          return data.items?.find((a) => a.id === current.id) ?? current;
        });
      } catch (err) {
        const errorMessage = err instanceof Error ? err.message : "Failed to load conductors";
        setError(errorMessage);
      } finally {
        setLoading(false);
      }
    },
    [page],
  );

  useEffect(() => {
    void fetchAgents();
    const id = window.setInterval(() => void fetchAgents({ silent: true }), PRESENCE_POLL_MS);
    return () => window.clearInterval(id);
  }, [fetchAgents]);

  const stats = useMemo(() => {
    const online = agents.filter((a) => conductorPresence(a) === "online").length;
    const onTrip = agents.filter((a) => Boolean(a.active_trip)).length;
    const active = agents.filter((a) => a.status === "ACTIVE").length;
    return { online, onTrip, active, total };
  }, [agents, total]);

  const sortedAgents = useMemo(() => [...agents].sort(compareConductors), [agents]);

  const handleAgentCreated = (credentials?: {
    full_name: string;
    username: string;
    merchant_code: string;
    agent_code: string;
    pin: string;
    depot_name?: string;
  }) => {
    if (page !== 1) setPage(1);
    else void fetchAgents();
    if (credentials) {
      setNewAgentCredentials(credentials);
      setShowNewAgentCredentials(true);
    }
  };

  const handleEditClick = (agent: Agent) => {
    setEditingAgent(agent);
    setDialogOpen(true);
  };

  const handleDialogClose = (open: boolean) => {
    setDialogOpen(open);
    if (!open) setEditingAgent(undefined);
  };

  const handleResetPinClick = (agent: Agent) => {
    setResetPinAgent(agent);
    setShowResetConfirm(true);
  };

  const handleResetPinConfirm = async () => {
    if (!resetPinAgent) return;
    setResettingPin(true);
    try {
      const result = await agentService.resetPin(resetPinAgent.id, resetPinAgent.depot_id);
      setResetPinResult({
        full_name: result.full_name,
        username: result.username || "",
        merchant_code: result.merchant_code || "",
        agent_code: result.agent_code,
        pin: result.pin || "",
        depot_name: result.depot_name,
      });
      setShowResetConfirm(false);
      setShowResetPinResult(true);
      toast({
        title: "PIN reset successful",
        description: `New PIN generated for ${result.full_name}. Share it securely.`,
      });
      void fetchAgents();
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : "Failed to reset PIN";
      toast({
        title: "Reset failed",
        description: errorMessage.includes("Depot context")
          ? "Unable to reset PIN. Please try again."
          : errorMessage,
        variant: "destructive",
      });
    } finally {
      setResettingPin(false);
    }
  };

  const handleDeleteConfirm = async () => {
    if (!deleteTarget) return;
    setDeleting(true);
    try {
      await agentService.delete(
        deleteTarget.id,
        isSuperAdminUser ? deleteTarget.depot_id : undefined,
      );
      toast({
        title: "Conductor deleted",
        description: `${deleteTarget.full_name} was removed successfully.`,
      });
      setDeleteTarget(null);
      if (agents.length === 1 && page > 1) setPage(page - 1);
      else void fetchAgents();
    } catch (err) {
      toast({
        title: "Delete failed",
        description: err instanceof Error ? err.message : "Could not delete conductor",
        variant: "destructive",
      });
    } finally {
      setDeleting(false);
    }
  };

  const openTrip = (agent: Agent) => {
    if (agent.active_trip?.id) {
      navigate(`/trips/${agent.active_trip.id}`);
      return;
    }
    setTripAgent(agent);
  };

  const PresencePill = ({ agent }: { agent: Agent }) => {
    const presence = conductorPresence(agent);
    if (presence === "online") {
      return (
        <span className="inline-flex items-center gap-1.5 rounded-full bg-emerald-500/10 px-2.5 py-1 text-xs font-semibold uppercase tracking-wide text-emerald-700 ring-1 ring-inset ring-emerald-500/20">
          <span className="relative flex h-1.5 w-1.5">
            <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-emerald-500 opacity-60" />
            <span className="relative inline-flex h-1.5 w-1.5 rounded-full bg-emerald-600" />
          </span>
          Online
        </span>
      );
    }
    if (presence === "offline") {
      return (
        <span className="inline-flex items-center gap-1.5 rounded-full bg-slate-500/10 px-2.5 py-1 text-xs font-semibold uppercase tracking-wide text-slate-600 ring-1 ring-inset ring-slate-500/15">
          <WifiOff className="h-3 w-3" />
          Offline
        </span>
      );
    }
    return (
      <span className="inline-flex items-center gap-1.5 rounded-full bg-muted px-2.5 py-1 text-xs font-semibold uppercase tracking-wide text-muted-foreground ring-1 ring-inset ring-border">
        <Wifi className="h-3 w-3 opacity-50" />
        Signed out
      </span>
    );
  };

  const TripCell = ({ agent }: { agent: Agent }) => {
    const trip = agent.active_trip;
    if (!trip) {
      return (
        <span className="inline-flex items-center gap-1.5 text-sm text-muted-foreground">
          <span className="h-1.5 w-1.5 rounded-full bg-border" />
          Idle
        </span>
      );
    }
    return (
      <div className="max-w-[260px] space-y-1.5">
        <span className="inline-flex items-center gap-1.5 rounded-full bg-amber-500/15 px-2.5 py-1 text-xs font-semibold uppercase tracking-wide text-amber-800 ring-1 ring-inset ring-amber-500/30">
          <Bus className="h-3 w-3" />
          On trip
        </span>
        <p className="truncate text-[11px] text-muted-foreground">
          {trip.fleet_number ? `Bus ${trip.fleet_number} · ` : ""}
          {trip.origin} → {trip.destination}
        </p>
        <Button
          variant="outline"
          size="sm"
          className="h-7 gap-1 text-xs"
          onClick={(e) => {
            e.stopPropagation();
            navigate(`/trips/${trip.id}`);
          }}
        >
          <Eye className="h-3 w-3" /> View trip
        </Button>
      </div>
    );
  };

  const ActionMenu = ({ agent }: { agent: Agent }) => (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button
          variant="ghost"
          size="icon"
          className="h-8 w-8 text-muted-foreground hover:text-foreground"
          onClick={(e) => e.stopPropagation()}
        >
          <MoreHorizontal className="h-4 w-4" />
          <span className="sr-only">Actions</span>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-48" onClick={(e) => e.stopPropagation()}>
        <DropdownMenuItem onClick={() => setSelectedAgent(agent)}>
          <Eye className="mr-2 h-4 w-4" />
          Credentials
        </DropdownMenuItem>
        <DropdownMenuItem onClick={() => openTrip(agent)}>
          <Bus className="mr-2 h-4 w-4" />
          {agent.active_trip ? "View trip" : "Session details"}
        </DropdownMenuItem>
        {canManage && (
          <>
            <DropdownMenuSeparator />
            <DropdownMenuItem onClick={() => handleEditClick(agent)}>
              <Pencil className="mr-2 h-4 w-4" />
              Edit
            </DropdownMenuItem>
            <DropdownMenuItem onClick={() => handleResetPinClick(agent)}>
              <KeyRound className="mr-2 h-4 w-4 text-orange-600" />
              Reset PIN
            </DropdownMenuItem>
            <DropdownMenuSeparator />
            <DropdownMenuItem
              className="text-destructive focus:text-destructive"
              onClick={() => setDeleteTarget(agent)}
            >
              <Trash2 className="mr-2 h-4 w-4" />
              Delete
            </DropdownMenuItem>
          </>
        )}
      </DropdownMenuContent>
    </DropdownMenu>
  );

  if (loading && agents.length === 0) {
    return (
      <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.3 }}>
        <PageHeader title="Conductors" description="Manage conductors and their depot assignments" />
        <div className="flex items-center justify-center py-16">
          <div className="flex flex-col items-center gap-3">
            <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
            <p className="text-sm text-muted-foreground">Loading conductors…</p>
          </div>
        </div>
      </motion.div>
    );
  }

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.3 }}>
      <PageHeader title="Conductors" description="Live presence, trips, and depot assignments">
        {canManage && (
          <Button size="sm" className="gap-2 shadow-sm" onClick={() => setDialogOpen(true)}>
            <Plus className="h-4 w-4" /> Add Conductor
          </Button>
        )}
      </PageHeader>

      <ErrorAlert error={error} />

      {total > 0 && (
        <div className="mb-5 grid grid-cols-2 gap-3 sm:grid-cols-4">
          {[
            { label: "Total", value: stats.total },
            { label: "Active accounts", value: stats.active },
            { label: "Online now", value: stats.online },
            { label: "On trip", value: stats.onTrip },
          ].map((stat) => (
            <div
              key={stat.label}
              className="rounded-2xl border border-border/70 bg-card/80 px-4 py-3 shadow-sm"
            >
              <p className="text-[11px] font-medium uppercase tracking-wide text-muted-foreground">
                {stat.label}
              </p>
              <p className="mt-1 text-2xl font-semibold tracking-tight tabular-nums">{stat.value}</p>
            </div>
          ))}
        </div>
      )}

      <AddAgentDialog
        open={dialogOpen}
        onOpenChange={handleDialogClose}
        onSuccess={handleAgentCreated}
        agent={editingAgent}
      />

      <AgentCredentialsDialog
        open={showNewAgentCredentials}
        onOpenChange={setShowNewAgentCredentials}
        credentials={newAgentCredentials}
        isNewAgent={!!newAgentCredentials?.pin}
      />

      <AgentCredentialsDialog
        open={!!selectedAgent}
        onOpenChange={(open) => {
          if (!open) setSelectedAgent(null);
        }}
        credentials={
          selectedAgent
            ? {
                full_name: selectedAgent.full_name,
                username: selectedAgent.username,
                merchant_code: selectedAgent.merchant_code || "N/A",
                agent_code: selectedAgent.agent_code,
                pin: "",
                depot_name: selectedAgent.depot_name,
              }
            : null
        }
        isNewAgent={false}
      />

      <Dialog open={showResetConfirm} onOpenChange={setShowResetConfirm}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <div className="mx-auto mb-2 flex h-12 w-12 items-center justify-center rounded-full bg-orange-500/10">
              <AlertTriangle className="h-6 w-6 text-orange-600" />
            </div>
            <DialogTitle className="text-center">Reset conductor PIN</DialogTitle>
            <DialogDescription className="text-center">
              Reset the PIN for <strong>{resetPinAgent?.full_name}</strong>? A new 4-digit PIN will be
              generated for sales authorization.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter className="flex justify-center gap-2 sm:flex-row">
            <Button variant="outline" onClick={() => setShowResetConfirm(false)} disabled={resettingPin}>
              Cancel
            </Button>
            <Button
              onClick={handleResetPinConfirm}
              disabled={resettingPin}
              className="bg-orange-600 hover:bg-orange-700"
            >
              {resettingPin ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  Resetting…
                </>
              ) : (
                <>
                  <KeyRound className="mr-2 h-4 w-4" />
                  Reset PIN
                </>
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <AgentCredentialsDialog
        open={showResetPinResult}
        onOpenChange={setShowResetPinResult}
        credentials={resetPinResult}
        isNewAgent
      />

      <ConfirmDeleteDialog
        open={!!deleteTarget}
        onOpenChange={(open) => !open && setDeleteTarget(null)}
        title="Delete conductor?"
        description={
          deleteTarget
            ? `This will permanently remove ${deleteTarget.full_name}. Conductors with trip or ticket history cannot be deleted — set status to Terminated instead.`
            : ""
        }
        loading={deleting}
        onConfirm={handleDeleteConfirm}
      />

      <ConductorTripDialog
        open={!!tripAgent}
        onOpenChange={(open) => {
          if (!open) setTripAgent(null);
        }}
        agent={tripAgent}
      />

      {total === 0 ? (
        <div className="rounded-3xl border border-dashed border-border/80 bg-muted/20 px-6 py-16 text-center">
          <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-primary/10">
            <Wifi className="h-6 w-6 text-primary" />
          </div>
          <p className="text-base font-semibold">No conductors yet</p>
          <p className="mt-1 text-sm text-muted-foreground">
            Add a conductor to start pairing devices and issuing tickets.
          </p>
          {canManage && (
            <Button size="sm" className="mt-5 gap-2" onClick={() => setDialogOpen(true)}>
              <Plus className="h-4 w-4" /> Add first conductor
            </Button>
          )}
        </div>
      ) : (
        <div className="space-y-4">
          <ResponsiveTable
              columns={columns}
              data={sortedAgents}
              keyExtractor={(a) => a.id}
              renderRow={(a) => {
                const account = statusConfig[a.status] ?? statusConfig.INACTIVE;
                return (
                  <TableRow
                    key={a.id}
                    className="group cursor-pointer border-border/60 hover:bg-muted/40"
                    onClick={() => setSelectedAgent(a)}
                  >
                    <TableCell className="py-3.5">
                      <div className="flex items-center gap-3">
                        <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-rose-500/15 to-amber-500/10 text-xs font-bold tracking-wide text-rose-800">
                          {initials(a.full_name)}
                        </div>
                        <div className="min-w-0">
                          <p className="leading-tight">{a.full_name}</p>
                          <div className="mt-1 flex flex-wrap items-center gap-1.5">
                            <Badge variant="outline" className="font-mono text-[10px] font-normal px-1.5 py-0">
                              {a.agent_code}
                            </Badge>
                            {a.username ? (
                              <span className="truncate text-xs text-muted-foreground font-mono">
                                @{a.username}
                              </span>
                            ) : null}
                          </div>
                        </div>
                      </div>
                    </TableCell>
                    <TableCell className="py-3.5">
                      <div className="flex items-center gap-1.5 text-sm text-muted-foreground">
                        <MapPin className="h-3.5 w-3.5 shrink-0 opacity-70" />
                        <span className="truncate">{a.depot_name || "—"}</span>
                      </div>
                    </TableCell>
                    <TableCell className="py-3.5">
                      <PresencePill agent={a} />
                    </TableCell>
                    <TableCell className="py-3.5">
                      <TripCell agent={a} />
                    </TableCell>
                    <TableCell className="py-3.5">
                      <Badge className={`text-xs gap-1.5 ${account.class}`}>
                        <span className={`h-1.5 w-1.5 rounded-full ${account.dot}`} />
                        {account.label}
                      </Badge>
                    </TableCell>
                    <TableCell className="py-3.5 text-right">
                      <ActionMenu agent={a} />
                    </TableCell>
                  </TableRow>
                );
              }}
              renderCard={(a) => {
                const account = statusConfig[a.status] ?? statusConfig.INACTIVE;
                return (
                  <div className="space-y-3.5" onClick={() => setSelectedAgent(a)}>
                    <div className="flex items-start justify-between gap-3">
                      <div className="flex min-w-0 items-center gap-3">
                        <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-rose-500/15 to-amber-500/10 text-xs font-bold text-rose-800">
                          {initials(a.full_name)}
                        </div>
                        <div className="min-w-0">
                          <p className="truncate">{a.full_name}</p>
                          <div className="mt-1 flex flex-wrap items-center gap-1.5">
                            <Badge variant="outline" className="font-mono text-[10px] font-normal">
                              {a.agent_code}
                            </Badge>
                            {a.username ? (
                              <span className="text-xs text-muted-foreground font-mono">@{a.username}</span>
                            ) : null}
                          </div>
                        </div>
                      </div>
                      <div onClick={(e) => e.stopPropagation()}>
                        <ActionMenu agent={a} />
                      </div>
                    </div>

                    <div className="flex flex-wrap gap-2">
                      <PresencePill agent={a} />
                      <Badge className={`text-xs gap-1.5 ${account.class}`}>
                        <span className={`h-1.5 w-1.5 rounded-full ${account.dot}`} />
                        {account.label}
                      </Badge>
                    </div>

                    <div className="rounded-xl border border-border/70 bg-muted/20 px-3 py-2.5">
                      <p className="text-[11px] uppercase tracking-wide text-muted-foreground">Depot</p>
                      <p className="mt-0.5 text-sm font-medium">{a.depot_name || "—"}</p>
                    </div>

                    <div onClick={(e) => e.stopPropagation()}>
                      <TripCell agent={a} />
                    </div>
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

export default Agents;

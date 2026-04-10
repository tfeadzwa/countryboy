import { useState, useEffect } from "react";
import { motion } from "framer-motion";
import PageHeader from "@/components/PageHeader";
import { TableCell, TableRow } from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { Plus, Eye, UserCircle, Loader2, KeyRound, AlertTriangle } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { ResponsiveTable } from "@/components/ResponsiveTable";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from "@/components/ui/dialog";
import AddAgentDialog from "@/components/AddAgentDialog";
import AgentCredentialsDialog from "@/components/AgentCredentialsDialog";
import ErrorAlert from "@/components/ErrorAlert";
import { agentService } from "@/lib/api/agent.service";
import { useAuth } from "@/contexts/AuthContext";
import { canManageAgents } from "@/lib/permissions";
import { useToast } from "@/hooks/use-toast";
import type { Agent } from "@/types";

//status configs
const statusConfig: Record<string, { class: string; dot: string }> = {
  ACTIVE: { class: "bg-success/10 text-success border border-success/20", dot: "bg-success" },
  SUSPENDED: { class: "bg-destructive/10 text-destructive border border-destructive/20", dot: "bg-destructive" },
  INACTIVE: { class: "bg-muted text-muted-foreground", dot: "bg-muted-foreground" },
};

const columns = [
  { header: "Full Name" },
  { header: "Username" },
  { header: "Agent Code" },
  { header: "Depot" },
  { header: "Status" },
  { header: "Actions", className: "text-right" },
];

const Agents = () => {
  const { user } = useAuth();
  const { toast } = useToast();
  const [agents, setAgents] = useState<Agent[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [selectedAgent, setSelectedAgent] = useState<Agent | null>(null);
  const [editingAgent, setEditingAgent] = useState<Agent | undefined>(undefined);
  const [newAgentCredentials, setNewAgentCredentials] = useState<{ full_name: string; username: string; merchant_code: string; agent_code: string; pin: string; depot_name?: string } | null>(null);
  const [showNewAgentCredentials, setShowNewAgentCredentials] = useState(false);
  const [resetPinAgent, setResetPinAgent] = useState<Agent | null>(null);
  const [showResetConfirm, setShowResetConfirm] = useState(false);
  const [resettingPin, setResettingPin] = useState(false);
  const [resetPinResult, setResetPinResult] = useState<{ full_name: string; username: string; merchant_code: string; agent_code: string; pin: string; depot_name?: string } | null>(null);
  const [showResetPinResult, setShowResetPinResult] = useState(false);

  const userRoles = user?.roles || [];
  const canManage = canManageAgents(userRoles);

  const fetchAgents = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await agentService.getAll();
      setAgents(data);
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to load agents';
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAgents();
  }, []);

  const handleAgentCreated = (credentials?: { full_name: string; username: string; merchant_code: string; agent_code: string; pin: string; depot_name?: string }) => {
    fetchAgents();
    // If credentials are provided (new agent), show credentials dialog
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
    if (!open) {
      setEditingAgent(undefined);
    }
  };

  const handleResetPinClick = (agent: Agent, e: React.MouseEvent) => {
    e.stopPropagation();
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
        username: result.username || '',
        merchant_code: result.merchant_code || '',
        agent_code: result.agent_code,
        pin: result.pin || '',
        depot_name: result.depot_name,
      });
      setShowResetConfirm(false);
      setShowResetPinResult(true);
      toast({
        title: "PIN Reset Successful",
        description: `New PIN generated for ${result.full_name}. Make sure to share it securely.`,
      });
      fetchAgents(); // Refresh list
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to reset PIN';
      toast({
        title: "Reset Failed",
        description: errorMessage.includes('Depot context') 
          ? 'Unable to reset PIN. Please try again.'
          : errorMessage,
        variant: "destructive",
      });
    } finally {
      setResettingPin(false);
    }
  };

  if (loading) {
    return (
      <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.3 }}>
        <PageHeader title="Agents" description="Manage conductors and their depot assignments" />
        <div className="flex items-center justify-center py-12">
          <div className="flex flex-col items-center gap-3">
            <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
            <p className="text-sm text-muted-foreground">Loading agents...</p>
          </div>
        </div>
      </motion.div>
    );
  }

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.3 }}>
      <PageHeader title="Agents" description="Manage conductors and their depot assignments">
        {canManage && (
          <Button size="sm" className="gap-2 shadow-sm" onClick={() => setDialogOpen(true)}>
            <Plus className="h-4 w-4" /> Add Agent
          </Button>
        )}
      </PageHeader>

      <ErrorAlert error={error} />

      <AddAgentDialog 
        open={dialogOpen} 
        onOpenChange={handleDialogClose}
        onSuccess={handleAgentCreated}
        agent={editingAgent}
      />
      
      {/* Credentials dialog for newly created/updated agent */}
      <AgentCredentialsDialog
        open={showNewAgentCredentials}
        onOpenChange={setShowNewAgentCredentials}
        credentials={newAgentCredentials}
        isNewAgent={!!newAgentCredentials?.pin}
      />
      
      {/* Credentials dialog for existing agent (PIN hidden) */}
      <AgentCredentialsDialog
        open={!!selectedAgent}
        onOpenChange={(open) => { if (!open) setSelectedAgent(null); }}
        credentials={selectedAgent ? { 
          full_name: selectedAgent.full_name, 
          username: selectedAgent.username, 
          merchant_code: selectedAgent.merchant_code || "N/A", 
          agent_code: selectedAgent.agent_code, 
          pin: "", // Don't show hashed PIN
          depot_name: selectedAgent.depot_name 
        } : null}
        isNewAgent={false}
      />

      {/* Confirmation dialog for PIN reset */}
      <Dialog open={showResetConfirm} onOpenChange={setShowResetConfirm}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <div className="mx-auto mb-2 flex h-12 w-12 items-center justify-center rounded-full bg-orange-500/10">
              <AlertTriangle className="h-6 w-6 text-orange-600" />
            </div>
            <DialogTitle className="text-center">Reset Agent PIN</DialogTitle>
            <DialogDescription className="text-center">
              Are you sure you want to reset the PIN for <strong>{resetPinAgent?.full_name}</strong>?
              <br />
              <span className="text-xs text-muted-foreground mt-2 block">
                A new 4-digit PIN will be generated. The agent will need the new PIN to authorize sales.
              </span>
            </DialogDescription>
          </DialogHeader>
          <DialogFooter className="flex justify-center gap-2 sm:flex-row">
            <Button
              variant="outline"
              onClick={() => setShowResetConfirm(false)}
              disabled={resettingPin}
            >
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
                  Resetting...
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

      {/* Credentials dialog for reset PIN result */}
      <AgentCredentialsDialog
        open={showResetPinResult}
        onOpenChange={setShowResetPinResult}
        credentials={resetPinResult}
        isNewAgent
      />

      <ResponsiveTable
        columns={columns}
        data={agents}
        keyExtractor={(a) => a.id}
        renderRow={(a) => {
          const config = statusConfig[a.status];
          return (
            <TableRow key={a.id} className="group cursor-pointer hover:bg-muted/30 transition-colors" onClick={() => setSelectedAgent(a)}>
              <TableCell>
                <div className="flex items-center gap-2.5">
                  <div className="h-8 w-8 rounded-full bg-secondary/10 flex items-center justify-center">
                    <UserCircle className="h-4 w-4 text-secondary" />
                  </div>
                  <span className="font-medium">{a.full_name}</span>
                </div>
              </TableCell>
              <TableCell className="font-mono text-sm text-muted-foreground">{a.username}</TableCell>
              <TableCell><Badge variant="outline" className="font-mono text-xs">{a.agent_code}</Badge></TableCell>
              <TableCell className="text-muted-foreground text-sm">{a.depot_name}</TableCell>
              <TableCell>
                <Badge className={`text-xs gap-1.5 ${config.class}`}>
                  <span className={`h-1.5 w-1.5 rounded-full ${config.dot}`} />
                  {a.status}
                </Badge>
              </TableCell>
              <TableCell className="text-right space-x-1">
                <Button variant="ghost" size="sm" className="gap-1" onClick={(e) => { e.stopPropagation(); setSelectedAgent(a); }}>
                  <Eye className="h-3.5 w-3.5" /> Credentials
                </Button>
                {canManage ? (
                  <>
                    <Button variant="ghost" size="sm" onClick={(e) => { e.stopPropagation(); handleEditClick(a); }}>
                      Edit
                    </Button>
                    <Button variant="ghost" size="sm" className="gap-1 text-orange-600 hover:text-orange-700 hover:bg-orange-50" onClick={(e) => handleResetPinClick(a, e)}>
                      <KeyRound className="h-3.5 w-3.5" /> Reset PIN
                    </Button>
                  </>
                ) : (
                  <span className="text-xs text-muted-foreground">View only</span>
                )}
              </TableCell>
            </TableRow>
          );
        }}
        renderCard={(a) => {
          const config = statusConfig[a.status];
          return (
            <div className="space-y-3 cursor-pointer" onClick={() => setSelectedAgent(a)}>
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2.5">
                  <div className="h-9 w-9 rounded-full bg-secondary/10 flex items-center justify-center">
                    <UserCircle className="h-4 w-4 text-secondary" />
                  </div>
                  <div>
                    <p className="font-medium text-sm">{a.full_name}</p>
                    <p className="text-xs text-muted-foreground font-mono">{a.username}</p>
                  </div>
                </div>
                <Badge className={`text-xs gap-1.5 ${config.class}`}>
                  <span className={`h-1.5 w-1.5 rounded-full ${config.dot}`} />
                  {a.status}
                </Badge>
              </div>
              <div className="grid grid-cols-2 gap-2 text-sm">
                <div>
                  <p className="text-muted-foreground text-xs">Agent Code</p>
                  <Badge variant="outline" className="font-mono text-xs">{a.agent_code}</Badge>
                </div>
                <div>
                  <p className="text-muted-foreground text-xs">Depot</p>
                  <p className="font-medium">{a.depot_name}</p>
                </div>
              </div>
              <div className="flex justify-between items-center pt-2 border-t border-border/40">
                <Button variant="ghost" size="sm" className="gap-1 text-accent" onClick={(e) => { e.stopPropagation(); setSelectedAgent(a); }}>
                  <Eye className="h-3.5 w-3.5" /> Credentials
                </Button>
                {canManage && (
                  <div className="flex gap-1">
                    <Button variant="ghost" size="sm" onClick={(e) => { e.stopPropagation(); handleEditClick(a); }}>
                      Edit
                    </Button>
                    <Button variant="ghost" size="sm" className="gap-1 text-orange-600" onClick={(e) => handleResetPinClick(a, e)}>
                      <KeyRound className="h-3.5 w-3.5" /> Reset PIN
                    </Button>
                  </div>
                )}
              </div>
            </div>
          );
        }}
      />
    </motion.div>
  );
};

export default Agents;

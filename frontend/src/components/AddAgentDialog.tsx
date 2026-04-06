import { useState, useEffect } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { UserPlus, Loader2, AlertCircle } from "lucide-react";
import { Alert, AlertDescription } from "@/components/ui/alert";
import AgentCredentialsDialog from "@/components/AgentCredentialsDialog";
import { agentService } from "@/lib/api/agent.service";
import { depotService } from "@/lib/api/depot.service";
import { useAuth } from "@/contexts/AuthContext";
import { isSuperAdmin } from "@/lib/permissions";
import type { Agent, Depot } from "@/types";

interface AddAgentDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSuccess: (credentials?: { full_name: string; username: string; merchant_code: string; agent_code: string; pin: string; depot_name?: string }) => void;
  agent?: Agent; // Optional: if provided, dialog is in edit mode
}

const AddAgentDialog = ({ open, onOpenChange, onSuccess, agent }: AddAgentDialogProps) => {
  const { user } = useAuth();
  const isEditMode = !!agent;
  const isSuperAdminUser = user ? isSuperAdmin(user.roles || []) : false;
  
  const [fullName, setFullName] = useState("");
  const [status, setStatus] = useState<'ACTIVE' | 'INACTIVE' | 'SUSPENDED' | 'TERMINATED'>('ACTIVE');
  const [selectedDepotId, setSelectedDepotId] = useState<string>("");
  const [depots, setDepots] = useState<Depot[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Load depots for SUPER_ADMIN and pre-populate form
  useEffect(() => {
    const initialize = async () => {
      if (open) {
        let depotList: Depot[] = [];
        
        // Load depots first if SUPER_ADMIN
        if (isSuperAdminUser) {
          try {
            depotList = await depotService.getAll();
            setDepots(depotList);
          } catch (err) {
            console.error('Failed to load depots:', err);
          }
        }

        // Pre-populate form when editing
        if (agent) {
          setFullName(agent.full_name);
          setStatus(agent.status);
          // Pre-populate depot for SUPER_ADMIN in edit mode
          if (isSuperAdminUser && agent.depot_id) {
            setSelectedDepotId(agent.depot_id);
          }
        } else {
          // Reset form for create mode
          setFullName("");
          setStatus('ACTIVE');
          // Auto-select first depot if available (only in create mode, for SUPER_ADMIN)
          if (isSuperAdminUser && depotList.length > 0) {
            setSelectedDepotId(depotList[0].id);
          }
        }
      } else {
        // Reset form when closing
        setFullName("");
        setStatus('ACTIVE');
        setSelectedDepotId("");
        setError(null);
      }
    };

    initialize();
  }, [agent, open, isSuperAdminUser]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    // Validation
    if (!fullName.trim()) {
      setError("Full name is required");
      return;
    }

    // SUPER_ADMIN must select a depot
    if (isSuperAdminUser && !selectedDepotId) {
      setError("Please select a depot for this agent");
      return;
    }

    setLoading(true);

    try {
      if (isEditMode && agent) {
        // Update existing agent (full_name, status, and depot_id can be updated)
        const agentData: any = {
          full_name: fullName.trim(),
          status,
        };
        
        // Include depot_id if SUPER_ADMIN changed it
        if (isSuperAdminUser && selectedDepotId && selectedDepotId !== agent.depot_id) {
          agentData.depot_id = selectedDepotId;
        }
        
        // Pass depot_id for context (use new depot if changed, otherwise current depot)
        const contextDepotId = isSuperAdminUser && selectedDepotId ? selectedDepotId : agent.depot_id;
        const updatedAgent = await agentService.update(agent.id, agentData, contextDepotId);
        
        // Pass credentials back to parent to show after update
        const credentials = {
          full_name: updatedAgent.full_name,
          username: updatedAgent.username || "",
          merchant_code: updatedAgent.merchant_code || "",
          agent_code: updatedAgent.agent_code,
          pin: "", // Don't show PIN for updates (only for creation and reset)
          depot_name: updatedAgent.depot_name,
        };
        
        // Reset form
        setFullName("");
        setStatus('ACTIVE');
        setSelectedDepotId("");
        setError(null);
        
        // Close dialog and pass credentials to parent
        onOpenChange(false);
        onSuccess(credentials);
        return; // Exit early for update
      } else {
        // Create new agent (backend auto-generates username, agent_code, and PIN)
        const agentData = {
          full_name: fullName.trim(),
          status,
        };
        // Pass depot_id for SUPER_ADMIN users
        const newAgent = await agentService.create(agentData, isSuperAdminUser ? selectedDepotId : undefined);
        
        // Pass credentials back to parent to show credentials dialog
        const credentials = {
          full_name: newAgent.full_name,
          username: newAgent.username || "",
          merchant_code: newAgent.merchant_code || "",
          agent_code: newAgent.agent_code,
          pin: newAgent.pin || "",
          depot_name: newAgent.depot_name,
        };
        
        // Reset form
        setFullName("");
        setStatus('ACTIVE');
        setSelectedDepotId("");
        setError(null);
        
        // Close dialog and pass credentials to parent
        onOpenChange(false);
        onSuccess(credentials);
        return; // Exit early for creation
      }
    } catch (err) {
      // Translate backend errors to user-friendly messages
      let errorMessage = `Failed to ${isEditMode ? 'update' : 'create'} agent`;
      if (err instanceof Error) {
        if (err.message.includes('Depot context required')) {
          errorMessage = 'Unable to process request. Please try again or contact support.';
        } else if (err.message.includes('403') || err.message.includes('Forbidden')) {
          errorMessage = 'You do not have permission to perform this action.';
        } else if (err.message.includes('duplicate') || err.message.includes('already exists')) {
          errorMessage = 'An agent with this information already exists.';
        } else {
          errorMessage = err.message;
        }
      }
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <Dialog open={open} onOpenChange={onOpenChange}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <div className="mx-auto mb-2 flex h-12 w-12 items-center justify-center rounded-full bg-primary/10">
              <UserPlus className="h-6 w-6 text-primary" />
            </div>
            <DialogTitle className="text-center">
              {isEditMode ? 'Edit Agent' : 'Add New Agent'}
            </DialogTitle>
            <DialogDescription className="text-center">
              {isEditMode 
                ? 'Update agent information below.'
                : 'Create a new conductor account. Username, agent code, and PIN will be auto-generated.'}
            </DialogDescription>
          </DialogHeader>

          <form onSubmit={handleSubmit} className="space-y-4 pt-2">
            {error && (
              <Alert variant="destructive">
                <AlertCircle className="h-4 w-4" />
                <AlertDescription>{error}</AlertDescription>
              </Alert>
            )}

            {isSuperAdminUser && (
              <div className="space-y-2">
                <Label htmlFor="depot">
                  Depot <span className="text-destructive">*</span>
                </Label>
                <Select value={selectedDepotId} onValueChange={setSelectedDepotId} disabled={loading}>
                  <SelectTrigger id="depot">
                    <SelectValue placeholder="Select depot..." />
                  </SelectTrigger>
                  <SelectContent>
                    {depots.map((depot) => (
                      <SelectItem key={depot.id} value={depot.id}>
                        {depot.name} ({depot.merchant_code})
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                <p className="text-xs text-muted-foreground">
                  {isEditMode ? "Change agent's depot assignment" : "Agent will be assigned to this depot"}
                </p>
              </div>
            )}

            <div className="space-y-2">
              <Label htmlFor="full-name">
                Full Name <span className="text-destructive">*</span>
              </Label>
              <Input
                id="full-name"
                placeholder="e.g. John Moyo"
                value={fullName}
                onChange={(e) => {
                  setFullName(e.target.value);
                  setError(null);
                }}
                required
                disabled={loading}
              />
            </div>



            <div className="space-y-2">
              <Label htmlFor="status">Status</Label>
              <Select value={status} onValueChange={(value: any) => setStatus(value)} disabled={loading}>
                <SelectTrigger id="status">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="ACTIVE">Active</SelectItem>
                  <SelectItem value="INACTIVE">Inactive</SelectItem>
                  <SelectItem value="SUSPENDED">Suspended</SelectItem>
                  <SelectItem value="TERMINATED">Terminated</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <DialogFooter className="pt-2">
              <Button type="button" variant="outline" onClick={() => onOpenChange(false)} disabled={loading}>
                Cancel
              </Button>
              <Button type="submit" disabled={loading} className="gap-2">
                {loading ? (
                  <>
                    <Loader2 className="h-4 w-4 animate-spin" />
                    {isEditMode ? 'Updating…' : 'Creating…'}
                  </>
                ) : (
                  isEditMode ? 'Update Agent' : 'Create Agent'
                )}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

    </>
  );
};

export default AddAgentDialog;

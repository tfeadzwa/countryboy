import { useState, useEffect } from "react";
import { motion } from "framer-motion";
import PageHeader from "@/components/PageHeader";
import { TableCell, TableRow } from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { Plus, Building2, MapPin, Calendar, Loader2 } from "lucide-react";
import { Badge } from "@/components/ui/badge";
import { ResponsiveTable } from "@/components/ResponsiveTable";
import AddDepotDialog from "@/components/AddDepotDialog";
import ErrorAlert from "@/components/ErrorAlert";
import { depotService } from "@/lib/api/depot.service";
import { Depot } from "@/types";
import { useAuth } from "@/contexts/AuthContext";
import { canManageDepots } from "@/lib/permissions";

const columns = [
  { header: "Merchant Code" },
  { header: "Name" },
  { header: "Location" },
  { header: "Created" },
  { header: "Actions", className: "text-right" },
];

const Depots = () => {
  const { user } = useAuth();
  const [depots, setDepots] = useState<Depot[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showAddDialog, setShowAddDialog] = useState(false);
  const [editingDepot, setEditingDepot] = useState<Depot | undefined>(undefined);

  const userRoles = user?.roles || [];
  const canManage = canManageDepots(userRoles);

  const fetchDepots = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await depotService.getAll();
      setDepots(data);
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to load depots';
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDepots();
  }, []);

  const handleDepotCreated = () => {
    fetchDepots();
  };

  const handleEditClick = (depot: Depot) => {
    setEditingDepot(depot);
    setShowAddDialog(true);
  };

  const handleDialogClose = (open: boolean) => {
    setShowAddDialog(open);
    if (!open) {
      setEditingDepot(undefined);
    }
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    });
  };

  if (loading) {
    return (
      <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.3 }}>
        <PageHeader title="Depots" description="Manage depot locations and merchant codes" />
        <div className="flex items-center justify-center py-12">
          <div className="flex flex-col items-center gap-3">
            <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
            <p className="text-sm text-muted-foreground">Loading depots...</p>
          </div>
        </div>
      </motion.div>
    );
  }

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.3 }}>
      <PageHeader title="Depots" description="Manage depot locations and merchant codes">
        {canManage && (
          <Button size="sm" className="gap-2 shadow-sm" onClick={() => setShowAddDialog(true)}>
            <Plus className="h-4 w-4" /> Add Depot
          </Button>
        )}
      </PageHeader>

      <ErrorAlert error={error} />

      {depots.length === 0 && !error ? (
        <div className="rounded-lg border border-dashed border-border bg-muted/20 p-12">
          <div className="flex flex-col items-center gap-3 text-center">
            <div className="rounded-full bg-muted p-4">
              <Building2 className="h-8 w-8 text-muted-foreground" />
            </div>
            <div className="space-y-1">
              <p className="text-sm font-medium">No depots found</p>
              <p className="text-sm text-muted-foreground">
                {canManage 
                  ? 'Get started by creating your first depot'
                  : 'No depots have been created yet'}
              </p>
            </div>
            {canManage && (
              <Button size="sm" className="mt-2" onClick={() => setShowAddDialog(true)}>
                <Plus className="h-4 w-4 mr-2" /> Add Depot
              </Button>
            )}
          </div>
        </div>
      ) : (
        <ResponsiveTable
          columns={columns}
          data={depots}
          keyExtractor={(d) => d.id}
          renderRow={(d) => (
            <TableRow key={d.id} className="group hover:bg-muted/30 transition-colors">
              <TableCell><Badge variant="outline" className="font-mono text-xs">{d.merchant_code}</Badge></TableCell>
              <TableCell className="font-medium">
                <div className="flex items-center gap-2.5">
                  <div className="h-8 w-8 rounded-lg bg-primary/10 flex items-center justify-center">
                    <Building2 className="h-4 w-4 text-primary" />
                  </div>
                  {d.name}
                </div>
              </TableCell>
              <TableCell>
                <span className="flex items-center gap-1.5 text-muted-foreground text-sm">
                  <MapPin className="h-3.5 w-3.5" />{d.location || "N/A"}
                </span>
              </TableCell>
              <TableCell>
                <span className="flex items-center gap-1.5 text-muted-foreground text-sm">
                  <Calendar className="h-3.5 w-3.5" />{formatDate(d.created_at)}
                </span>
              </TableCell>
              <TableCell className="text-right">
                {canManage ? (
                  <Button 
                    variant="ghost" 
                    size="sm" 
                    onClick={() => handleEditClick(d)}
                  >
                    Edit
                  </Button>
                ) : (
                  <span className="text-xs text-muted-foreground">View only</span>
                )}
              </TableCell>
            </TableRow>
          )}
          renderCard={(d) => (
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2.5">
                  <div className="h-9 w-9 rounded-lg bg-primary/10 flex items-center justify-center">
                    <Building2 className="h-4 w-4 text-primary" />
                  </div>
                  <div>
                    <p className="font-medium text-sm">{d.name}</p>
                    <p className="text-xs text-muted-foreground flex items-center gap-1">
                      <MapPin className="h-3 w-3" />{d.location || "N/A"}
                    </p>
                  </div>
                </div>
                <Badge variant="outline" className="font-mono text-xs">{d.merchant_code}</Badge>
              </div>
              <div className="flex items-center justify-between pt-2 border-t border-border/40">
                <span className="text-xs text-muted-foreground flex items-center gap-1">
                  <Calendar className="h-3 w-3" />{formatDate(d.created_at)}
                </span>
                {canManage && (
                  <Button 
                    variant="ghost" 
                    size="sm" 
                    onClick={() => handleEditClick(d)}
                  >
                    Edit
                  </Button>
                )}
              </div>
            </div>
          )}
        />
      )}

      <AddDepotDialog
        open={showAddDialog}
        onOpenChange={handleDialogClose}
        onSuccess={handleDepotCreated}
        depot={editingDepot}
      />
    </motion.div>
  );
};

export default Depots;

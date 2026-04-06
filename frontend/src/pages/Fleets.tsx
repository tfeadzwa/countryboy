import { useState, useEffect } from "react";
import { motion } from "framer-motion";
import PageHeader from "@/components/PageHeader";
import { fleetService } from "@/lib/api/fleet.service";
import { TableCell, TableRow } from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Plus, Bus, Loader2, Users } from "lucide-react";
import { ResponsiveTable } from "@/components/ResponsiveTable";
import AddFleetDialog from "@/components/AddFleetDialog";
import ErrorAlert from "@/components/ErrorAlert";
import { canManageFleets } from "@/lib/permissions";
import { useAuth } from "@/contexts/AuthContext";
import type { Fleet } from "@/types";

const columns = [
  { header: "Fleet Number" },
  { header: "Depot" },
  { header: "Status" },
  { header: "Capacity" },
  { header: "Actions", className: "text-right" },
];

const Fleets = () => {
  const { user } = useAuth();
  const [fleets, setFleets] = useState<Fleet[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingFleet, setEditingFleet] = useState<Fleet | null>(null);
  
  const canManage = user ? canManageFleets(user.roles || []) : false;

  const fetchFleets = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await fleetService.getAll();
      setFleets(data);
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to load fleets';
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchFleets();
  }, []);

  const handleFleetSaved = () => {
    fetchFleets();
  };

  const handleEdit = (fleet: Fleet) => {
    setEditingFleet(fleet);
    setDialogOpen(true);
  };

  const handleDialogClose = () => {
    setDialogOpen(false);
    setEditingFleet(null);
  };

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.3 }}>
      <PageHeader title="Fleets" description="Manage buses and vehicle assignments">
        {canManage && (
          <Button size="sm" className="gap-2 shadow-sm" onClick={() => setDialogOpen(true)}>
            <Plus className="h-4 w-4" /> Add Fleet
          </Button>
        )}
      </PageHeader>

      <AddFleetDialog
        open={dialogOpen}
        onOpenChange={handleDialogClose}
        onSuccess={handleFleetSaved}
        fleet={editingFleet}
      />

      {loading ? (
        <div className="flex items-center justify-center py-12">
          <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
        </div>
      ) : (
        <>
          <ErrorAlert error={error} />
          {fleets.length === 0 ? (
            <div className="text-center py-12">
              <Bus className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
              <p className="text-muted-foreground">No fleets registered yet.</p>
              {canManage && (
                <Button size="sm" className="gap-2 mt-4" onClick={() => setDialogOpen(true)}>
                  <Plus className="h-4 w-4" /> Add First Fleet
                </Button>
              )}
            </div>
          ) : (
            <ResponsiveTable<Fleet>
              columns={columns}
              data={fleets}
              keyExtractor={(f) => f.id}
              renderRow={(f) => (
                <TableRow key={f.id} className="group hover:bg-muted/30 transition-colors">
                  <TableCell>
                    <div className="flex items-center gap-2.5">
                      <div className="h-8 w-8 rounded-lg flex items-center justify-center bg-primary/10">
                        <Bus className="h-4 w-4 text-primary" />
                      </div>
                      <span className="font-mono font-medium">{f.number}</span>
                    </div>
                  </TableCell>
                  <TableCell className="text-muted-foreground text-sm">{f.depot_name || 'N/A'}</TableCell>
                  <TableCell>
                    <Badge 
                      variant={f.status === 'ACTIVE' ? 'default' : f.status === 'MAINTENANCE' ? 'secondary' : 'outline'}
                      className={`text-xs ${
                        f.status === 'ACTIVE' ? 'bg-green-500/10 text-green-700 border-green-500/20' :
                        f.status === 'MAINTENANCE' ? 'bg-yellow-500/10 text-yellow-700 border-yellow-500/20' :
                        f.status === 'OUT_OF_SERVICE' ? 'bg-red-500/10 text-red-700 border-red-500/20' :
                        'bg-gray-500/10 text-gray-700 border-gray-500/20'
                      }`}
                    >
                      {f.status.replace(/_/g, ' ')}
                    </Badge>
                  </TableCell>
                  <TableCell className="text-sm text-muted-foreground">
                    <span className="flex items-center gap-1.5">
                      <Users className="h-3.5 w-3.5" />
                      {f.capacity} seats
                    </span>
                  </TableCell>
                  <TableCell className="text-right">
                    {canManage && (
                      <Button variant="ghost" size="sm" onClick={() => handleEdit(f)}>
                        Edit
                      </Button>
                    )}
                  </TableCell>
                </TableRow>
              )}
              renderCard={(f) => (
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2.5">
                      <div className="h-9 w-9 rounded-lg flex items-center justify-center bg-primary/10">
                        <Bus className="h-4 w-4 text-primary" />
                      </div>
                      <div>
                        <p className="font-mono font-medium text-sm">{f.number}</p>
                        <p className="text-xs text-muted-foreground">{f.depot_name || 'N/A'}</p>
                      </div>
                    </div>
                    <Badge 
                      variant={f.status === 'ACTIVE' ? 'default' : f.status === 'MAINTENANCE' ? 'secondary' : 'outline'}
                      className={`text-xs ${
                        f.status === 'ACTIVE' ? 'bg-green-500/10 text-green-700 border-green-500/20' :
                        f.status === 'MAINTENANCE' ? 'bg-yellow-500/10 text-yellow-700 border-yellow-500/20' :
                        f.status === 'OUT_OF_SERVICE' ? 'bg-red-500/10 text-red-700 border-red-500/20' :
                        'bg-gray-500/10 text-gray-700 border-gray-500/20'
                      }`}
                    >
                      {f.status.replace(/_/g, ' ')}
                    </Badge>
                  </div>
                  <div className="grid grid-cols-2 gap-2 text-sm">
                    <div>
                      <p className="text-muted-foreground text-xs">Capacity</p>
                      <p className="font-medium flex items-center gap-1">
                        <Users className="h-3 w-3 text-muted-foreground" />
                        {f.capacity} seats
                      </p>
                    </div>
                    <div>
                      <p className="text-muted-foreground text-xs">Status</p>
                      <p className="font-medium">{f.status.replace(/_/g, ' ')}</p>
                    </div>
                  </div>
                  {canManage && (
                    <div className="flex justify-end pt-2 border-t border-border/40">
                      <Button variant="ghost" size="sm" onClick={() => handleEdit(f)}>
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
    </motion.div>
  );
};

export default Fleets;

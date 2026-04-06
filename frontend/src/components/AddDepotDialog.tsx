import { useState, useEffect } from "react";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Building2, Loader2, AlertCircle } from "lucide-react";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { depotService } from "@/lib/api/depot.service";
import { Depot } from "@/types";

interface AddDepotDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  onSuccess: () => void;
  depot?: Depot; // Optional: if provided, dialog is in edit mode
}

const AddDepotDialog = ({ open, onOpenChange, onSuccess, depot }: AddDepotDialogProps) => {
  const isEditMode = !!depot;
  const [merchantCode, setMerchantCode] = useState("");
  const [name, setName] = useState("");
  const [location, setLocation] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Pre-populate form when editing
  useEffect(() => {
    if (depot && open) {
      setMerchantCode(depot.merchant_code);
      setName(depot.name);
      setLocation(depot.location || "");
    } else if (!open) {
      // Reset form when closing
      setMerchantCode("");
      setName("");
      setLocation("");
      setError(null);
    }
  }, [depot, open]);

  const validateMerchantCode = (code: string): boolean => {
    // Must be exactly 6 characters: 3 uppercase letters + 3 digits (e.g., HRE001)
    const pattern = /^[A-Z]{3}\d{3}$/;
    return pattern.test(code);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    // Validation
    if (!merchantCode.trim() || !name.trim()) {
      setError("Merchant code and name are required");
      return;
    }

    const upperMerchantCode = merchantCode.trim().toUpperCase();
    
    if (!validateMerchantCode(upperMerchantCode)) {
      setError("Merchant code must be 6 characters: 3 uppercase letters + 3 digits (e.g., HRE001)");
      return;
    }

    setLoading(true);

    try {
      const depotData = {
        merchant_code: upperMerchantCode,
        name: name.trim(),
        location: location.trim() || undefined,
      };

      if (isEditMode && depot) {
        await depotService.update(depot.id, depotData);
      } else {
        await depotService.create(depotData);
      }

      // Reset form
      setMerchantCode("");
      setName("");
      setLocation("");
      setError(null);
      
      // Close dialog and refresh list
      onOpenChange(false);
      onSuccess();
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : `Failed to ${isEditMode ? 'update' : 'create'} depot`;
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  const handleOpenChange = (newOpen: boolean) => {
    if (!loading) {
      if (!newOpen) {
        // Reset form when closing
        setMerchantCode("");
        setName("");
        setLocation("");
        setError(null);
      }
      onOpenChange(newOpen);
    }
  };

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <div className="mx-auto mb-2 flex h-12 w-12 items-center justify-center rounded-full bg-primary/10">
            <Building2 className="h-6 w-6 text-primary" />
          </div>
          <DialogTitle className="text-center">
            {isEditMode ? 'Edit Depot' : 'Add New Depot'}
          </DialogTitle>
          <DialogDescription className="text-center">
            {isEditMode 
              ? 'Update the depot information below.'
              : 'Create a new depot location with a unique merchant code.'}
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-4 pt-2">
          {error && (
            <Alert variant="destructive">
              <AlertCircle className="h-4 w-4" />
              <AlertDescription>{error}</AlertDescription>
            </Alert>
          )}

          <div className="space-y-2">
            <Label htmlFor="merchant-code">
              Merchant Code <span className="text-destructive">*</span>
            </Label>
            <Input
              id="merchant-code"
              placeholder="e.g. HRE001"
              value={merchantCode}
              onChange={(e) => {
                setMerchantCode(e.target.value.toUpperCase());
                setError(null);
              }}
              maxLength={6}
              required
              disabled={loading || isEditMode}
              className="font-mono"
            />
            <p className="text-xs text-muted-foreground">
              {isEditMode 
                ? 'Merchant code cannot be changed'
                : 'Format: 3 letters + 3 digits (e.g., HRE001, BYO002)'}
            </p>
          </div>

          <div className="space-y-2">
            <Label htmlFor="depot-name">
              Depot Name <span className="text-destructive">*</span>
            </Label>
            <Input
              id="depot-name"
              placeholder="e.g. Harare Central"
              value={name}
              onChange={(e) => {
                setName(e.target.value);
                setError(null);
              }}
              required
              disabled={loading}
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="location">Location (Optional)</Label>
            <Input
              id="location"
              placeholder="e.g. Corner of 5th St & Rotten Row"
              value={location}
              onChange={(e) => setLocation(e.target.value)}
              disabled={loading}
            />
          </div>

          <DialogFooter className="gap-2">
            <Button
              type="button"
              variant="outline"
              onClick={() => handleOpenChange(false)}
              disabled={loading}
            >
              Cancel
            </Button>
            <Button type="submit" disabled={loading}>
              {loading ? (
                <>
                  <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                  {isEditMode ? 'Updating...' : 'Creating...'}
                </>
              ) : (
                <>
                  <Building2 className="mr-2 h-4 w-4" />
                  {isEditMode ? 'Update Depot' : 'Create Depot'}
                </>
              )}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
};

export default AddDepotDialog;

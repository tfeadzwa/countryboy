import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";
import { Loader2 } from "lucide-react";

interface ConfirmDeleteDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  title: string;
  description: string;
  confirmLabel?: string;
  loadingLabel?: string;
  loading?: boolean;
  onConfirm: () => void;
  /** Defaults to destructive (delete). Use "default" for non-delete confirms. */
  tone?: "destructive" | "default";
}

const ConfirmDeleteDialog = ({
  open,
  onOpenChange,
  title,
  description,
  confirmLabel = "Delete",
  loadingLabel = "Deleting…",
  loading = false,
  onConfirm,
  tone = "destructive",
}: ConfirmDeleteDialogProps) => (
  <AlertDialog open={open} onOpenChange={onOpenChange}>
    <AlertDialogContent>
      <AlertDialogHeader>
        <AlertDialogTitle>{title}</AlertDialogTitle>
        <AlertDialogDescription>{description}</AlertDialogDescription>
      </AlertDialogHeader>
      <AlertDialogFooter>
        <AlertDialogCancel disabled={loading}>Cancel</AlertDialogCancel>
        <AlertDialogAction
          onClick={(e) => {
            e.preventDefault();
            onConfirm();
          }}
          disabled={loading}
          className={
            tone === "destructive"
              ? "bg-destructive text-destructive-foreground hover:bg-destructive/90"
              : undefined
          }
        >
          {loading ? (
            <>
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
              {loadingLabel}
            </>
          ) : (
            confirmLabel
          )}
        </AlertDialogAction>
      </AlertDialogFooter>
    </AlertDialogContent>
  </AlertDialog>
);

export default ConfirmDeleteDialog;

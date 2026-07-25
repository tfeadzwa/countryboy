import { Printer, X } from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import TicketReceipt58mm from "@/components/TicketReceipt58mm";
import type { TripDetail, TripDetailTicket } from "@/types";

interface TicketReceiptPrintDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  ticket: TripDetailTicket | null;
  trip: TripDetail | null;
}

const TicketReceiptPrintDialog = ({
  open,
  onOpenChange,
  ticket,
  trip,
}: TicketReceiptPrintDialogProps) => {
  if (!ticket || !trip) return null;

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-md max-h-[92vh] overflow-hidden p-0 gap-0 print:max-w-none print:max-h-none print:overflow-visible print:shadow-none print:border-0 print:bg-transparent">
        <div className="flex items-start justify-between gap-3 border-b border-border/60 px-4 py-3 print:hidden">
          <DialogHeader className="space-y-1 text-left">
            <DialogTitle>Print ticket</DialogTitle>
            <DialogDescription>
              58 mm receipt — same layout as the conductor mobile printer.
            </DialogDescription>
          </DialogHeader>
          <Button
            variant="ghost"
            size="icon"
            className="shrink-0"
            onClick={() => onOpenChange(false)}
          >
            <X className="h-4 w-4" />
          </Button>
        </div>

        <div className="overflow-y-auto px-4 py-5 print:overflow-visible print:p-0">
          <div className="mx-auto w-fit rounded-lg border border-border/70 bg-white p-3 shadow-sm print:border-0 print:p-0 print:shadow-none">
            <TicketReceipt58mm ticket={ticket} trip={trip} printRoot />
          </div>
          <p className="mt-3 text-center text-xs text-muted-foreground print:hidden">
            Select your 58 mm thermal printer in the system print dialog.
          </p>
        </div>

        <div className="flex flex-col-reverse gap-2 border-t border-border/60 px-4 py-3 sm:flex-row sm:justify-end print:hidden">
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Close
          </Button>
          <Button className="gap-2" onClick={() => window.print()}>
            <Printer className="h-4 w-4" />
            Print ticket
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
};

export default TicketReceiptPrintDialog;

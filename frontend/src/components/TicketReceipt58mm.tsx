import { QRCodeSVG } from "qrcode.react";
import type { TripDetail, TripDetailTicket } from "@/types";
import {
  receiptCategoryLabel,
  receiptIssuedAt,
  receiptRouteLine,
  receiptTicketNumber,
  sanitizeReceiptText,
  ticketVerifyUrl,
} from "@/lib/ticket-receipt";

const KvRow = ({ label, value }: { label: string; value: string }) => (
  <div className="ticket-receipt-kv">
    <span className="ticket-receipt-kv-label">{sanitizeReceiptText(label.toUpperCase())}</span>
    <span className="ticket-receipt-kv-value">{sanitizeReceiptText(value)}</span>
  </div>
);

interface TicketReceipt58mmProps {
  ticket: TripDetailTicket;
  trip: TripDetail;
  /** When true, wraps with the print-root id used by @media print. */
  printRoot?: boolean;
}

/**
 * 58mm thermal ticket layout matching mobile TicketPrintService (ESC/POS).
 */
const TicketReceipt58mm = ({ ticket, trip, printRoot = false }: TicketReceipt58mmProps) => {
  const verifyUrl = ticketVerifyUrl(ticket.id);
  const amount = `${ticket.currency} ${Number(ticket.amount).toFixed(2)}`;
  const luggageAmt = ticket.luggage_amount;
  const showPaxBagSplit =
    luggageAmt != null &&
    luggageAmt > 0 &&
    ticket.ticket_category === "PASSENGER_WITH_LUGGAGE";
  const passengerAmt = showPaxBagSplit ? Number(ticket.amount) - Number(luggageAmt) : 0;

  const body = (
    <div className="ticket-receipt-58mm">
      <img
        src="/cboy-receipt-logo.png"
        alt="CountryBoy"
        className="ticket-receipt-logo"
      />

      <p className="ticket-receipt-title">BUS TICKET</p>
      <p className="ticket-receipt-category">{receiptCategoryLabel(ticket.ticket_category)}</p>
      <hr className="ticket-receipt-hr" />

      <p className="ticket-receipt-route">{receiptRouteLine(ticket, trip)}</p>
      <p className="ticket-receipt-amount">{amount}</p>
      {showPaxBagSplit && (
        <p className="ticket-receipt-split">
          {`Pax ${ticket.currency} ${passengerAmt.toFixed(2)} + Bag ${ticket.currency} ${Number(luggageAmt).toFixed(2)}`}
        </p>
      )}
      <hr className="ticket-receipt-hr" />

      <KvRow label="Ticket" value={receiptTicketNumber(ticket)} />
      <KvRow label="Fleet" value={trip.fleet_number || "-"} />
      {trip.fleet_registration_number ? (
        <KvRow label="Plate No" value={trip.fleet_registration_number} />
      ) : null}
      {ticket.luggage_description ? (
        <KvRow label="Luggage" value={ticket.luggage_description} />
      ) : null}
      <KvRow label="Issued" value={receiptIssuedAt(ticket.issued_at)} />
      <KvRow label="Depot" value={trip.depot_name || "-"} />
      <KvRow label="Conductor" value={trip.agent_name || "-"} />
      {trip.device_serial ? <KvRow label="Device" value={trip.device_serial} /> : null}
      {ticket.printer_name ? <KvRow label="Printer" value={ticket.printer_name} /> : null}
      {/* {ticket.printer_mac ? <KvRow label="Mac" value={ticket.printer_mac} /> : null} */}

      <hr className="ticket-receipt-hr" />

      <div className="ticket-receipt-qr">
        <QRCodeSVG value={verifyUrl} size={132} level="M" includeMargin={false} />
      </div>
      <p className="ticket-receipt-verify">Scan to verify ticket</p>
      <hr className="ticket-receipt-hr" />

      <p className="ticket-receipt-footer">Thank you for travelling with us</p>
      <p className="ticket-receipt-brand">countryboy</p>
    </div>
  );

  if (!printRoot) return body;
  return <div id="ticket-receipt-print">{body}</div>;
};

export default TicketReceipt58mm;

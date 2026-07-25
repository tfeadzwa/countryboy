import { format } from "date-fns";
import type { TripDetail, TripDetailTicket } from "@/types";

/** Match mobile sanitizeReceiptText — thermal printers lack many Unicode glyphs. */
export const sanitizeReceiptText = (value: string) =>
  value
    .replace(/→/g, "->")
    .replace(/⟶/g, "->")
    .replace(/⇒/g, "=>")
    .replace(/·/g, "-")
    .replace(/•/g, "-")
    .replace(/—/g, "-")
    .replace(/–/g, "-")
    .replace(/’/g, "'")
    .replace(/‘/g, "'")
    .replace(/“/g, '"')
    .replace(/”/g, '"');

export const receiptCategoryLabel = (category: string) => {
  switch (category) {
    case "PASSENGER":
      return "PASSENGER";
    case "PASSENGER_WITH_LUGGAGE":
      return "PASSENGER + LUGGAGE";
    case "LUGGAGE":
      return "LUGGAGE";
    default:
      return sanitizeReceiptText(category);
  }
};

export const receiptTicketNumber = (ticket: TripDetailTicket) =>
  ticket.serial_number != null
    ? String(ticket.serial_number).padStart(3, "0")
    : "Pending";

export const receiptIssuedAt = (issuedAt: string) => {
  const date = new Date(issuedAt);
  if (Number.isNaN(date.getTime())) return "-";
  return sanitizeReceiptText(format(date, "dd MMM yyyy HH:mm"));
};

export const receiptRouteLine = (ticket: TripDetailTicket, trip: TripDetail) => {
  const origin = sanitizeReceiptText(
    ticket.departure || trip.origin || trip.route_origin || "Origin",
  );
  const destination = sanitizeReceiptText(
    ticket.destination || trip.destination || trip.route_destination || "Dest",
  );
  return `${origin} -> ${destination}`;
};

/** Same path as mobile Env.ticketVerifyUrl — public web /verify/:id */
export const ticketVerifyUrl = (ticketId: string) => {
  const base =
    (import.meta.env.VITE_PUBLIC_WEB_URL as string | undefined)?.replace(/\/$/, "") ||
    window.location.origin;
  return `${base}/verify/${ticketId}`;
};

export type TicketReceiptContext = {
  ticket: TripDetailTicket;
  trip: TripDetail;
};

export const CURRENCY_OPTIONS = [
  { value: "USD", label: "USD ($)" },
  { value: "ZWL", label: "ZWL (Z$)" },
  { value: "ZAR", label: "ZAR (R)" },
] as const;

export type CurrencyCode = (typeof CURRENCY_OPTIONS)[number]["value"];

/** Conductor ticket fare rules (also useful for admin reference fares). */
export function validateTicketFareAmount(
  currency: string,
  amount: number,
  label = "Amount",
): string | null {
  if (!Number.isFinite(amount) || amount <= 0) {
    return `${label} must be greater than 0`;
  }
  if (!Number.isInteger(amount)) {
    return `${label} must be a whole number (no cents)`;
  }
  if (currency === "USD" || currency === "ZWL") {
    return null;
  }
  if (currency === "ZAR") {
    if (amount < 20) return `${label} for ZAR must be at least 20`;
    if (amount % 10 !== 0) return `${label} for ZAR must be a multiple of 10`;
    return null;
  }
  return "Unsupported currency";
}

export function currencyFareHint(currency: string): string {
  if (currency === "ZAR") {
    return "Whole amounts from 20, in steps of 10";
  }
  if (currency === "USD" || currency === "ZWL") {
    return "Whole amounts only (no cents)";
  }
  return "Enter amount";
}

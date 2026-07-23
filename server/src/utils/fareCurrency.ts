/**
 * Fare amount rules for conductor-entered ticket prices.
 *
 * USD / ZWL: whole numbers only (multiples of 1).
 * ZAR: whole numbers, minimum 20, multiples of 10.
 */

export const TICKET_CURRENCIES = ['USD', 'ZWL', 'ZAR'] as const;
export type TicketCurrency = (typeof TICKET_CURRENCIES)[number];

export function isTicketCurrency(value: string): value is TicketCurrency {
  return (TICKET_CURRENCIES as readonly string[]).includes(value);
}

/** Returns an error message, or null when valid. */
export function validateFareAmount(
  currency: string,
  amount: number,
  label = 'Amount',
): string | null {
  if (!Number.isFinite(amount) || amount <= 0) {
    return `${label} must be greater than 0`;
  }
  if (!Number.isInteger(amount)) {
    return `${label} must be a whole number (no cents)`;
  }

  if (currency === 'USD' || currency === 'ZWL') {
    return null;
  }

  if (currency === 'ZAR') {
    if (amount < 20) {
      return `${label} for ZAR must be at least 20`;
    }
    if (amount % 10 !== 0) {
      return `${label} for ZAR must be a multiple of 10`;
    }
    return null;
  }

  return 'Unsupported currency';
}

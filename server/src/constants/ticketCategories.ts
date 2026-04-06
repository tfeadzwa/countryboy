/**
 * Ticket Category Constants
 * 
 * Defines the three types of tickets that can be issued:
 * - PASSENGER: Travel ticket for a passenger only
 * - PASSENGER_WITH_LUGGAGE: Single ticket for passenger traveling with luggage
 * - LUGGAGE: Luggage sent without a passenger
 */

export const TICKET_CATEGORIES = {
  PASSENGER: 'PASSENGER',
  PASSENGER_WITH_LUGGAGE: 'PASSENGER_WITH_LUGGAGE',
  LUGGAGE: 'LUGGAGE',
} as const;

export type TicketCategory = typeof TICKET_CATEGORIES[keyof typeof TICKET_CATEGORIES];

export const VALID_TICKET_CATEGORIES = Object.values(TICKET_CATEGORIES);

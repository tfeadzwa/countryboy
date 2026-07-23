/**
 * Ticket Category Constants
 * 
 * Defines the three types of tickets that can be issued:
 * - PASSENGER: Travel ticket; amount entered manually by conductor
 * - PASSENGER_WITH_LUGGAGE: Single ticket; amount = manual passenger fare + luggage_amount
 * - LUGGAGE: Luggage only; amount entered manually
 *
 * Origin/destination are free-text per ticket (not tied to admin route fares).
 */

export const TICKET_CATEGORIES = {
  PASSENGER: 'PASSENGER',
  PASSENGER_WITH_LUGGAGE: 'PASSENGER_WITH_LUGGAGE',
  LUGGAGE: 'LUGGAGE',
} as const;

export type TicketCategory = typeof TICKET_CATEGORIES[keyof typeof TICKET_CATEGORIES];

export const VALID_TICKET_CATEGORIES = Object.values(TICKET_CATEGORIES);

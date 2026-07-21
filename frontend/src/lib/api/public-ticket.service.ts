import axios from 'axios';
import { getApiBaseUrl } from './base-url';

export type TicketVerificationStatus = 'VALID' | 'VOIDED';

export interface TicketVerificationResult {
  verified: boolean;
  status: TicketVerificationStatus;
  ticket: {
    id: string;
    serial_number: number | null;
    display_number: string;
    category: string;
    category_label: string;
    currency: string;
    amount: number;
    luggage_amount: number | null;
    origin: string | null;
    destination: string | null;
    route_label: string | null;
    passenger_phone: string | null;
    luggage_description: string | null;
    issued_at: string;
  };
  trip: {
    fleet_number: string | null;
    started_at: string;
    status: string;
  };
  depot: {
    name: string;
    location: string | null;
  };
  conductor: {
    name: string;
  };
  void_info: {
    reason: string;
    voided_at: string;
  } | null;
}

const publicClient = axios.create({
  baseURL: getApiBaseUrl(),
  timeout: 20000,
  headers: { 'Content-Type': 'application/json' },
});

class PublicTicketService {
  async verify(ticketId: string): Promise<TicketVerificationResult> {
    try {
      const response = await publicClient.get<TicketVerificationResult>(
        `/public/tickets/${encodeURIComponent(ticketId)}`,
      );
      const data = response.data;
      if (
        !data ||
        typeof data !== 'object' ||
        !('ticket' in data) ||
        !(data as TicketVerificationResult).ticket?.display_number
      ) {
        throw new Error(
          'Verification service returned an unexpected response. Check that /api is proxied to the backend.',
        );
      }
      return data;
    } catch (err) {
      if (axios.isAxiosError(err)) {
        const message =
          (err.response?.data as { error?: string } | undefined)?.error ||
          err.message ||
          'Unable to verify ticket';
        throw new Error(message);
      }
      throw err;
    }
  }
}

export const publicTicketService = new PublicTicketService();

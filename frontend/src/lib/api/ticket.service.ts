import apiClient from './axios';
import { Ticket } from '@/types';

class TicketService {
  /**
   * Get all tickets  (filtered by depot scope automatically on backend)
   */
  async getAll(): Promise<Ticket[]> {
    const response = await apiClient.get<Ticket[]>('/tickets');
    return response.data;
  }

  /**
   * Search tickets by various criteria
   */
  async search(params: {
    serial_number?: number;
    ticket_id?: string;
    trip_id?: string;
  }): Promise<Ticket[]> {
    const response = await apiClient.get<Ticket[]>('/tickets/search', { params });
    return response.data;
  }

  /**
   * Void a ticket (requires DEPOT_ADMIN role)
   * @param id - Ticket ID
   * @param reason - Reason for voiding
   * @param agentId - Optional agent ID if voided by agent
   * @param deviceId - Optional device ID if voided from device
   */
  async void(id: string, reason: string, agentId?: string, deviceId?: string): Promise<any> {
    const response = await apiClient.post(`/tickets/${id}/void`, {
      reason,
      agent_id: agentId,
      device_id: deviceId,
    });
    return response.data;
  }
}

export const ticketService = new TicketService();

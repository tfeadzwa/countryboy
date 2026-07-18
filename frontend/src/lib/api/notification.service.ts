import apiClient from './axios';
import type { NotificationsResponse } from '@/types';

class NotificationService {
  async getAll(): Promise<NotificationsResponse> {
    const response = await apiClient.get<NotificationsResponse>('/notifications');
    return response.data;
  }
}

export const notificationService = new NotificationService();

import apiClient from './axios';

export type TicketCurrencyCode = 'USD' | 'ZWL' | 'ZAR';

export interface SystemSettings {
  company_name: string;
  company_email: string | null;
  company_phone: string | null;
  support_email: string | null;
  enabled_currencies: TicketCurrencyCode[];
  default_currency: TicketCurrencyCode;
  timezone: string;
  updated_at?: string;
}

export interface SettingsProfile {
  id: string;
  username: string;
  email: string | null;
  phone: string | null;
  full_name: string | null;
  depot_id: string | null;
  depot_name: string | null;
  depot_merchant_code: string | null;
  status: string;
  roles: string[];
}

export interface SettingsPayload {
  system: SystemSettings;
  profile: SettingsProfile;
  available_currencies: TicketCurrencyCode[];
  features: {
    two_factor_auth: boolean;
    email_notifications: boolean;
    sms_notifications: boolean;
  };
}

export type UpdateSystemSettingsRequest = Partial<{
  company_name: string;
  company_email: string | null;
  company_phone: string | null;
  support_email: string | null;
  enabled_currencies: TicketCurrencyCode[];
  default_currency: TicketCurrencyCode;
  timezone: string;
}>;

export type UpdateProfileSettingsRequest = Partial<{
  full_name: string;
  email: string | null;
  phone: string | null;
}>;

class SettingsService {
  async get(): Promise<SettingsPayload> {
    const response = await apiClient.get<SettingsPayload>('/settings');
    return response.data;
  }

  async updateSystem(data: UpdateSystemSettingsRequest): Promise<SystemSettings> {
    const response = await apiClient.put<SystemSettings>('/settings/system', data);
    return response.data;
  }

  async updateProfile(data: UpdateProfileSettingsRequest): Promise<SettingsProfile> {
    const response = await apiClient.put<SettingsProfile>('/settings/profile', data);
    return response.data;
  }

  async changePassword(currentPassword: string, newPassword: string): Promise<void> {
    await apiClient.post('/settings/change-password', {
      current_password: currentPassword,
      new_password: newPassword,
    });
  }
}

export const settingsService = new SettingsService();

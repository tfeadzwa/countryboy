import apiClient from './axios';
import { Device, DeviceSession } from '@/types';

export interface CreateDeviceRequest {
  serial_number: string;
}

export interface UpdateDeviceRequest {
  serial_number?: string;
  depot_id?: string;
  last_seen?: Date;
  app_version?: string;
  sync_errors?: number;
}

export interface UnpairDeviceResponse {
  id: string;
  serial_number: string;
  pairing_code: string;
  message: string;
}

export type RegeneratePairingCodeResponse = UnpairDeviceResponse;

export interface DeleteDeviceResponse {
  id: string;
  serial_number: string;
  message: string;
}

class DeviceService {
  /**
   * Get all devices (filtered by depot scope automatically on backend)
   */
  async getAll(): Promise<Device[]> {
    const response = await apiClient.get<Device[] | { items?: Device[] }>('/devices');
    const data = response.data;
    return Array.isArray(data) ? data : (data?.items ?? []);
  }

  /**
   * Get a single device by ID
   */
  async getOne(id: string): Promise<Device> {
    const response = await apiClient.get<Device>(`/devices/${id}`);
    return response.data;
  }

  /**
   * Create a new device (register serial number - generates pairing code)
   * Requires DEPOT_ADMIN role
   * @param data - Device data
   * @param depotId - Required for SUPER_ADMIN to specify which depot the device belongs to
   */
  async create(data: CreateDeviceRequest, depotId?: string): Promise<Device> {
    const config = depotId ? {
      headers: { 'x-depot-id': depotId }
    } : {};
    const response = await apiClient.post<Device>('/devices', data, config);
    return response.data;
  }

  /**
   * Update an existing device (serial number and/or depot)
   * Requires DEPOT_ADMIN role
   */
  async update(id: string, data: UpdateDeviceRequest, depotId?: string): Promise<Device> {
    const config = depotId ? {
      headers: { 'x-depot-id': depotId }
    } : {};
    const response = await apiClient.put<Device>(`/devices/${id}`, data, config);
    return response.data;
  }

  /**
   * Delete an unpaired device with no ticket/trip history
   */
  async remove(id: string, depotId?: string): Promise<DeleteDeviceResponse> {
    const config = depotId ? {
      headers: { 'x-depot-id': depotId }
    } : {};
    const response = await apiClient.delete<DeleteDeviceResponse>(`/devices/${id}`, config);
    return response.data;
  }

  /**
   * Unpair device - resets device to unpaired state with new pairing code
   * Requires DEPOT_ADMIN role
   */
  async unpair(id: string, depotId?: string): Promise<UnpairDeviceResponse> {
    const config = depotId ? {
      headers: { 'x-depot-id': depotId }
    } : {};
    const response = await apiClient.post<UnpairDeviceResponse>(`/devices/${id}/unpair`, {}, config);
    return response.data;
  }

  /**
   * Regenerate pairing code for an unpaired device (without full unpair).
   * Requires DEPOT_ADMIN role
   */
  async regeneratePairingCode(id: string, depotId?: string): Promise<RegeneratePairingCodeResponse> {
    const config = depotId ? {
      headers: { 'x-depot-id': depotId }
    } : {};
    const response = await apiClient.post<RegeneratePairingCodeResponse>(
      `/devices/${id}/regenerate-pairing-code`,
      {},
      config,
    );
    return response.data;
  }

  /**
   * Session history for a device (conductor login trail)
   */
  async getSessions(id: string, limit = 20): Promise<{ device_id: string; sessions: DeviceSession[] }> {
    const response = await apiClient.get<{ device_id: string; sessions: DeviceSession[] }>(
      `/devices/${id}/sessions`,
      { params: { limit } },
    );
    return response.data;
  }
}

export const deviceService = new DeviceService();

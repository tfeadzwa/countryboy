import apiClient from './axios';
import { Device } from '@/types';

export interface CreateDeviceRequest {
  serial_number: string;
}

export interface UpdateDeviceRequest {
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

class DeviceService {
  /**
   * Get all devices (filtered by depot scope automatically on backend)
   */
  async getAll(): Promise<Device[]> {
    const response = await apiClient.get<Device[]>('/devices');
    return response.data;
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
   * Update an existing device
   * Requires DEPOT_ADMIN role
   * @param id - Device ID
   * @param data - Device data to update
   * @param depotId - Required for SUPER_ADMIN to specify depot context
   */
  async update(id: string, data: UpdateDeviceRequest, depotId?: string): Promise<Device> {
    const config = depotId ? {
      headers: { 'x-depot-id': depotId }
    } : {};
    const response = await apiClient.put<Device>(`/devices/${id}`, data, config);
    return response.data;
  }

  /**
   * Unpair device - resets device to unpaired state with new pairing code
   * Requires DEPOT_ADMIN role
   * @param id - Device ID
   * @param depotId - Required for SUPER_ADMIN to specify depot context
   */
  async unpair(id: string, depotId?: string): Promise<UnpairDeviceResponse> {
    const config = depotId ? {
      headers: { 'x-depot-id': depotId }
    } : {};
    const response = await apiClient.post<UnpairDeviceResponse>(`/devices/${id}/unpair`, {}, config);
    return response.data;
  }
}

export const deviceService = new DeviceService();

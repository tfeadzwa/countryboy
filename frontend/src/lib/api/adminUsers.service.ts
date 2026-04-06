import apiClient from './axios';

export type AdminUserRole = 'SUPER_ADMIN' | 'DEPOT_ADMIN' | 'MANAGER' | 'VIEWER';
export type AdminUserStatus = 'ACTIVE' | 'INACTIVE';

export interface AdminUserListItem {
  id: string;
  username: string;
  full_name: string;
  email: string | null;
  depot_id: string | null;
  status: AdminUserStatus;
  created_at: string;
  depot: { id: string; name: string; merchant_code: string } | null;
  roles: { role: { id: string; name: string } }[];
}

export interface CreateAdminUserRequest {
  username: string;
  full_name: string;
  email?: string;
  role: 'DEPOT_ADMIN' | 'MANAGER' | 'VIEWER';
  depot_id?: string;
  password?: string;
}

export interface UpdateAdminUserRequest {
  full_name?: string;
  email?: string | null;
  role?: 'DEPOT_ADMIN' | 'MANAGER' | 'VIEWER';
  depot_id?: string | null;
  status?: AdminUserStatus;
}

class AdminUsersService {
  async getAll(): Promise<AdminUserListItem[]> {
    const response = await apiClient.get<AdminUserListItem[]>('/admin-users');
    return response.data;
  }

  async create(data: CreateAdminUserRequest): Promise<AdminUserListItem & { temporaryPassword?: string }> {
    const response = await apiClient.post<AdminUserListItem & { temporaryPassword?: string }>('/admin-users', data);
    return response.data;
  }

  async update(id: string, data: UpdateAdminUserRequest): Promise<AdminUserListItem> {
    const response = await apiClient.put<AdminUserListItem>(`/admin-users/${id}`, data);
    return response.data;
  }
}

export const adminUsersService = new AdminUsersService();

// Helper to extract the primary role name from a list item
export const getPrimaryRoleName = (user: AdminUserListItem): AdminUserRole => {
  return (user.roles?.[0]?.role?.name as AdminUserRole) ?? 'VIEWER';
};

import apiClient from './axios';

export type AdminUserRole =
  | 'DEVELOPER'
  | 'SUPER_ADMIN'
  | 'DEPOT_ADMIN'
  | 'CASHIER'
  | 'MANAGER'
  | 'VIEWER';
export type AdminUserStatus = 'ACTIVE' | 'INACTIVE';

export interface AdminUserListItem {
  id: string;
  username: string;
  full_name: string;
  email: string | null;
  depot_id: string | null;
  status: AdminUserStatus;
  created_at: string;
  last_seen_at?: string | null;
  is_online?: boolean;
  depot: { id: string; name: string; merchant_code: string } | null;
  roles: { role: { id: string; name: string } }[];
}

export interface CreateAdminUserRequest {
  username: string;
  full_name: string;
  email?: string;
  role: Exclude<AdminUserRole, 'SUPER_ADMIN' | 'DEVELOPER'>;
  depot_id?: string;
  password?: string;
}

export interface UpdateAdminUserRequest {
  full_name?: string;
  email?: string | null;
  role?: Exclude<AdminUserRole, 'SUPER_ADMIN' | 'DEVELOPER'>;
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

  async resetPassword(
    id: string,
    password?: string,
  ): Promise<AdminUserListItem & { temporaryPassword: string }> {
    const response = await apiClient.post<AdminUserListItem & { temporaryPassword: string }>(
      `/admin-users/${id}/reset-password`,
      password ? { password } : {},
    );
    return response.data;
  }
}

export const adminUsersService = new AdminUsersService();

// Helper to extract the primary role name from a list item
export const getPrimaryRoleName = (user: AdminUserListItem): AdminUserRole => {
  const names = (user.roles ?? []).map((r) => r.role.name);
  const priority: Record<string, number> = {
    DEVELOPER: 0,
    SUPER_ADMIN: 1,
    DEPOT_ADMIN: 2,
    CASHIER: 3,
    MANAGER: 4,
    VIEWER: 5,
  };
  const sorted = [...names].sort(
    (a, b) => (priority[a] ?? 999) - (priority[b] ?? 999),
  );
  return (sorted[0] as AdminUserRole) ?? 'VIEWER';
};

export const isProtectedAdminRole = (roleName: string): boolean => {
  return roleName === 'SUPER_ADMIN' || roleName === 'DEVELOPER';
};

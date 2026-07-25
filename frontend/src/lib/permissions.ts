/**
 * Permission Helper Functions
 *
 * Centralized logic for checking user permissions based on roles.
 * Aligns with backend role-based access control (RBAC).
 */

export type UserRole =
  | 'SUPER_ADMIN'
  | 'DEPOT_ADMIN'
  | 'CASHIER'
  | 'MANAGER'
  | 'VIEWER';

/**
 * Check if user has any of the specified roles
 */
export const hasRole = (userRoles: string[], ...requiredRoles: string[]): boolean => {
  if (!userRoles || userRoles.length === 0) return false;
  return requiredRoles.some((role) => userRoles.includes(role));
};

/**
 * Check if user is a Super Admin
 */
export const isSuperAdmin = (userRoles: string[]): boolean => {
  return hasRole(userRoles, 'SUPER_ADMIN');
};

/**
 * Check if user is a Depot Admin or higher
 */
export const isDepotAdmin = (userRoles: string[]): boolean => {
  return hasRole(userRoles, 'SUPER_ADMIN', 'DEPOT_ADMIN');
};

/**
 * Check if user is a Cashier (or Super Admin with cashier privileges)
 */
export const isCashier = (userRoles: string[]): boolean => {
  return hasRole(userRoles, 'SUPER_ADMIN', 'CASHIER');
};

/**
 * Check if user is a Manager or higher
 */
export const isManager = (userRoles: string[]): boolean => {
  return hasRole(userRoles, 'SUPER_ADMIN', 'DEPOT_ADMIN', 'MANAGER');
};

// ===== DEPOT PERMISSIONS =====

export const canManageDepots = (userRoles: string[]): boolean => {
  return isSuperAdmin(userRoles);
};

export const canManageAdminUsers = (userRoles: string[]): boolean => {
  return isSuperAdmin(userRoles);
};

// ===== AGENT PERMISSIONS =====

export const canManageAgents = (userRoles: string[]): boolean => {
  return isDepotAdmin(userRoles);
};

export const canViewAgents = (userRoles: string[]): boolean => {
  return userRoles && userRoles.length > 0 && !isCashierOnly(userRoles);
};

// ===== DEVICE PERMISSIONS =====

export const canManageDevices = (userRoles: string[]): boolean => {
  return isDepotAdmin(userRoles);
};

export const canViewDevices = (userRoles: string[]): boolean => {
  return userRoles && userRoles.length > 0 && !isCashierOnly(userRoles);
};

// ===== FLEET PERMISSIONS =====

export const canManageFleets = (userRoles: string[]): boolean => {
  return isDepotAdmin(userRoles);
};

export const canViewFleets = (userRoles: string[]): boolean => {
  return userRoles && userRoles.length > 0 && !isCashierOnly(userRoles);
};

export const canManageDrivers = (userRoles: string[]): boolean => {
  return isDepotAdmin(userRoles);
};

export const canViewDrivers = (userRoles: string[]): boolean => {
  return userRoles && userRoles.length > 0 && !isCashierOnly(userRoles);
};

// ===== ROUTE PERMISSIONS =====

export const canManageRoutes = (userRoles: string[]): boolean => {
  return isDepotAdmin(userRoles);
};

export const canViewRoutes = (userRoles: string[]): boolean => {
  return userRoles && userRoles.length > 0 && !isCashierOnly(userRoles);
};

// ===== FARE PERMISSIONS =====

export const canManageFares = (userRoles: string[]): boolean => {
  return isDepotAdmin(userRoles);
};

export const canViewFares = (userRoles: string[]): boolean => {
  return userRoles && userRoles.length > 0 && !isCashierOnly(userRoles);
};

// ===== TRIP PERMISSIONS =====

/**
 * Cashiers and Super Admins close trips (conductors only start them).
 */
export const canEndTrips = (userRoles: string[]): boolean => {
  return hasRole(userRoles, 'SUPER_ADMIN', 'CASHIER');
};

export const canManageTrips = (userRoles: string[]): boolean => {
  return isDepotAdmin(userRoles);
};

export const canViewTrips = (userRoles: string[]): boolean => {
  return !!(userRoles && userRoles.length > 0);
};

// ===== TICKET PERMISSIONS =====

export const canVoidTickets = (userRoles: string[]): boolean => {
  return isDepotAdmin(userRoles);
};

export const canViewTickets = (userRoles: string[]): boolean => {
  return !!(userRoles && userRoles.length > 0);
};

/**
 * Print ticket batches for a trip (cashier desk + super admin).
 */
export const canPrintTicketBatches = (userRoles: string[]): boolean => {
  return hasRole(userRoles, 'SUPER_ADMIN', 'CASHIER');
};

// ===== METRICS/REPORTS PERMISSIONS =====

export const canViewMetrics = (userRoles: string[]): boolean => {
  return !!(userRoles && userRoles.length > 0);
};

/**
 * True when the user is a cashier without broader admin roles.
 */
export const isCashierOnly = (userRoles: string[]): boolean => {
  if (!userRoles?.length) return false;
  if (hasRole(userRoles, 'SUPER_ADMIN', 'DEPOT_ADMIN', 'MANAGER')) return false;
  return hasRole(userRoles, 'CASHIER');
};

/**
 * Get a human-readable role name for display
 */
export const getRoleDisplayName = (role: string): string => {
  const roleNames: Record<string, string> = {
    SUPER_ADMIN: 'Super Admin',
    DEPOT_ADMIN: 'Depot Admin',
    CASHIER: 'Cashier',
    MANAGER: 'Manager',
    VIEWER: 'Viewer',
  };
  return roleNames[role] || role;
};

/**
 * Get the highest priority role from a list of roles
 */
export const getPrimaryRole = (userRoles: string[]): string | null => {
  if (!userRoles || userRoles.length === 0) return null;

  const rolePriority: Record<string, number> = {
    SUPER_ADMIN: 1,
    DEPOT_ADMIN: 2,
    CASHIER: 3,
    MANAGER: 4,
    VIEWER: 5,
  };

  const sortedRoles = [...userRoles].sort((a, b) => {
    const priorityA = rolePriority[a] || 999;
    const priorityB = rolePriority[b] || 999;
    return priorityA - priorityB;
  });

  return sortedRoles[0] || null;
};

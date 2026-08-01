/**
 * Permission Helper Functions
 *
 * Centralized logic for checking user permissions based on roles.
 * Aligns with backend role-based access control (RBAC).
 *
 * DEVELOPER inherits SUPER_ADMIN privileges and sits above it for
 * platform-only capabilities (e.g. publishing mobile app releases).
 */

export type UserRole =
  | 'DEVELOPER'
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
 * Platform developer — above super admin for release publishing / hidden accounts.
 */
export const isDeveloper = (userRoles: string[]): boolean => {
  return hasRole(userRoles, 'DEVELOPER');
};

/**
 * Super Admin privileges (DEVELOPER inherits these).
 */
export const isSuperAdmin = (userRoles: string[]): boolean => {
  return hasRole(userRoles, 'SUPER_ADMIN', 'DEVELOPER');
};

/**
 * Check if user is a Depot Admin or higher
 */
export const isDepotAdmin = (userRoles: string[]): boolean => {
  return hasRole(userRoles, 'SUPER_ADMIN', 'DEVELOPER', 'DEPOT_ADMIN');
};

/**
 * Check if user is a Cashier (or Super Admin / Developer with cashier privileges)
 */
export const isCashier = (userRoles: string[]): boolean => {
  return hasRole(userRoles, 'SUPER_ADMIN', 'DEVELOPER', 'CASHIER');
};

/**
 * Check if user is a Manager or higher
 */
export const isManager = (userRoles: string[]): boolean => {
  return hasRole(userRoles, 'SUPER_ADMIN', 'DEVELOPER', 'DEPOT_ADMIN', 'MANAGER');
};

// ===== DEPOT PERMISSIONS =====

export const canManageDepots = (userRoles: string[]): boolean => {
  return isSuperAdmin(userRoles);
};

export const canManageAdminUsers = (userRoles: string[]): boolean => {
  return isSuperAdmin(userRoles);
};

/** View / download published mobile app releases. */
export const canViewAppReleases = (userRoles: string[]): boolean => {
  return isSuperAdmin(userRoles);
};

/** Publish / promote / delete mobile app releases (developer only). */
export const canPublishAppReleases = (userRoles: string[]): boolean => {
  return isDeveloper(userRoles);
};

/** @deprecated Prefer canViewAppReleases / canPublishAppReleases */
export const canManageAppReleases = (userRoles: string[]): boolean => {
  return canViewAppReleases(userRoles);
};

// ===== AGENT PERMISSIONS =====

export const canManageAgents = (userRoles: string[]): boolean => {
  return isDepotAdmin(userRoles);
};

/** Cashiers may not open the conductors list. */
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

/** Cashiers may not open the fleets list. */
export const canViewFleets = (userRoles: string[]): boolean => {
  return userRoles && userRoles.length > 0 && !isCashierOnly(userRoles);
};

export const canManageDrivers = (userRoles: string[]): boolean => {
  return isDepotAdmin(userRoles);
};

/** Cashiers may not open the drivers list. */
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
  return hasRole(userRoles, 'SUPER_ADMIN', 'DEVELOPER', 'CASHIER');
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
  return hasRole(userRoles, 'SUPER_ADMIN', 'DEVELOPER', 'CASHIER');
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
  if (hasRole(userRoles, 'SUPER_ADMIN', 'DEVELOPER', 'DEPOT_ADMIN', 'MANAGER')) return false;
  return hasRole(userRoles, 'CASHIER');
};

/**
 * Get a human-readable role name for display
 */
export const getRoleDisplayName = (role: string): string => {
  const roleNames: Record<string, string> = {
    DEVELOPER: 'Developer',
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
    DEVELOPER: 0,
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

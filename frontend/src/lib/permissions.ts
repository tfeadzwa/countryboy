/**
 * Permission Helper Functions
 * 
 * Centralized logic for checking user permissions based on roles.
 * Aligns with backend role-based access control (RBAC).
 */

export type UserRole = 'SUPER_ADMIN' | 'DEPOT_ADMIN' | 'MANAGER' | 'VIEWER';

/**
 * Check if user has any of the specified roles
 */
export const hasRole = (userRoles: string[], ...requiredRoles: string[]): boolean => {
  if (!userRoles || userRoles.length === 0) return false;
  return requiredRoles.some(role => userRoles.includes(role));
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
 * Check if user is a Manager or higher
 */
export const isManager = (userRoles: string[]): boolean => {
  return hasRole(userRoles, 'SUPER_ADMIN', 'DEPOT_ADMIN', 'MANAGER');
};

// ===== DEPOT PERMISSIONS =====

/**
 * Can create or update depots (SUPER_ADMIN only)
 */
export const canManageDepots = (userRoles: string[]): boolean => {
  return isSuperAdmin(userRoles);
};

export const canManageAdminUsers = (userRoles: string[]): boolean => {
  return isSuperAdmin(userRoles);
};

// ===== AGENT PERMISSIONS =====

/**
 * Can create or update agents (DEPOT_ADMIN and above)
 */
export const canManageAgents = (userRoles: string[]): boolean => {
  return isDepotAdmin(userRoles);
};

/**
 * Can view agents (all authenticated users)
 */
export const canViewAgents = (userRoles: string[]): boolean => {
  return userRoles && userRoles.length > 0;
};

// ===== DEVICE PERMISSIONS =====

/**
 * Can register, update, or unpair devices (DEPOT_ADMIN and above)
 */
export const canManageDevices = (userRoles: string[]): boolean => {
  return isDepotAdmin(userRoles);
};

/**
 * Can view devices (all authenticated users)
 */
export const canViewDevices = (userRoles: string[]): boolean => {
  return userRoles && userRoles.length > 0;
};

// ===== FLEET PERMISSIONS =====

/**
 * Can create or update fleets (DEPOT_ADMIN and above)
 */
export const canManageFleets = (userRoles: string[]): boolean => {
  return isDepotAdmin(userRoles);
};

/**
 * Can view fleets (all authenticated users)
 */
export const canViewFleets = (userRoles: string[]): boolean => {
  return userRoles && userRoles.length > 0;
};

// ===== ROUTE PERMISSIONS =====

/**
 * Can create or update routes (DEPOT_ADMIN and above)
 */
export const canManageRoutes = (userRoles: string[]): boolean => {
  return isDepotAdmin(userRoles);
};

/**
 * Can view routes (all authenticated users)
 */
export const canViewRoutes = (userRoles: string[]): boolean => {
  return userRoles && userRoles.length > 0;
};

// ===== FARE PERMISSIONS =====

/**
 * Can create or update fares (DEPOT_ADMIN and above)
 */
export const canManageFares = (userRoles: string[]): boolean => {
  return isDepotAdmin(userRoles);
};

/**
 * Can view fares (all authenticated users)
 */
export const canViewFares = (userRoles: string[]): boolean => {
  return userRoles && userRoles.length > 0;
};

// ===== TRIP PERMISSIONS =====

/**
 * Can start or end trips (DEPOT_ADMIN and above)
 */
export const canManageTrips = (userRoles: string[]): boolean => {
  return isDepotAdmin(userRoles);
};

/**
 * Can view trips (all authenticated users)
 */
export const canViewTrips = (userRoles: string[]): boolean => {
  return userRoles && userRoles.length > 0;
};

// ===== TICKET PERMISSIONS =====

/**
 * Can void tickets (DEPOT_ADMIN and above)
 */
export const canVoidTickets = (userRoles: string[]): boolean => {
  return isDepotAdmin(userRoles);
};

/**
 * Can view tickets (all authenticated users)
 */
export const canViewTickets = (userRoles: string[]): boolean => {
  return userRoles && userRoles.length > 0;
};

// ===== METRICS/REPORTS PERMISSIONS =====

/**
 * Can view metrics and reports (all authenticated users)
 */
export const canViewMetrics = (userRoles: string[]): boolean => {
  return userRoles && userRoles.length > 0;
};

/**
 * Get a human-readable role name for display
 */
export const getRoleDisplayName = (role: string): string => {
  const roleNames: Record<string, string> = {
    'SUPER_ADMIN': 'Super Admin',
    'DEPOT_ADMIN': 'Depot Admin',
    'MANAGER': 'Manager',
    'VIEWER': 'Viewer',
  };
  return roleNames[role] || role;
};

/**
 * Get the highest priority role from a list of roles
 * (for display purposes when user has multiple roles)
 */
export const getPrimaryRole = (userRoles: string[]): string | null => {
  if (!userRoles || userRoles.length === 0) return null;
  
  const rolePriority: Record<string, number> = {
    'SUPER_ADMIN': 1,
    'DEPOT_ADMIN': 2,
    'MANAGER': 3,
    'VIEWER': 4,
  };
  
  // Sort roles by priority and return the highest
  const sortedRoles = [...userRoles].sort((a, b) => {
    const priorityA = rolePriority[a] || 999;
    const priorityB = rolePriority[b] || 999;
    return priorityA - priorityB;
  });
  
  return sortedRoles[0] || null;
};

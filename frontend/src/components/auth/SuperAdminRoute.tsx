import { ReactNode } from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { isSuperAdmin } from '@/lib/permissions';

interface SuperAdminRouteProps {
  children: ReactNode;
}

/**
 * Route guard for SUPER_ADMIN-only pages (e.g. /depots, /admin-users).
 * Authenticated non-super-admin users are redirected to the dashboard
 * instead of seeing a broken page with 403 API errors.
 */
const SuperAdminRoute = ({ children }: SuperAdminRouteProps) => {
  const { user, isLoading } = useAuth();

  if (isLoading) return null;

  if (!user || !isSuperAdmin(user.roles)) {
    return <Navigate to="/" replace />;
  }

  return <>{children}</>;
};

export default SuperAdminRoute;

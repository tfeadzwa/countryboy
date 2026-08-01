import { ReactNode } from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { isCashierOnly } from '@/lib/permissions';

interface DenyCashierRouteProps {
  children: ReactNode;
}

/**
 * Blocks cashier-only users from staff ops pages (conductors, drivers, fleets).
 * Redirects to the dashboard instead of showing a broken/403 page.
 */
const DenyCashierRoute = ({ children }: DenyCashierRouteProps) => {
  const { user, isLoading } = useAuth();

  if (isLoading) return null;

  if (!user || isCashierOnly(user.roles || [])) {
    return <Navigate to="/" replace />;
  }

  return <>{children}</>;
};

export default DenyCashierRoute;

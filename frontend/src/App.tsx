import { lazy, Suspense } from "react";
import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { Loader2 } from "lucide-react";
import { AuthProvider } from "./contexts/AuthContext";
import ProtectedRoute from "./components/auth/ProtectedRoute";
import SuperAdminRoute from "./components/auth/SuperAdminRoute";
import DenyCashierRoute from "./components/auth/DenyCashierRoute";
import AdminLayout from "./components/AdminLayout";

const Dashboard = lazy(() => import("./pages/Dashboard"));
const Depots = lazy(() => import("./pages/Depots"));
const Agents = lazy(() => import("./pages/Agents"));
const Drivers = lazy(() => import("./pages/Drivers"));
const Fleets = lazy(() => import("./pages/Fleets"));
const EditFleetPage = lazy(() => import("./pages/EditFleetPage"));
const EditDriverPage = lazy(() => import("./pages/EditDriverPage"));
const CreateDriverPage = lazy(() => import("./pages/CreateDriverPage"));
const RoutesPage = lazy(() => import("./pages/RoutesPage"));
const RouteDetailPage = lazy(() => import("./pages/RouteDetailPage"));
const Trips = lazy(() => import("./pages/Trips"));
const TripDetailPage = lazy(() => import("./pages/TripDetailPage"));
const Tickets = lazy(() => import("./pages/Tickets"));
const Devices = lazy(() => import("./pages/Devices"));
const Settings = lazy(() => import("./pages/Settings"));
const Notifications = lazy(() => import("./pages/Notifications"));
const Login = lazy(() => import("./pages/Login"));
const ForgotPassword = lazy(() => import("./pages/ForgotPassword"));
const ResetPassword = lazy(() => import("./pages/ResetPassword"));
const VerifyTicket = lazy(() => import("./pages/VerifyTicket"));
const NotFound = lazy(() => import("./pages/NotFound"));
const AdminUsers = lazy(() => import("./pages/AdminUsers"));
const AppReleases = lazy(() => import("./pages/AppReleases"));
const AppReleaseNotesPage = lazy(() => import("./pages/AppReleaseNotesPage"));

const queryClient = new QueryClient();

const PageFallback = () => (
  <div className="flex min-h-[40vh] items-center justify-center text-muted-foreground">
    <Loader2 className="h-5 w-5 animate-spin" />
  </div>
);

const App = () => (
  <QueryClientProvider client={queryClient}>
    <TooltipProvider>
      <Toaster />
      <Sonner />
      <BrowserRouter
        future={{
          v7_startTransition: true,
          v7_relativeSplatPath: true,
        }}
      >
        <AuthProvider>
          <Suspense fallback={<PageFallback />}>
            <Routes>
              <Route path="/login" element={<Login />} />
              <Route path="/forgot-password" element={<ForgotPassword />} />
              <Route path="/reset-password" element={<ResetPassword />} />
              <Route path="/verify/:ticketId" element={<VerifyTicket />} />
              <Route element={<ProtectedRoute><AdminLayout /></ProtectedRoute>}>
                <Route path="/" element={<Dashboard />} />
                <Route path="/depots" element={<SuperAdminRoute><Depots /></SuperAdminRoute>} />
                <Route path="/agents" element={<DenyCashierRoute><Agents /></DenyCashierRoute>} />
                <Route path="/drivers" element={<DenyCashierRoute><Drivers /></DenyCashierRoute>} />
                <Route path="/drivers/new" element={<DenyCashierRoute><CreateDriverPage /></DenyCashierRoute>} />
                <Route path="/drivers/:id/edit" element={<DenyCashierRoute><EditDriverPage /></DenyCashierRoute>} />
                <Route path="/fleets" element={<DenyCashierRoute><Fleets /></DenyCashierRoute>} />
                <Route path="/fleets/:id/edit" element={<DenyCashierRoute><EditFleetPage /></DenyCashierRoute>} />
                <Route path="/routes" element={<RoutesPage />} />
                <Route path="/routes/:id" element={<RouteDetailPage />} />
                <Route path="/routes/:id/edit" element={<Navigate to="/routes" replace />} />
                <Route path="/trips" element={<Trips />} />
                <Route path="/trips/:id" element={<TripDetailPage />} />
                <Route path="/tickets" element={<Tickets />} />
                <Route path="/devices" element={<Devices />} />
                <Route path="/settings" element={<Settings />} />
                <Route path="/notifications" element={<Notifications />} />
                <Route path="/admin-users" element={<SuperAdminRoute><AdminUsers /></SuperAdminRoute>} />
                <Route path="/app-releases" element={<SuperAdminRoute><AppReleases /></SuperAdminRoute>} />
                <Route path="/app-releases/:id/notes" element={<SuperAdminRoute><AppReleaseNotesPage /></SuperAdminRoute>} />
              </Route>
              <Route path="*" element={<NotFound />} />
            </Routes>
          </Suspense>
        </AuthProvider>
      </BrowserRouter>
    </TooltipProvider>
  </QueryClientProvider>
);

export default App;

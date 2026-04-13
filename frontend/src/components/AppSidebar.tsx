import { NavLink, useLocation } from "react-router-dom";
import {
  LayoutDashboard, Building2, Users, Bus, MapPin, Ticket, Route, Smartphone, UserCog,
  LogOut, ChevronsLeft, ChevronsRight, Shield, ShieldCheck, X
} from "lucide-react";
import { useAuth } from "@/contexts/AuthContext";
import { canManageDepots, getPrimaryRole, getRoleDisplayName } from "@/lib/permissions";
import BrandLogo from "@/components/BrandLogo";
import cboyIcon from "@/assets/cboy-icon.svg";

const mainLinks = [
  { to: "/", label: "Dashboard", icon: LayoutDashboard },
  { to: "/depots", label: "Depots", icon: Building2, superOnly: true },
  { to: "/admin-users", label: "Admin Users", icon: UserCog, superOnly: true },
  { to: "/agents", label: "Agents", icon: Users },
  { to: "/fleets", label: "Fleets", icon: Bus },
  { to: "/routes", label: "Routes & Fares", icon: MapPin },
];

const operationLinks = [
  { to: "/trips", label: "Trips", icon: Route },
  { to: "/tickets", label: "Tickets", icon: Ticket },
  { to: "/devices", label: "Devices", icon: Smartphone },
];

const AppSidebar = ({ open = true, onToggle, onClose }: { open?: boolean; onToggle?: () => void; onClose?: () => void }) => {
  const location = useLocation();
  const { user, logout } = useAuth();
  const userRoles = user?.roles || [];
  const isSuperAdmin = canManageDepots(userRoles);
  const isMobileSheet = !!onClose;
  const primaryRole = getPrimaryRole(userRoles);
  const roleDisplay = primaryRole ? getRoleDisplayName(primaryRole) : 'User';

  if (!user) return null;

  const renderLink = (link: typeof mainLinks[0]) => {
    if ('superOnly' in link && link.superOnly && !isSuperAdmin) return null;
    const isActive = location.pathname === link.to;
    return (
      <NavLink
        key={link.to}
        to={link.to}
        title={!open ? link.label : undefined}
        onClick={onClose}
        className={`flex items-center gap-3 px-3 py-2.5 rounded-lg text-[13px] font-medium transition-all duration-150 group ${
          !open ? "justify-center" : ""
        } ${
          isActive
            ? "bg-sidebar-primary text-sidebar-primary-foreground shadow-md shadow-sidebar-primary/20"
            : "text-sidebar-foreground hover:bg-sidebar-accent hover:text-sidebar-primary-foreground"
        }`}
      >
        <link.icon className={`h-[18px] w-[18px] shrink-0 transition-colors ${isActive ? "" : "group-hover:text-sidebar-primary-foreground"}`} />
        {open && <span className="truncate">{link.label}</span>}
      </NavLink>
    );
  };

  return (
    <aside className={`${isMobileSheet ? "h-full" : "fixed left-0 top-0 z-40 h-screen"} bg-sidebar flex flex-col transition-all duration-300 ${
      isMobileSheet ? "w-full" : open ? "w-[260px]" : "w-[60px]"
    }`}>
      {/* Header */}
      <div className={`flex items-center border-b border-sidebar-border ${open || isMobileSheet ? "gap-3 px-4 py-4" : "flex-col gap-2 px-2 py-3"}`}>
        {open || isMobileSheet ? (
          <div className="flex-1 min-w-0">
            <BrandLogo variant="light" height="h-9" showSubtitle subtitle="Admin Console" />
          </div>
        ) : (
          /* Collapsed: show only the horse icon */
          <img
            src={cboyIcon}
            alt="Country Boy"
            className="h-9 w-9 object-contain"
          />
        )}
        {isMobileSheet ? (
          <button
            onClick={onClose}
            className="text-sidebar-foreground/40 hover:text-sidebar-primary-foreground transition-colors p-1.5 rounded-lg hover:bg-sidebar-accent ml-auto"
            title="Close menu"
          >
            <X className="h-4 w-4" />
          </button>
        ) : onToggle && (
          <button
            onClick={onToggle}
            className="text-sidebar-foreground/40 hover:text-sidebar-primary-foreground transition-colors p-1.5 rounded-lg hover:bg-sidebar-accent"
            title={open ? "Collapse sidebar" : "Expand sidebar"}
          >
            {open ? <ChevronsLeft className="h-4 w-4" /> : <ChevronsRight className="h-4 w-4" />}
          </button>
        )}
      </div>

      {/* Navigation */}
      <nav className="flex-1 px-2.5 py-4 space-y-5 overflow-y-auto">
        <div className="space-y-0.5">
          {open && <p className="text-[10px] font-semibold uppercase tracking-widest text-sidebar-foreground/40 px-3 mb-2">Main</p>}
          {mainLinks.map(renderLink)}
        </div>
        <div className="space-y-0.5">
          {open && <p className="text-[10px] font-semibold uppercase tracking-widest text-sidebar-foreground/40 px-3 mb-2">Operations</p>}
          {operationLinks.map(renderLink)}
        </div>
      </nav>

      {/* Footer - User */}
      <div className="px-2.5 py-3 border-t border-sidebar-border">
        <div className={`flex items-center gap-3 px-2 py-2 rounded-lg ${!open && !isMobileSheet && "justify-center px-0"}`}>
          <div className="h-8 w-8 rounded-full bg-gradient-to-br from-sidebar-primary to-accent flex items-center justify-center text-[11px] font-bold text-sidebar-primary-foreground shrink-0 shadow-sm">
            {(user.full_name || user.username).split(" ").map((n: string) => n[0]).join("").toUpperCase().slice(0, 2)}
          </div>
          {open && (
            <div className="flex-1 min-w-0">
              <div className="flex items-center gap-1.5">
                <p className="text-xs font-medium text-sidebar-primary-foreground truncate">{user.full_name || user.username}</p>
                {isSuperAdmin ? (
                  <ShieldCheck className="h-3.5 w-3.5 text-warning shrink-0" />
                ) : (
                  <Shield className="h-3.5 w-3.5 text-sidebar-foreground/50 shrink-0" />
                )}
              </div>
              <p className="text-[10px] text-sidebar-foreground/50 truncate">
                {roleDisplay}
              </p>
            </div>
          )}
          {open && (
            <button 
              className="text-sidebar-foreground/40 hover:text-sidebar-primary-foreground transition-colors p-1 rounded-md hover:bg-sidebar-accent" 
              title="Logout"
              onClick={logout}
            >
              <LogOut className="h-4 w-4" />
            </button>
          )}
        </div>
      </div>
    </aside>
  );
};

export default AppSidebar;

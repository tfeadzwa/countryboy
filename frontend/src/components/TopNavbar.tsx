import { useNavigate } from "react-router-dom";
import { Bell, Settings, LogOut, Search, Menu, Building2 } from "lucide-react";
import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { useAuth } from "@/contexts/AuthContext";
import { isSuperAdmin } from "@/lib/permissions";
import { useState, useEffect } from "react";
import { depotService } from "@/lib/api/depot.service";
import { Depot } from "@/types";

const TopNavbar = ({ onMenuClick }: { onMenuClick?: () => void }) => {
  const navigate = useNavigate();
  const { user, logout } = useAuth();
  const [depots, setDepots] = useState<Depot[]>([]);
  const [selectedDepot, setSelectedDepot] = useState<string>("");
  const userIsSuperAdmin = user ? isSuperAdmin(user.roles) : false;

  // Load depots for SUPER_ADMIN users
  useEffect(() => {
    const loadDepots = async () => {
      if (userIsSuperAdmin) {
        try {
          const depotList = await depotService.getAll();
          setDepots(depotList);
          
          // Load saved depot selection
          const saved = sessionStorage.getItem('selected_depot_id');
          if (saved) {
            setSelectedDepot(saved);
          } else if (depotList.length > 0) {
            // Default to first depot
            setSelectedDepot(depotList[0].id);
            sessionStorage.setItem('selected_depot_id', depotList[0].id);
          }
        } catch (err) {
          console.error('Failed to load depots:', err);
        }
      }
    };
    loadDepots();
  }, [userIsSuperAdmin]);

  const handleDepotChange = (depotId: string) => {
    setSelectedDepot(depotId);
    sessionStorage.setItem('selected_depot_id', depotId);
    // Reload page to refresh data with new depot context
    window.location.reload();
  };

  const handleLogout = () => {
    sessionStorage.removeItem('selected_depot_id');
    logout();
  };

  // Get user initials for avatar
  const getUserInitials = () => {
    if (!user) return "AD";
    if (user.full_name) {
      return user.full_name.split(" ").map(n => n[0]).join("").toUpperCase();
    }
    return user.username.substring(0, 2).toUpperCase();
  };

  return (
    <header className="sticky top-0 z-30 h-14 border-b border-border/60 bg-card/90 backdrop-blur-md flex items-center justify-between px-4 sm:px-6">
      <div className="flex items-center gap-2 flex-1 max-w-md">
        {onMenuClick && (
          <Button variant="ghost" size="icon" className="shrink-0 text-muted-foreground hover:text-foreground" onClick={onMenuClick}>
            <Menu className="h-5 w-5" />
          </Button>
        )}
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground/60" />
          <input
            type="text"
            placeholder="Search…"
            className="h-9 w-full rounded-lg border border-input/60 bg-muted/30 pl-9 pr-4 text-sm text-foreground placeholder:text-muted-foreground/60 focus:outline-none focus:ring-2 focus:ring-ring/30 focus:bg-background transition-colors"
          />
        </div>
      </div>

      <div className="flex items-center gap-2">
        {/* Depot Selector for SUPER_ADMIN */}
        {userIsSuperAdmin && depots.length > 0 && (
          <Select value={selectedDepot} onValueChange={handleDepotChange}>
            <SelectTrigger className="h-9 w-[180px] sm:w-[220px] border-border/60 bg-muted/30 text-sm">
              <div className="flex items-center gap-2">
                <Building2 className="h-4 w-4 text-muted-foreground" />
                <SelectValue placeholder="Select depot" />
              </div>
            </SelectTrigger>
            <SelectContent>
              {depots.map((depot) => (
                <SelectItem key={depot.id} value={depot.id}>
                  <div className="flex flex-col">
                    <span className="font-medium">{depot.name}</span>
                    <span className="text-xs opacity-60">{depot.merchant_code}</span>
                  </div>
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        )}

        <Button variant="ghost" size="icon" className="relative text-muted-foreground hover:text-foreground" onClick={() => navigate("/notifications")}>
          <Bell className="h-4 w-4" />
          <span className="absolute -top-0.5 -right-0.5 h-4 w-4 rounded-full bg-destructive text-[10px] font-bold text-destructive-foreground flex items-center justify-center shadow-sm">3</span>
        </Button>

        <Button variant="ghost" size="icon" className="text-muted-foreground hover:text-foreground hidden sm:inline-flex" onClick={() => navigate("/settings")}>
          <Settings className="h-4 w-4" />
        </Button>

        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" size="icon" className="ml-1">
              <div className="h-7 w-7 rounded-full bg-gradient-to-br from-primary to-accent flex items-center justify-center text-[11px] font-bold text-primary-foreground shadow-sm">
                {getUserInitials()}
              </div>
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="w-52">
            <div className="px-3 py-2.5">
              <p className="text-sm font-medium text-foreground">{user?.full_name || user?.username || "Admin"}</p>
              <p className="text-xs text-muted-foreground">@{user?.username || "admin"}</p>
            </div>
            <DropdownMenuSeparator />
            <DropdownMenuItem onClick={() => navigate("/settings")}>
              <Settings className="mr-2 h-4 w-4" />Settings
            </DropdownMenuItem>
            <DropdownMenuItem onClick={() => navigate("/notifications")}>
              <Bell className="mr-2 h-4 w-4" />Notifications
            </DropdownMenuItem>
            <DropdownMenuSeparator />
            <DropdownMenuItem onClick={handleLogout} className="text-destructive focus:text-destructive">
              <LogOut className="mr-2 h-4 w-4" />Logout
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>
    </header>
  );
};

export default TopNavbar;

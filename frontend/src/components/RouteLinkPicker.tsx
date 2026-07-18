import { useMemo, useState } from "react";
import { Search, X, ArrowRight } from "lucide-react";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import type { RouteInfo } from "@/types";

interface RouteLinkPickerProps {
  label: string;
  description?: string;
  routes: RouteInfo[];
  selectedIds: string[];
  onChange: (ids: string[]) => void;
  excludeRouteId?: string;
  depotId?: string;
  disabled?: boolean;
  emptyMessage?: string;
  searchPlaceholder?: string;
}

const routeLabel = (route: RouteInfo) => `${route.origin} → ${route.destination}`;

const matchesQuery = (route: RouteInfo, query: string) => {
  const fields = [
    route.origin,
    route.destination,
    `${route.origin} ${route.destination}`,
    `${route.origin} -> ${route.destination}`,
    `${route.origin} → ${route.destination}`,
    ...(route.parent_route_labels ?? []),
    ...(route.child_route_labels ?? []),
  ];

  return fields
    .filter(Boolean)
    .some((value) => String(value).toLowerCase().includes(query));
};

const RouteLinkPicker = ({
  label,
  description,
  routes,
  selectedIds,
  onChange,
  excludeRouteId,
  depotId,
  disabled = false,
  emptyMessage = "No routes available to link.",
  searchPlaceholder = "Search routes by origin or destination…",
}: RouteLinkPickerProps) => {
  const [search, setSearch] = useState("");

  const routeById = useMemo(
    () => new Map(routes.map((route) => [route.id, route])),
    [routes],
  );

  const candidates = useMemo(() => {
    return routes.filter((route) => {
      if (excludeRouteId && route.id === excludeRouteId) return false;
      if (depotId && route.depot_id !== depotId) return false;
      return true;
    });
  }, [routes, excludeRouteId, depotId]);

  const filteredCandidates = useMemo(() => {
    const query = search.trim().toLowerCase();
    const available = candidates.filter((route) => !selectedIds.includes(route.id));
    if (!query) return available;
    return available.filter((route) => matchesQuery(route, query));
  }, [candidates, search, selectedIds]);

  const selectedRoutes = selectedIds
    .map((id) => routeById.get(id))
    .filter((route): route is RouteInfo => Boolean(route));

  const addRoute = (routeId: string) => {
    if (selectedIds.includes(routeId)) return;
    onChange([...selectedIds, routeId]);
  };

  const removeRoute = (routeId: string) => {
    onChange(selectedIds.filter((id) => id !== routeId));
  };

  return (
    <div className="space-y-3">
      <div>
        <p className="text-sm font-medium">{label}</p>
        {description && (
          <p className="text-xs text-muted-foreground mt-0.5">{description}</p>
        )}
      </div>

      {selectedRoutes.length > 0 && (
        <div className="flex flex-wrap gap-2 rounded-lg border border-border/70 bg-muted/20 p-3">
          {selectedRoutes.map((route) => (
            <Badge
              key={route.id}
              variant="secondary"
              className="gap-1.5 py-1 pl-2.5 pr-1.5 text-xs font-normal"
            >
              <span>{routeLabel(route)}</span>
              <button
                type="button"
                className="rounded-full p-0.5 hover:bg-background/80"
                onClick={() => removeRoute(route.id)}
                disabled={disabled}
                aria-label={`Remove ${routeLabel(route)}`}
              >
                <X className="h-3 w-3" />
              </button>
            </Badge>
          ))}
        </div>
      )}

      {candidates.length > 0 && (
        <div className="relative">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground pointer-events-none" />
          <Input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder={searchPlaceholder}
            className="pl-9"
            disabled={disabled}
            aria-label={`Search ${label.toLowerCase()}`}
          />
        </div>
      )}

      <div className="max-h-52 overflow-y-auto rounded-lg border border-border divide-y divide-border/60">
        {candidates.length === 0 ? (
          <p className="px-3 py-4 text-xs text-muted-foreground">{emptyMessage}</p>
        ) : filteredCandidates.length === 0 ? (
          <p className="px-3 py-4 text-xs text-muted-foreground">
            {search.trim()
              ? `No routes match “${search.trim()}”.`
              : "All matching routes are already linked."}
          </p>
        ) : (
          filteredCandidates.map((route) => (
            <div
              key={route.id}
              className="flex items-center justify-between gap-3 px-3 py-2.5 hover:bg-muted/30"
            >
              <div className="min-w-0">
                <p className="text-sm font-medium truncate flex items-center gap-1.5">
                  {route.origin}
                  <ArrowRight className="h-3.5 w-3.5 shrink-0 text-muted-foreground" />
                  {route.destination}
                </p>
                {(route.parent_route_labels?.length ?? 0) > 0 && (
                  <p className="text-[11px] text-muted-foreground truncate">
                    Under {route.parent_route_labels!.join(", ")}
                  </p>
                )}
              </div>
              <Button
                type="button"
                size="sm"
                variant="outline"
                className="shrink-0 h-8"
                onClick={() => addRoute(route.id)}
                disabled={disabled}
              >
                Add
              </Button>
            </div>
          ))
        )}
      </div>

      {selectedIds.length > 0 && (
        <p className="text-xs text-muted-foreground">
          {selectedIds.length} route{selectedIds.length === 1 ? "" : "s"} linked
          {search.trim() && filteredCandidates.length > 0
            ? ` · ${filteredCandidates.length} more available`
            : ""}
          .
        </p>
      )}
    </div>
  );
};

export default RouteLinkPicker;

import { useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { motion } from "framer-motion";
import {
  AlertCircle,
  ArrowLeft,
  ArrowRight,
  GitBranch,
  Loader2,
  MapPin,
  Save,
} from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Separator } from "@/components/ui/separator";
import RouteLinkPicker from "@/components/RouteLinkPicker";
import RouteFareFields, { type FareDraft } from "@/components/RouteFareFields";
import ErrorAlert from "@/components/ErrorAlert";
import { useToast } from "@/hooks/use-toast";
import { useAuth } from "@/contexts/AuthContext";
import { isSuperAdmin } from "@/lib/permissions";
import { routeService } from "@/lib/api/route.service";
import { fareService } from "@/lib/api/fare.service";
import { depotService } from "@/lib/api/depot.service";
import type { Depot, Fare, RouteInfo } from "@/types";

const normalizeRouteIds = (ids: string[]) =>
  Array.from(
    new Set(
      ids.filter((value): value is string => {
        if (!value) return false;
        return true;
      }),
    ),
  );

const EditRoutePage = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { user } = useAuth();
  const { toast } = useToast();

  const isSuperAdminUser = user ? isSuperAdmin(user.roles || []) : false;

  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [saveError, setSaveError] = useState<string | null>(null);

  const [route, setRoute] = useState<RouteInfo | null>(null);
  const [allRoutes, setAllRoutes] = useState<RouteInfo[]>([]);
  const [depots, setDepots] = useState<Depot[]>([]);

  const [origin, setOrigin] = useState("");
  const [destination, setDestination] = useState("");
  const [distanceKm, setDistanceKm] = useState("");
  const [isActive, setIsActive] = useState(true);
  const [selectedDepotId, setSelectedDepotId] = useState("");
  const [parentRouteIds, setParentRouteIds] = useState<string[]>([]);
  const [childRouteIds, setChildRouteIds] = useState<string[]>([]);
  const [fares, setFares] = useState<FareDraft[]>([]);
  const [initialFares, setInitialFares] = useState<Fare[]>([]);

  useEffect(() => {
    const load = async () => {
      if (!id) return;
      setLoading(true);
      setLoadError(null);

      try {
        const [routeData, routesData, depotData, allFares] = await Promise.all([
          routeService.getOne(id),
          routeService.getAll(),
          isSuperAdminUser ? depotService.getAll() : Promise.resolve([] as Depot[]),
          fareService.getAll(),
        ]);

        setRoute(routeData);
        setAllRoutes(routesData);
        setDepots(depotData);

        setOrigin(routeData.origin);
        setDestination(routeData.destination);
        setDistanceKm(routeData.distance_km ? String(routeData.distance_km) : "");
        setIsActive(routeData.is_active);
        setSelectedDepotId(routeData.depot_id);
        setParentRouteIds(
          normalizeRouteIds(
            routeData.parent_route_ids?.length
              ? routeData.parent_route_ids
              : routeData.parent_route_id
                ? [routeData.parent_route_id]
                : [],
          ),
        );
        setChildRouteIds(normalizeRouteIds(routeData.child_route_ids ?? []));

        const routeFares = allFares
          .filter((fare) => fare.route_id === routeData.id)
          .sort((a, b) => a.currency.localeCompare(b.currency));
        setInitialFares(routeFares);
        setFares(
          routeFares.length > 0
            ? routeFares.map((fare) => ({
                id: fare.id,
                currency: fare.currency,
                amount: String(fare.amount),
              }))
            : [],
        );
      } catch (err) {
        setLoadError(err instanceof Error ? err.message : "Failed to load route");
      } finally {
        setLoading(false);
      }
    };

    load();
  }, [id, isSuperAdminUser]);

  const handleSave = async () => {
    if (!id) return;
    setSaveError(null);

    if (!origin.trim() || !destination.trim()) {
      setSaveError("Both origin and destination are required");
      return;
    }

    if (isSuperAdminUser && !selectedDepotId) {
      setSaveError("Please select a depot");
      return;
    }

    const sanitizedParentRouteIds = normalizeRouteIds(parentRouteIds);
    const sanitizedChildRouteIds = normalizeRouteIds(childRouteIds);
    if (sanitizedParentRouteIds.includes(id) || sanitizedChildRouteIds.includes(id)) {
      setSaveError("This route cannot be linked to itself. Remove it from parent/child links first.");
      return;
    }
    const overlap = sanitizedParentRouteIds.find((parentId) =>
      sanitizedChildRouteIds.includes(parentId),
    );
    if (overlap) {
      setSaveError("A linked route cannot be both parent and child for the same route.");
      return;
    }

    const fareRows = fares
      .map((fare) => ({
        id: fare.id,
        currency: fare.currency.trim().toUpperCase(),
        amount: parseFloat(fare.amount),
      }))
      .filter((fare) => fare.currency && !Number.isNaN(fare.amount) && fare.amount > 0);

    const currencies = fareRows.map((fare) => fare.currency);
    if (new Set(currencies).size !== currencies.length) {
      setSaveError("Each currency can only be added once per route.");
      return;
    }

    setSaving(true);
    try {
      const depotId = isSuperAdminUser ? selectedDepotId : undefined;
      await routeService.update(
        id,
        {
          origin: origin.trim(),
          destination: destination.trim(),
          parent_route_ids: sanitizedParentRouteIds,
          child_route_ids: sanitizedChildRouteIds,
          is_active: isActive,
          distance_km: distanceKm ? parseFloat(distanceKm) : undefined,
        },
        depotId,
      );

      const fareErrors: string[] = [];
      for (const fare of fareRows) {
        try {
          if (fare.id) {
            const existing = initialFares.find((item) => item.id === fare.id);
            const changed =
              !existing ||
              existing.currency !== fare.currency ||
              Number(existing.amount) !== fare.amount;
            if (changed) {
              await fareService.update(
                fare.id,
                { currency: fare.currency, amount: fare.amount },
                depotId,
              );
            }
          } else {
            await fareService.create(
              { route_id: id, currency: fare.currency, amount: fare.amount },
              depotId,
            );
          }
        } catch (err) {
          const message = err instanceof Error ? err.message : "Failed to save fare";
          fareErrors.push(`${fare.currency}: ${message}`);
        }
      }

      toast({
        title: "Route updated",
        description:
          fareErrors.length > 0
            ? `${origin} → ${destination} saved, but some fares failed: ${fareErrors.join("; ")}`
            : `${origin} → ${destination} saved successfully.`,
      });
      navigate("/routes");
    } catch (err) {
      setSaveError(err instanceof Error ? err.message : "Failed to update route");
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-24">
        <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
      </div>
    );
  }

  if (loadError || !route) {
    return (
      <div className="space-y-4">
        <Button variant="ghost" size="sm" className="gap-2" asChild>
          <Link to="/routes">
            <ArrowLeft className="h-4 w-4" />
            Back to routes
          </Link>
        </Button>
        <ErrorAlert error={loadError ?? "Route not found"} />
      </div>
    );
  }

  const routeTitle = `${origin} → ${destination}`;

  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.25 }}
      className="space-y-6 pb-10"
    >
      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div className="space-y-3">
          <Button variant="ghost" size="sm" className="gap-2 -ml-2" asChild>
            <Link to="/routes">
              <ArrowLeft className="h-4 w-4" />
              Back to routes
            </Link>
          </Button>

          <div className="flex items-start gap-3">
            <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-primary/10">
              <MapPin className="h-6 w-6 text-primary" />
            </div>
            <div>
              <h1 className="text-2xl font-semibold tracking-tight flex items-center gap-2 flex-wrap">
                {routeTitle}
                <Badge
                  variant="outline"
                  className={
                    isActive
                      ? "bg-green-500/10 text-green-700 border-green-500/20"
                      : "bg-gray-500/10 text-gray-700 border-gray-500/20"
                  }
                >
                  {isActive ? "Active" : "Inactive"}
                </Badge>
              </h1>
              <p className="text-sm text-muted-foreground mt-1">
                Manage route details, fares, and linked parent / child routes.
              </p>
            </div>
          </div>
        </div>

        <div className="flex gap-2 sm:pt-8">
          <Button variant="outline" onClick={() => navigate("/routes")} disabled={saving}>
            Cancel
          </Button>
          <Button className="gap-2" onClick={handleSave} disabled={saving}>
            {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
            Save changes
          </Button>
        </div>
      </div>

      {saveError && (
        <Alert variant="destructive">
          <AlertCircle className="h-4 w-4" />
          <AlertDescription>{saveError}</AlertDescription>
        </Alert>
      )}

      <div className="grid gap-6 xl:grid-cols-[minmax(0,1fr)_minmax(0,1.2fr)]">
        <Card className="shadow-sm">
          <CardHeader>
            <CardTitle className="text-base">Route details</CardTitle>
            <CardDescription>Core information for this route.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div className="space-y-1.5">
                <Label htmlFor="edit-origin">Origin</Label>
                <Input
                  id="edit-origin"
                  value={origin}
                  onChange={(e) => setOrigin(e.target.value)}
                  disabled={saving}
                />
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="edit-destination">Destination</Label>
                <Input
                  id="edit-destination"
                  value={destination}
                  onChange={(e) => setDestination(e.target.value)}
                  disabled={saving}
                />
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div className="space-y-1.5">
                <Label htmlFor="edit-distance">Distance (km)</Label>
                <Input
                  id="edit-distance"
                  type="number"
                  step="0.1"
                  min="0"
                  value={distanceKm}
                  onChange={(e) => setDistanceKm(e.target.value)}
                  disabled={saving}
                />
              </div>
              <div className="space-y-1.5">
                <Label>Depot</Label>
                {isSuperAdminUser ? (
                  <Select value={selectedDepotId} onValueChange={setSelectedDepotId} disabled={saving}>
                    <SelectTrigger>
                      <SelectValue placeholder="Select depot" />
                    </SelectTrigger>
                    <SelectContent>
                      {depots.map((depot) => (
                        <SelectItem key={depot.id} value={depot.id}>
                          {depot.name}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                ) : (
                  <Input value={route.depot_name ?? "N/A"} disabled />
                )}
              </div>
            </div>

            <div className="flex items-center gap-2 rounded-lg border border-border/70 bg-muted/20 px-3 py-2.5">
              <Checkbox
                id="edit-active"
                checked={isActive}
                onCheckedChange={(checked) => setIsActive(checked === true)}
                disabled={saving}
              />
              <Label htmlFor="edit-active" className="font-normal cursor-pointer">
                Route is active and available for trips
              </Label>
            </div>

            <RouteFareFields
              fares={fares}
              onChange={setFares}
              disabled={saving}
              canRemove={(fare) => !fare.id}
            />
          </CardContent>
        </Card>

        <Card className="shadow-sm">
          <CardHeader>
            <div className="flex items-center gap-2">
              <GitBranch className="h-4 w-4 text-primary" />
              <CardTitle className="text-base">Route links</CardTitle>
            </div>
            <CardDescription>
              Parent routes are corridors this route belongs under. Child routes are segments linked below it.
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-6">
            <RouteLinkPicker
              label="Parent routes"
              description="Where this route sits in the network (e.g. Masvingo → Beitbridge under Harare → Beitbridge)."
              routes={allRoutes}
              selectedIds={parentRouteIds}
              onChange={setParentRouteIds}
              excludeRouteId={route.id}
              depotId={isSuperAdminUser ? selectedDepotId : route.depot_id}
              disabled={saving}
            />

            <Separator />

            <RouteLinkPicker
              label="Child routes"
              description="Segments that conductors can sell under this route during trips."
              routes={allRoutes}
              selectedIds={childRouteIds}
              onChange={setChildRouteIds}
              excludeRouteId={route.id}
              depotId={isSuperAdminUser ? selectedDepotId : route.depot_id}
              disabled={saving}
            />
          </CardContent>
        </Card>
      </div>

      {(parentRouteIds.length > 0 || childRouteIds.length > 0) && (
        <Card className="shadow-sm border-dashed">
          <CardHeader className="pb-3">
            <CardTitle className="text-sm font-medium">Link preview</CardTitle>
          </CardHeader>
          <CardContent className="text-sm text-muted-foreground space-y-2">
            {parentRouteIds.length > 0 && (
              <p className="flex items-center gap-2 flex-wrap">
                <span className="font-medium text-foreground">Parents:</span>
                {parentRouteIds.map((parentId) => {
                  const parent = allRoutes.find((r) => r.id === parentId);
                  return (
                    <Badge key={parentId} variant="outline">
                      {parent ? `${parent.origin} → ${parent.destination}` : parentId}
                    </Badge>
                  );
                })}
              </p>
            )}
            <p className="flex items-center gap-2 flex-wrap">
              <span className="font-medium text-foreground">This route:</span>
              <Badge>{origin} <ArrowRight className="h-3 w-3 mx-1" /> {destination}</Badge>
            </p>
            {childRouteIds.length > 0 && (
              <p className="flex items-center gap-2 flex-wrap">
                <span className="font-medium text-foreground">Children:</span>
                {childRouteIds.map((childId) => {
                  const child = allRoutes.find((r) => r.id === childId);
                  return (
                    <Badge key={childId} variant="secondary">
                      {child ? `${child.origin} → ${child.destination}` : childId}
                    </Badge>
                  );
                })}
              </p>
            )}
          </CardContent>
        </Card>
      )}
    </motion.div>
  );
};

export default EditRoutePage;

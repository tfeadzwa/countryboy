import prisma from '../utils/prisma';
import { Prisma } from '@prisma/client';

const routeLabel = (route: { origin: string; destination: string }) =>
  `${route.origin} → ${route.destination}`;

const routeInclude = {
  depot: true,
  parentLinks: {
    include: {
      childRoute: {
        select: { id: true, origin: true, destination: true, is_active: true },
      },
    },
  },
  childLinks: {
    include: {
      parentRoute: {
        select: { id: true, origin: true, destination: true, is_active: true },
      },
    },
  },
} satisfies Prisma.tblRoutesInclude;

type RouteWithLinks = Prisma.tblRoutesGetPayload<{ include: typeof routeInclude }>;

type RouteLinkWithChild = {
  childRoute: RouteWithLinks;
};

type RouteLinksClient = {
  findMany: (
    args: Record<string, unknown>,
  ) => Promise<RouteLinkWithChild[] | Array<{ parent_route_id: string }> | Array<{ child_route_id: string }>>;
  deleteMany: (args: {
    where:
      | { child_route_id?: string; parent_route_id?: string }
      | { OR: Array<{ child_route_id?: string; parent_route_id?: string }> };
  }) => Promise<{ count: number }>;
  createMany: (args: {
    data: Array<{
      depot_id: string;
      parent_route_id: string;
      child_route_id: string;
      created_by?: string;
    }>;
  }) => Promise<{ count: number }>;
};

const routeLinks = prisma.tblRouteLinks as unknown as RouteLinksClient;

const normalizeRouteIds = (ids: string[]) =>
  Array.from(new Set(ids.filter((id): id is string => Boolean(id && id.trim()))));

const assertNoParentChildOverlap = (parentRouteIds: string[], childRouteIds: string[]) => {
  const childSet = new Set(childRouteIds);
  const overlap = parentRouteIds.find((parentId) => childSet.has(parentId));
  if (overlap) {
    throw new Error('A linked route cannot be both parent and child for the same route');
  }
};

export const formatRouteRecord = (route: RouteWithLinks) => {
  // childLinks: rows where this route is the child → parentRoute is the parent corridor.
  // parentLinks: rows where this route is the parent → childRoute is the linked segment.
  const parentRoutes = route.childLinks
    .map((link) => link.parentRoute)
    .filter((r) => r.id !== route.id)
    .sort((a, b) => a.origin.localeCompare(b.origin) || a.destination.localeCompare(b.destination));
  const childRoutes = route.parentLinks
    .map((link) => link.childRoute)
    .filter((r) => r.id !== route.id)
    .sort((a, b) => a.origin.localeCompare(b.origin) || a.destination.localeCompare(b.destination));

  return {
    ...route,
    depot_name: route.depot.name,
    parent_route_ids: parentRoutes.map((r) => r.id),
    parent_routes: parentRoutes.map((r) => ({
      id: r.id,
      origin: r.origin,
      destination: r.destination,
      label: routeLabel(r),
      is_active: r.is_active,
    })),
    child_route_ids: childRoutes.map((r) => r.id),
    child_routes: childRoutes.map((r) => ({
      id: r.id,
      origin: r.origin,
      destination: r.destination,
      label: routeLabel(r),
      is_active: r.is_active,
    })),
    parent_route_labels: parentRoutes.map(routeLabel),
    child_route_labels: childRoutes.map(routeLabel),
    // Compatibility fields for older clients.
    parent_route_id: parentRoutes[0]?.id ?? null,
    parent_route_label: parentRoutes[0] ? routeLabel(parentRoutes[0]) : null,
  };
};

const assertNoCycle = async (parentRouteId: string, childRouteId: string) => {
  if (parentRouteId === childRouteId) {
    throw new Error('A route cannot link to itself');
  }

  // BFS upward from the proposed parent: if we reach the child, attaching would form a cycle.
  const queue = [parentRouteId];
  const visited = new Set<string>();

  while (queue.length > 0) {
    const current = queue.shift()!;
    if (visited.has(current)) continue;
    visited.add(current);

    if (current === childRouteId) {
      throw new Error('Linking these routes would create a cycle');
    }

    const parents = (await routeLinks.findMany({
      where: { child_route_id: current },
      select: { parent_route_id: true },
    })) as Array<{ parent_route_id: string }>;

    for (const link of parents) {
      if (!visited.has(link.parent_route_id)) {
        queue.push(link.parent_route_id);
      }
    }
  }
};

const validateParentLinks = async (
  depotId: string,
  routeId: string | null,
  parentRouteIds: string[],
) => {
  const uniqueIds = normalizeRouteIds(parentRouteIds);
  if (uniqueIds.length === 0) return uniqueIds;

  const parents = await prisma.tblRoutes.findMany({
    where: { id: { in: uniqueIds }, depot_id: depotId },
    select: { id: true },
  });
  if (parents.length !== uniqueIds.length) {
    throw new Error('One or more parent routes were not found in this depot');
  }

  for (const parentId of uniqueIds) {
    if (routeId && parentId === routeId) {
      throw new Error('A route cannot link to itself');
    }
    if (routeId) {
      await assertNoCycle(parentId, routeId);
    }
  }

  return uniqueIds;
};

const validateChildLinks = async (
  depotId: string,
  routeId: string,
  childRouteIds: string[],
) => {
  const uniqueIds = normalizeRouteIds(childRouteIds);
  if (uniqueIds.length === 0) return uniqueIds;

  const children = await prisma.tblRoutes.findMany({
    where: { id: { in: uniqueIds }, depot_id: depotId },
    select: { id: true },
  });
  if (children.length !== uniqueIds.length) {
    throw new Error('One or more child routes were not found in this depot');
  }

  for (const childId of uniqueIds) {
    if (childId === routeId) {
      throw new Error('A route cannot link to itself');
    }
    await assertNoCycle(routeId, childId);
  }

  return uniqueIds;
};

const replaceParentLinks = async (
  tx: Prisma.TransactionClient,
  depotId: string,
  routeId: string,
  parentRouteIds: string[],
  createdBy?: string,
) => {
  const txRouteLinks = (tx as unknown as { tblRouteLinks: RouteLinksClient }).tblRouteLinks;

  await txRouteLinks.deleteMany({ where: { child_route_id: routeId } });
  if (parentRouteIds.length === 0) return;

  await txRouteLinks.createMany({
    data: parentRouteIds.map((parentRouteId) => ({
      depot_id: depotId,
      parent_route_id: parentRouteId,
      child_route_id: routeId,
      created_by: createdBy,
    })),
  });
};

const replaceChildLinks = async (
  tx: Prisma.TransactionClient,
  depotId: string,
  routeId: string,
  childRouteIds: string[],
  createdBy?: string,
) => {
  const txRouteLinks = (tx as unknown as { tblRouteLinks: RouteLinksClient }).tblRouteLinks;

  await txRouteLinks.deleteMany({ where: { parent_route_id: routeId } });
  if (childRouteIds.length === 0) return;

  await txRouteLinks.createMany({
    data: childRouteIds.map((childRouteId) => ({
      depot_id: depotId,
      parent_route_id: routeId,
      child_route_id: childRouteId,
      created_by: createdBy,
    })),
  });
};

export const listRoutes = async (
  depotId?: string,
  pagination?: { skip: number; limit: number },
) => {
  const where: Prisma.tblRoutesWhereInput = {};
  if (depotId) where.depot_id = depotId;

  const routes = await prisma.tblRoutes.findMany({
    where,
    include: routeInclude,
    orderBy: [{ origin: 'asc' }, { destination: 'asc' }],
    ...(pagination ? { skip: pagination.skip, take: pagination.limit } : {}),
  });

  return routes.map(formatRouteRecord);
};

export const countRoutes = async (depotId?: string): Promise<number> => {
  const where: Prisma.tblRoutesWhereInput = {};
  if (depotId) where.depot_id = depotId;
  return prisma.tblRoutes.count({ where });
};

export const deleteRoute = async (id: string, depotId?: string): Promise<void> => {
  const route = await prisma.tblRoutes.findFirst({
    where: { id, ...(depotId ? { depot_id: depotId } : {}) },
    include: { _count: { select: { trips: true } } },
  });

  if (!route) {
    throw new Error('Route not found');
  }

  if (route._count.trips > 0) {
    throw new Error('Cannot delete a route with trip history.');
  }

  await prisma.$transaction(async (tx) => {
    const txRouteLinks = (tx as unknown as { tblRouteLinks: RouteLinksClient }).tblRouteLinks;
    await txRouteLinks.deleteMany({
      where: { OR: [{ parent_route_id: id }, { child_route_id: id }] },
    });
    await tx.tblFares.deleteMany({ where: { route_id: id } });
    await tx.tblRoutes.delete({ where: { id } });
  });
};

export const createRoute = async (
  depotId: string,
  data: {
    origin: string;
    destination: string;
    parent_route_ids?: string[];
    parent_route_id?: string;
    child_route_ids?: string[];
    is_active?: boolean;
    distance_km?: number;
  },
  createdBy?: string,
) => {
  const parentRouteIds = await validateParentLinks(
    depotId,
    null,
    data.parent_route_ids ?? (data.parent_route_id ? [data.parent_route_id] : []),
  );
  const childRouteIdsInput = normalizeRouteIds(data.child_route_ids ?? []);
  assertNoParentChildOverlap(parentRouteIds, childRouteIdsInput);

  const {
    parent_route_ids: _parentIds,
    parent_route_id: _parentId,
    child_route_ids: _childIds,
    ...routeData
  } = data;

  const created = await prisma.$transaction(async (tx) => {
    const route = await tx.tblRoutes.create({
      data: { ...routeData, depot_id: depotId, created_by: createdBy },
    });
    const childRouteIds = await validateChildLinks(depotId, route.id, childRouteIdsInput);
    await replaceParentLinks(tx, depotId, route.id, parentRouteIds, createdBy);
    await replaceChildLinks(tx, depotId, route.id, childRouteIds, createdBy);
    return tx.tblRoutes.findUniqueOrThrow({
      where: { id: route.id },
      include: routeInclude,
    });
  });

  return formatRouteRecord(created);
};

export const updateRoute = async (
  id: string,
  data: Partial<{
    origin: string;
    destination: string;
    parent_route_ids?: string[];
    parent_route_id?: string | null;
    child_route_ids?: string[];
    is_active?: boolean;
    distance_km?: number;
  }>,
  updatedBy?: string,
) => {
  const existing = await prisma.tblRoutes.findUnique({
    where: { id },
    select: { id: true, depot_id: true },
  });
  if (!existing) {
    throw new Error('Route not found');
  }

  const shouldUpdateParents =
    data.parent_route_ids !== undefined || data.parent_route_id !== undefined;
  const shouldUpdateChildren = data.child_route_ids !== undefined;

  let parentRouteIds: string[] | undefined;
  if (shouldUpdateParents) {
    parentRouteIds = await validateParentLinks(
      existing.depot_id,
      id,
      data.parent_route_ids ??
        (data.parent_route_id ? [data.parent_route_id] : []),
    );
  }

  let childRouteIds: string[] | undefined;
  if (shouldUpdateChildren) {
    childRouteIds = await validateChildLinks(
      existing.depot_id,
      id,
      data.child_route_ids ?? [],
    );
  }

  const currentParentLinks = (await routeLinks.findMany({
    where: { child_route_id: id },
    select: { parent_route_id: true },
  })) as Array<{ parent_route_id: string }>;

  const currentChildLinks = (await routeLinks.findMany({
    where: { parent_route_id: id },
    select: { child_route_id: true },
  })) as Array<{ child_route_id: string }>;

  const effectiveParentRouteIds =
    parentRouteIds ?? currentParentLinks.map((link) => link.parent_route_id);
  const effectiveChildRouteIds =
    childRouteIds ?? currentChildLinks.map((link) => link.child_route_id);
  assertNoParentChildOverlap(effectiveParentRouteIds, effectiveChildRouteIds);

  const {
    parent_route_ids: _parentIds,
    parent_route_id: _parentId,
    child_route_ids: _childIds,
    ...routeData
  } = data;

  const updated = await prisma.$transaction(async (tx) => {
    await tx.tblRoutes.update({
      where: { id },
      data: { ...routeData, updated_by: updatedBy },
    });

    if (parentRouteIds !== undefined) {
      await replaceParentLinks(tx, existing.depot_id, id, parentRouteIds, updatedBy);
    }

    if (childRouteIds !== undefined) {
      await replaceChildLinks(tx, existing.depot_id, id, childRouteIds, updatedBy);
    }

    return tx.tblRoutes.findUniqueOrThrow({
      where: { id },
      include: routeInclude,
    });
  });

  return formatRouteRecord(updated);
};

export const getRoute = async (id: string) => {
  const route = await prisma.tblRoutes.findUnique({
    where: { id },
    include: routeInclude,
  });

  return route ? formatRouteRecord(route) : null;
};

/** Direct child routes linked under a parent route (for ticket issuance). */
export const listChildRoutes = async (parentRouteId: string, depotId?: string) => {
  const links = (await routeLinks.findMany({
    where: {
      parent_route_id: parentRouteId,
      ...(depotId ? { depot_id: depotId } : {}),
      childRoute: { is_active: true },
    },
    include: {
      childRoute: {
        include: routeInclude,
      },
    },
    orderBy: {
      childRoute: { origin: 'asc' },
    },
  })) as RouteLinkWithChild[];

  return links.map((link) => formatRouteRecord(link.childRoute));
};

const normalizePlace = (value: string) => value.trim().replace(/\s+/g, ' ');

type DbClient = Prisma.TransactionClient | typeof prisma;

/**
 * Find or create a normal route for a depot by origin/destination.
 * Used for trip parent corridors and ticket segment (child) routes.
 */
export const ensureRoute = async (
  depotId: string,
  origin: string,
  destination: string,
  opts?: { createdBy?: string; client?: DbClient },
) => {
  const client = opts?.client ?? prisma;
  const trimmedOrigin = normalizePlace(origin);
  const trimmedDestination = normalizePlace(destination);

  if (trimmedOrigin.length < 2 || trimmedDestination.length < 2) {
    throw new Error('Origin and destination must be at least 2 characters');
  }
  if (trimmedOrigin.toLowerCase() === trimmedDestination.toLowerCase()) {
    throw new Error('Origin and destination must be different');
  }

  return client.tblRoutes.upsert({
    where: {
      depot_id_origin_destination: {
        depot_id: depotId,
        origin: trimmedOrigin,
        destination: trimmedDestination,
      },
    },
    create: {
      depot_id: depotId,
      origin: trimmedOrigin,
      destination: trimmedDestination,
      is_active: true,
      created_by: opts?.createdBy,
    },
    update: {
      is_active: true,
      updated_by: opts?.createdBy,
    },
  });
};

/**
 * Link a child segment under a parent corridor without wiping other links.
 */
export const ensureParentChildLink = async (
  depotId: string,
  parentRouteId: string,
  childRouteId: string,
  opts?: { createdBy?: string; client?: DbClient },
) => {
  if (parentRouteId === childRouteId) return null;

  const client = opts?.client ?? prisma;
  await assertNoCycle(parentRouteId, childRouteId);

  return client.tblRouteLinks.upsert({
    where: {
      parent_route_id_child_route_id: {
        parent_route_id: parentRouteId,
        child_route_id: childRouteId,
      },
    },
    create: {
      depot_id: depotId,
      parent_route_id: parentRouteId,
      child_route_id: childRouteId,
      created_by: opts?.createdBy,
    },
    update: {},
  });
};

/**
 * Ensure trip has a parent corridor route_id, creating the route from trip OD if needed.
 */
export const ensureTripParentRoute = async (
  trip: { id: string; depot_id: string; origin: string; destination: string; route_id: string | null },
  opts?: { createdBy?: string; client?: DbClient },
) => {
  const client = opts?.client ?? prisma;
  if (trip.route_id) return trip.route_id;

  const parent = await ensureRoute(trip.depot_id, trip.origin, trip.destination, opts);
  await client.tblTrips.update({
    where: { id: trip.id },
    data: { route_id: parent.id },
  });
  return parent.id;
};

/**
 * From a ticket segment, ensure child route exists and link under the trip parent corridor.
 */
export const linkTicketSegmentToTrip = async (
  trip: { id: string; depot_id: string; origin: string; destination: string; route_id: string | null },
  departure?: string | null,
  destination?: string | null,
  opts?: { createdBy?: string; client?: DbClient },
) => {
  const dep = departure?.trim();
  const dest = destination?.trim();
  if (!dep || !dest) return null;

  const parentRouteId = await ensureTripParentRoute(trip, opts);
  const child = await ensureRoute(trip.depot_id, dep, dest, opts);
  if (child.id !== parentRouteId) {
    await ensureParentChildLink(trip.depot_id, parentRouteId, child.id, opts);
  }
  return child;
};

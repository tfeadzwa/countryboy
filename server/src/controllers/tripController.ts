import { AuthenticatedRequest } from '../middleware/auth';
import { Response } from 'express';
import * as tripService from '../services/tripService';
import { formatPrismaError } from '../utils/prismaErrors';
import { isSuperAdmin } from '../middleware/rbac';
import { isDeviceOnline } from '../constants/presence';
import prisma from '../utils/prisma';

export const start = async (req: AuthenticatedRequest, res: Response) => {
  const depotId = req.depotId as string;
  const {
    agent_id,
    fleet_id,
    driver_id,
    origin,
    destination,
    route_id,
    device_id,
    started_offline,
    starting_mileage,
    waybill_no,
  } = req.body;

  if (!depotId) {
    return res.status(400).json({
      error: 'Cannot start trip: depot context is missing for this user.'
    });
  }

  try {
    const trip = await tripService.startTrip(depotId, {
      agent_id,
      fleet_id,
      driver_id,
      origin,
      destination,
      route_id,
      device_id,
      started_offline,
      starting_mileage,
      waybill_no,
    });
    res.status(201).json(trip);
  } catch (err) {
    const friendly = formatPrismaError(err, {
      agent_id,
      fleet_id,
      driver_id,
      origin,
      destination,
      route_id,
      device_id,
    });
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    if (err instanceof Error) {
      return res.status(400).json({ error: err.message });
    }
    res.status(400).json({ error: 'Could not start trip', details: err });
  }
};

export const end = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const tripId = req.params.id;
    const forceRequested = Boolean(req.body?.force);
    const closingMileage = req.body?.closing_mileage;

    if (forceRequested && !isSuperAdmin(req)) {
      return res.status(403).json({
        error: 'Only a super admin can force-end a trip while the conductor is offline.',
      });
    }

    const updated = await tripService.endTrip(tripId, req.depotId, {
      force: forceRequested && isSuperAdmin(req),
      closing_mileage: closingMileage,
    });
    const totals = await tripService.getTripTotals(tripId);
    res.json({
      ...updated,
      ticket_count: totals.ticketCount,
      total_revenue: totals.total,
      message: 'Trip ended successfully',
    });
  } catch (err) {
    if (err instanceof Error) {
      if (err.message === 'Trip not found' || err.message === 'Trip not found in this depot') {
        return res.status(404).json({ error: err.message });
      }
      if (
        err.message === 'Trip is already ended' ||
        err.message.startsWith('Cannot end trip while the conductor is offline') ||
        err.message.includes('mileage') ||
        err.message.includes('Waybill')
      ) {
        return res.status(400).json({ error: err.message });
      }
    }
    const friendly = formatPrismaError(err);
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(400).json({ error: 'Could not end trip', details: err });
  }
};

export const listActive = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const trips = await tripService.listActiveTrips(req.depotId);
    res.json(trips);
  } catch (err) {
    res.status(500).json({ error: 'Unable to list active trips', details: err });
  }
};

export const getOne = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const id = req.params.id;
    const trip = await tripService.getTrip(id, req.depotId);
    if (!trip) return res.status(404).json({ error: 'Trip not found' });
    res.json(trip);
  } catch (err) {
    res.status(500).json({ error: 'Error fetching trip', details: err });
  }
};

export const totals = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const id = req.params.id;
    const tot = await tripService.getTripTotals(id);
    res.json(tot);
  } catch (err) {
    res.status(500).json({ error: 'Error fetching totals', details: err });
  }
};

export const list = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const depotId = req.depotId;
    const filters = {
      status: req.query.status as string | undefined,
      agent_id: req.query.agent_id as string | undefined,
      fleet_id: req.query.fleet_id as string | undefined,
      date_from: req.query.date_from as string | undefined,
      date_to: req.query.date_to as string | undefined,
    };

    const trips = await tripService.listTrips(depotId, filters);

    const activeAgentIds = [
      ...new Set(
        trips
          .filter((t) => t.status === 'ACTIVE')
          .map((t) => t.agent_id)
          .filter(Boolean),
      ),
    ];

    const openSessions =
      activeAgentIds.length > 0
        ? await prisma.tblAgentDeviceSessions.findMany({
            where: {
              agent_id: { in: activeAgentIds },
              ended_at: null,
            },
            orderBy: { started_at: 'desc' },
            include: {
              device: { select: { paired: true, last_seen: true } },
            },
          })
        : [];

    const sessionByAgent = new Map<string, (typeof openSessions)[number]>();
    for (const session of openSessions) {
      if (!sessionByAgent.has(session.agent_id)) {
        sessionByAgent.set(session.agent_id, session);
      }
    }

    // Format the response with additional fields for the frontend
    const formattedTrips = trips.map((t) => {
      // Calculate totals from tickets (excluding voided)
      const validTickets = t.tickets.filter((ticket) => ticket.voids.length === 0);
      const ticket_count = validTickets.length;
      const total_revenue = validTickets.reduce(
        (sum, ticket) => sum + Number(ticket.amount),
        0,
      );

      const status = t.status === 'COMPLETED' ? 'ENDED' : t.status;
      let conductor_presence: 'online' | 'offline' | 'signed_out' | null = null;
      let conductor_is_online: boolean | null = null;

      if (status === 'ACTIVE') {
        const session = sessionByAgent.get(t.agent_id);
        const online = isDeviceOnline({
          paired: Boolean(session?.device?.paired),
          lastSeen: session?.device?.last_seen ?? null,
          hasOpenSession: Boolean(session),
        });
        conductor_presence = session ? (online ? 'online' : 'offline') : 'signed_out';
        conductor_is_online = online;
      }

      return {
        id: t.id,
        depot_id: t.depot_id,
        depot_name: t.depot?.name,
        agent_id: t.agent_id,
        agent_name: t.agent?.full_name,
        fleet_id: t.fleet_id,
        fleet_number: t.fleet?.number,
        route_id: t.route_id,
        origin: t.origin,
        destination: t.destination,
        route_label: `${t.origin} → ${t.destination}`,
        status,
        started_at: t.started_at,
        ended_at: t.ended_at,
        started_offline: t.started_offline,
        starting_mileage: t.starting_mileage ?? null,
        waybill_no: t.waybill_no ?? null,
        closing_mileage: t.closing_mileage ?? null,
        ticket_count,
        total_revenue,
        conductor_presence,
        conductor_is_online,
        created_at: t.created_at,
        updated_at: t.updated_at,
      };
    });

    res.json(formattedTrips);
  } catch (err) {
    const friendly = formatPrismaError(err);
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(500).json({ error: 'Failed to list trips', details: err });
  }
};

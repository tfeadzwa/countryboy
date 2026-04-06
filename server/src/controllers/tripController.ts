import { AuthenticatedRequest } from '../middleware/auth';
import { Request, Response } from 'express';
import * as tripService from '../services/tripService';
import { formatPrismaError } from '../utils/prismaErrors';

export const start = async (req: AuthenticatedRequest, res: Response) => {
  const depotId = req.depotId as string;
  const { agent_id, fleet_id, route_id, device_id, started_offline } = req.body;

  if (!depotId) {
    return res.status(400).json({
      error: 'Cannot start trip: depot context is missing for this user.'
    });
  }

  try {
    const trip = await tripService.startTrip(depotId, { agent_id, fleet_id, route_id, device_id, started_offline });
    res.status(201).json(trip);
  } catch (err) {
    const friendly = formatPrismaError(err, { agent_id, fleet_id, route_id, device_id });
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(400).json({ error: 'Could not start trip', details: err });
  }
};

export const end = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const tripId = req.params.id;
    const updated = await tripService.endTrip(tripId);
    res.json(updated);
  } catch (err) {
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
    const trip = await tripService.getTrip(id);
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
    
    // Format the response with additional fields for the frontend
    const formattedTrips = trips.map(t => {
      // Calculate totals from tickets (excluding voided)
      const validTickets = t.tickets.filter(ticket => ticket.voids.length === 0);
      const ticket_count = validTickets.length;
      const total_revenue = validTickets.reduce((sum, ticket) => sum + Number(ticket.amount), 0);

      return {
        id: t.id,
        depot_id: t.depot_id,
        depot_name: t.depot?.name,
        agent_id: t.agent_id,
        agent_name: t.agent?.full_name,
        fleet_id: t.fleet_id,
        fleet_number: t.fleet?.number,
        route_id: t.route_id,
        route_label: t.route ? `${t.route.origin} → ${t.route.destination}` : null,
        status: t.status,
        started_at: t.started_at,
        ended_at: t.ended_at,
        started_offline: t.started_offline,
        ticket_count,
        total_revenue,
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

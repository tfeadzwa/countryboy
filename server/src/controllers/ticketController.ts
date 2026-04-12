import { AuthenticatedRequest } from '../middleware/auth';
import { Request, Response } from 'express';
import * as ticketService from '../services/ticketService';
import { formatPrismaError } from '../utils/prismaErrors';

export const issue = async (req: AuthenticatedRequest, res: Response) => {
  const depotId = req.depotId as string;
  const { trip_id, agent_id, device_id, ticket_category, currency, amount, departure, destination, issued_at, linked_passenger_ticket_id } = req.body;

  if (!depotId) {
    return res.status(400).json({
      error: 'Cannot issue ticket: depot context is missing for this user.'
    });
  }

  try {
    const ticket = await ticketService.issueTicket({
      depot_id: depotId,
      trip_id,
      agent_id,
      device_id,
      ticket_category,
      currency,
      amount,
      departure,
      destination,
      issued_at: issued_at ? new Date(issued_at) : undefined,
      linked_passenger_ticket_id,
    });
    res.status(201).json(ticket);
  } catch (err) {
    const friendly = formatPrismaError(err, { trip_id, agent_id, ticket_category });
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(400).json({ error: 'Could not issue ticket', details: err });
  }
};

export const voidTicket = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { id } = req.params;
    const { reason, agent_id, device_id } = req.body;
    const voidRecord = await ticketService.voidTicket(id, reason, {
      agent_id,
      device_id,
      admin_user_id: req.user?.id,
    });
    res.json(voidRecord);
  } catch (err) {
    const friendly = formatPrismaError(err);
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(400).json({ error: 'Could not void ticket', details: err });
  }
};

export const search = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const query: any = {};
    // Always scope search to the request's depot — DEPOT_ADMIN cannot see other depots' tickets
    if (req.depotId) query.depot_id = req.depotId;
    if (req.query.serial_number) query.serial_number = parseInt(req.query.serial_number as string);
    if (req.query.ticket_id) query.id = req.query.ticket_id;
    if (req.query.trip_id) query.trip_id = req.query.trip_id as string;
    const tickets = await ticketService.searchTickets(query);
    res.json(tickets);
  } catch (err) {
    res.status(500).json({ error: 'Search failed', details: err });
  }
};

export const list = async (req: AuthenticatedRequest, res: Response) => {
  try {
    const depotId = req.depotId;
    const tickets = await ticketService.listTickets(depotId);
    
    // Format the response with additional fields for the frontend
    const formattedTickets = tickets.map(t => ({
      ...t,
      is_voided: t.voids.length > 0,
      agent_name: t.agent.full_name,
      fleet_number: t.trip?.fleet?.number || 'N/A',
      route_label: t.trip?.route ? `${t.trip.route.origin} → ${t.trip.route.destination}` : null,
    }));

    res.json(formattedTickets);
  } catch (err) {
    const friendly = formatPrismaError(err);
    if (friendly) {
      return res.status(friendly.status).json({ error: friendly.message });
    }
    res.status(500).json({ error: 'Failed to list tickets', details: err });
  }
};

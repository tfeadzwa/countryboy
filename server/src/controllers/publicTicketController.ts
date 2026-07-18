import { Request, Response } from 'express';
import * as publicTicketService from '../services/publicTicketService';

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

/**
 * Public ticket verification (QR scan landing).
 * GET /api/public/tickets/:id
 */
export const verifyTicket = async (req: Request, res: Response) => {
  try {
    const id = String(req.params.id || '').trim();
    if (!id || !UUID_RE.test(id)) {
      return res.status(400).json({
        error: 'Invalid ticket reference',
        verified: false,
      });
    }

    const result = await publicTicketService.getPublicTicketVerification(id);
    if (!result) {
      return res.status(404).json({
        error: 'Ticket not found',
        verified: false,
      });
    }

    res.json(result);
  } catch (err) {
    res.status(500).json({
      error: 'Unable to verify ticket',
      verified: false,
      details: err,
    });
  }
};

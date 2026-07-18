import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import * as publicTicketController from '../controllers/publicTicketController';

const router = Router();

const verifyLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 60,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many verification attempts, try again later' },
});

router.get(
  '/tickets/:id',
  verifyLimiter,
  publicTicketController.verifyTicket,
);

export default router;

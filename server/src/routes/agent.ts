import { Router } from 'express';
import { authMiddleware } from '../middleware/auth';
import { depotScopeMiddleware } from '../middleware/depotScope';
import { requireAnyRole } from '../middleware/rbac';
import * as agentController from '../controllers/agentController';
import { validate } from '../middleware/validate';
import { agentSchema } from '../validators/schemas';

const router = Router();

// Public endpoint for agent login (no auth required for mobile app initial login)
router.post('/login', agentController.login);

// Agent management endpoints (admin only)
// anyone authenticated can list, super and depot admins can manage
router.get('/', authMiddleware, depotScopeMiddleware, agentController.list);
router.post('/', authMiddleware, depotScopeMiddleware, requireAnyRole(['SUPER_ADMIN', 'DEPOT_ADMIN']), validate(agentSchema), agentController.create);
router.get('/:id', authMiddleware, depotScopeMiddleware, agentController.getOne);
router.put('/:id', authMiddleware, depotScopeMiddleware, requireAnyRole(['SUPER_ADMIN', 'DEPOT_ADMIN']), agentController.update);
router.post('/:id/reset-pin', authMiddleware, depotScopeMiddleware, requireAnyRole(['SUPER_ADMIN', 'DEPOT_ADMIN']), agentController.resetPin);

// Agent trip management endpoints (mobile app - agents manage their own trips)
// These endpoints allow conductors to start/end trips from their mobile devices
// Authentication required, but no admin role needed - agents control their own trips
router.post('/trips/start', authMiddleware, agentController.startTrip);
router.post('/trips/:id/end', authMiddleware, agentController.endTrip);
router.get('/trips/active', authMiddleware, agentController.getActiveTrip);
router.get('/trips/current', authMiddleware, agentController.getActiveTrip); // Alias for active

// Agent fleet and route creation (mobile app - for on-the-fly data entry)
// Allows agents to add new fleet vehicles and routes when they're not in the system
// Scoped to agent's depot, no admin role required
router.post('/fleets', authMiddleware, depotScopeMiddleware, agentController.createFleet);
router.post('/routes', authMiddleware, depotScopeMiddleware, agentController.createRoute);

export default router;

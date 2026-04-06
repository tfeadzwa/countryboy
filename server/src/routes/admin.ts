import { Router } from 'express';
import { authMiddleware } from '../middleware/auth';
import { depotScopeMiddleware } from '../middleware/depotScope';
import { requireRole } from '../middleware/rbac';
import { 
  overview, 
  revenueTimeseries,
  revenueByCurrency,
  agentPerformance,
  fleetUtilization,
  routePerformance,
  voidRate,
  depotComparison
} from '../controllers/metricsController';

const router = Router();

// metrics endpoints
router.get('/metrics/overview', authMiddleware, depotScopeMiddleware, overview);
router.get('/metrics/revenue-timeseries', authMiddleware, depotScopeMiddleware, revenueTimeseries);
router.get('/metrics/revenue-by-currency', authMiddleware, depotScopeMiddleware, revenueByCurrency);
router.get('/metrics/agent-performance', authMiddleware, depotScopeMiddleware, agentPerformance);
router.get('/metrics/fleet-utilization', authMiddleware, depotScopeMiddleware, fleetUtilization);
router.get('/metrics/route-performance', authMiddleware, depotScopeMiddleware, routePerformance);
router.get('/metrics/void-rate', authMiddleware, depotScopeMiddleware, voidRate);
router.get('/metrics/depot-comparison', authMiddleware, depotScopeMiddleware, depotComparison);

// ... further endpoints will be added later

export default router;

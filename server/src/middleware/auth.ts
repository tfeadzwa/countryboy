import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import prisma from '../utils/prisma';

interface JwtPayload {
  userId?: string;    // For admin users (web portal)
  agentId?: string;   // For agents (mobile app)
  depotId?: string;   // Depot context
  role?: string;      // User role (SUPER_ADMIN, DEPOT_ADMIN, AGENT)
  type: string;       // Token type (access, refresh)
}

export interface AuthenticatedRequest extends Request {
  user?: any;         // Admin user object (for web portal)
  agentId?: string;   // Agent ID (for mobile app)
  depotId?: string;   
  requestId?: string;
  deviceId?: string;
  durationMs?: number;
}

/**
 * Authentication middleware
 * 
 * Handles JWT token validation for both:
 * 1. Admin users (web portal) - tokens contain userId
 * 2. Agents (mobile app) - tokens contain agentId
 * 
 * Token is validated and decoded, then:
 * - For admin tokens: user object is loaded from tblAdminUsers
 * - For agent tokens: agentId is extracted and added to request
 * 
 * Subsequent middlewares/controllers can check:
 * - req.user (if admin user authenticated)
 * - req.agentId (if agent authenticated)
 */
export const authMiddleware = async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  const token = authHeader.split(' ')[1];
  try {
    // Verify and decode JWT token
    const payload = jwt.verify(token, process.env.JWT_SECRET as string) as JwtPayload;

    // Handle admin user tokens (web portal)
    if (payload.userId) {
      const user = await prisma.tblAdminUsers.findUnique({
        where: { id: payload.userId },
        include: { roles: { include: { role: true } } }
      });
      if (!user) {
        return res.status(401).json({ error: 'User not found' });
      }
      req.user = user;
    }
    
    // Handle agent tokens (mobile app)
    else if (payload.agentId) {
      // Verify agent exists and is active
      const agent = await prisma.tblAgents.findUnique({
        where: { id: payload.agentId }
      });
      
      if (!agent) {
        return res.status(401).json({ error: 'Agent not found' });
      }
      
      if (agent.status !== 'ACTIVE') {
        return res.status(403).json({ error: 'Agent account is not active' });
      }
      
      // Add agent ID to request for use in controllers
      req.agentId = payload.agentId;
      req.depotId = agent.depot_id;
    }
    
    // Invalid token format
    else {
      return res.status(401).json({ error: 'Invalid token format' });
    }

    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid token' });
  }
};

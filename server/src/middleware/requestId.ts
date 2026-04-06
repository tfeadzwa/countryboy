import { Request, Response, NextFunction } from 'express';
import { v4 as uuidv4 } from 'uuid';

export const requestIdMiddleware = (req: Request & { requestId?: string }, res: Response, next: NextFunction) => {
  const id = uuidv4().substring(0, 8);
  req.requestId = id;
  res.setHeader('X-Request-Id', id);
  next();
};

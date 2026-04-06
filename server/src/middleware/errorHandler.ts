import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { formatPrismaError } from '../utils/prismaErrors';

export const errorHandler = (err: any, req: Request & { requestId?: string }, res: Response, next: NextFunction) => {
  // check for Prisma known request error and translate
  const prismaFriendly = formatPrismaError(err);
  let code = err.status || (prismaFriendly?.status || 500);
  const response: any = {
    code,
    message: prismaFriendly?.message || err.message || 'Internal server error',
    requestId: req.requestId,
  };

  if (err instanceof ZodError) {
    response.details = err.errors;
    code = 400;
    response.code = code;
  } else if (err.details) {
    response.details = err.details;
  }

  if (process.env.NODE_ENV !== 'production' && err.stack) {
    response.stack = err.stack;
  }

  // log error
  console.error(req.requestId, err);

  res.status(code).json(response);
};

import { AnyZodObject, ZodError } from 'zod';
import { Request, Response, NextFunction } from 'express';

export const validate = (schema: AnyZodObject) => (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = schema.parse({
      body: req.body,
      params: req.params,
      query: req.query,
    });
    req.body = result.body;
    req.params = result.params;
    req.query = result.query;
    next();
  } catch (err) {
    if (err instanceof ZodError) {
      next(err);
    } else {
      next(err);
    }
  }
};

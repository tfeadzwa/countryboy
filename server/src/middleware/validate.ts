import { AnyZodObject, ZodError } from 'zod';
import { Request, Response, NextFunction } from 'express';

export const validate = (schema: AnyZodObject) => (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = schema.parse({
      body: req.body,
      params: req.params,
      query: req.query,
    });
    // Only overwrite request parts the schema actually returned — schemas that
    // only validate `body` leave params/query undefined, which must not wipe Express params.
    if (result.body !== undefined) req.body = result.body;
    if (result.params !== undefined) req.params = result.params;
    if (result.query !== undefined) req.query = result.query;
    next();
  } catch (err) {
    if (err instanceof ZodError) {
      next(err);
    } else {
      next(err);
    }
  }
};

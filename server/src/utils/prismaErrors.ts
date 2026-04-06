import { Prisma } from '@prisma/client';

export function formatPrismaError(err: any, payload?: Record<string, any>) {
  if (err instanceof Prisma.PrismaClientValidationError) {
    return {
      status: 400,
      message: 'Invalid request data. Please check required fields and value formats.'
    };
  }

  if (err instanceof Prisma.PrismaClientKnownRequestError) {
    switch (err.code) {
      case 'P2002': {
        // unique constraint violation
        const fields = ((err.meta?.target as string[]) || []);
        let human = fields.map(f => f.replace(/_/g, ' ')).join(', ');
        human = human.charAt(0).toUpperCase() + human.slice(1);
        let message = `${human} already exists`;
        if (payload) {
          const values = fields
            .map(f => payload[f])
            .filter(v => v !== undefined && v !== null)
            .join(', ');
          if (values) {
            message += `: ${values}`;
          }
        }
        return { status: 409, message, fields };
      }
      case 'P2003': {
        // foreign key constraint failed
        const fields = ((err.meta?.field_name as string[]) || []);
        let human = fields.map(f => f.replace(/_/g, ' ')).join(', ');
        human = human.charAt(0).toUpperCase() + human.slice(1);
        let message = `Foreign key constraint failed on ${human}`;
        if (payload) {
          const values = fields
            .map(f => payload[f])
            .filter(v => v !== undefined && v !== null)
            .join(', ');
          if (values) {
            message += `: ${values}`;
          }
        }
        return { status: 400, message, fields };
      }
      case 'P2025': {
        // record not found during update/delete
        const message = err.message || 'Record not found';
        return { status: 404, message };
      }
      default:
        break;
    }
  }
  return null;
}

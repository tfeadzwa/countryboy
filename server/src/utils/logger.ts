import winston from 'winston';
import fs from 'fs';
import path from 'path';

const { combine, timestamp, printf, json } = winston.format;

const logsDir = path.join(process.cwd(), 'logs');
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir, { recursive: true });
}

const logFormat = printf(({ level, message, timestamp, ...meta }) => {
  // if json format, meta will include context
  return `${timestamp} [${level}] ${message} ${Object.keys(meta).length ? JSON.stringify(meta) : ''}`;
});

const logger = winston.createLogger({
  level: process.env.NODE_ENV === 'production' ? 'info' : 'debug',
  format: process.env.NODE_ENV === 'production' ? json() : combine(timestamp(), logFormat),
  transports: [new winston.transports.Console()],
});

// Dedicated login audit logger for auth troubleshooting and compliance traceability.
export const authLoginLogger = winston.createLogger({
  level: 'info',
  format: combine(timestamp(), logFormat),
  transports: [
    new winston.transports.File({
      filename: path.join(logsDir, 'auth-login.log'),
      maxsize: 5 * 1024 * 1024,
      maxFiles: 5,
    }),
  ],
});

export default logger;

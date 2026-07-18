import express from "express";
import dotenv from "dotenv";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";
import os from "os";
import { json, urlencoded } from "express";
import rateLimit from "express-rate-limit";

import { requestIdMiddleware } from "./middleware/requestId";
import { errorHandler } from "./middleware/errorHandler";
import logger from "./utils/logger";

// route imports
import authRoutes from "./routes/auth";
import syncRoutes from "./routes/sync";
import adminRoutes from "./routes/admin";
import adminUsersRoutes from "./routes/adminUsers";
import depotRoutes from "./routes/depot";
import agentRoutes from "./routes/agent";
import deviceRoutes from "./routes/device";
import fleetRoutes from "./routes/fleet";
import routeRoutes from "./routes/route";
import fareRoutes from "./routes/fare";
import tripRoutes from "./routes/trip";
import ticketRoutes from "./routes/ticket";
import publicRoutes from "./routes/public";
import notificationRoutes from "./routes/notification";

dotenv.config();
const app = express();
const port = Number(process.env.PORT || 3000);
const isProduction = process.env.NODE_ENV === "production";

// Required when behind Nginx so express-rate-limit can use X-Forwarded-For
if (isProduction || process.env.TRUST_PROXY === "1") {
  app.set("trust proxy", 1);
}

function getLocalNetworkAddresses(): string[] {
  const addresses = new Set<string>();
  for (const iface of Object.values(os.networkInterfaces())) {
    if (!iface) continue;
    for (const details of iface) {
      const isIPv4 = details.family === "IPv4" || String(details.family) === "4";
      if (isIPv4 && !details.internal) {
        addresses.add(details.address);
      }
    }
  }
  return [...addresses];
}

// security headers (allow cross-origin reads for public API + SPA verify page)
app.use(
  helmet({
    crossOriginResourcePolicy: { policy: 'cross-origin' },
  }),
);

const allowedOrigins = (process.env.CORS_ORIGINS || "")
  .split(",")
  .map((o) => o.trim())
  .filter((o) => o);

app.use(
  cors({
    origin: allowedOrigins.length
      ? allowedOrigins
      : isProduction
        ? false
        : true,
    credentials: true,
  }),
);

// request id
app.use(requestIdMiddleware);

// parse bodies
app.use(json());
app.use(urlencoded({ extended: true }));

// logging tokens
morgan.token("id", (req: any) => req.requestId);
morgan.token("user", (req: any) => req.user?.id || "-");
morgan.token("depot", (req: any) => req.depotId || "-");
app.use(morgan(
  ":id :remote-addr :method :url :status :res[content-length] - :response-time ms user=:user depot=:depot",
  { stream: { write: (msg) => logger.info(msg.trim()) } }
));

// rate limiting
const loginLimiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 20, message: { error: 'Too many login attempts, try again later' } });
const forgotPasswordLimiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 10, message: { error: 'Too many reset requests, try again later' } });
app.use('/api/auth/login', loginLimiter);
app.use('/api/auth/forgot-password', forgotPasswordLimiter);

// routes with /api prefix
app.use("/api/auth", authRoutes);
app.use("/api/sync", syncRoutes);
app.use("/api/admin", adminRoutes);
app.use("/api/depots", depotRoutes);
app.use("/api/agents", agentRoutes);
app.use("/api/devices", deviceRoutes);
app.use("/api/fleets", fleetRoutes);
app.use("/api/notifications", notificationRoutes);
app.use("/api/routes", routeRoutes);
app.use("/api/fares", fareRoutes);
app.use("/api/trips", tripRoutes);
app.use("/api/tickets", ticketRoutes);
app.use("/api/admin-users", adminUsersRoutes);
app.use("/api/public", publicRoutes);

// health check
app.get("/", (req, res) => res.json({ status: "ok" }));
app.get("/api", (req, res) => res.json({ status: "ok", version: "1.0.0" }));

// error handler
app.use(errorHandler);

// expose app for testing
export default app;

// start server only if this file is executed directly
if (require.main === module) {
  const host = process.env.HOST || '0.0.0.0';
  app.listen(port, host, () => {
    logger.info(`Server listening on ${host}:${port}`);
    logger.info(`Local access: http://localhost:${port}`);

    const networkAddresses = getLocalNetworkAddresses();
    if (networkAddresses.length === 0) {
      logger.info("No external network interfaces detected");
      return;
    }

    for (const address of networkAddresses) {
      logger.info(`Network access: http://${address}:${port}`);
    }
  });
}

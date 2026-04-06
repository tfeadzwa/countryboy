import request from 'supertest';
import jwt from 'jsonwebtoken';
import app from '../src/index';
import prisma from '../src/utils/prisma';

describe('Fare endpoints', () => {
  let token: string;
  let depotId: string;
  let routeId: string;

  beforeAll(async () => {
    const user = await prisma.tblAdminUsers.findFirst({ where: { username: 'super' } });
    const depRole = await prisma.tblRoles.findFirst({ where: { name: 'DEPOT_ADMIN' } });

    if (user && depRole) {
      await prisma.tblUserRoles.upsert({
        where: { userId_roleId: { userId: user.id, roleId: depRole.id } },
        update: {},
        create: { userId: user.id, roleId: depRole.id },
      });
    }

    const depot = await prisma.tblDepots.create({
      data: {
        merchant_code: `FTEST-${Date.now()}`,
        name: 'Fare Test Depot',
      },
    });
    depotId = depot.id;

    await prisma.tblAdminUsers.update({
      where: { username: 'super' },
      data: { depot_id: depotId },
    });

    const route = await prisma.tblRoutes.create({
      data: {
        origin: 'Harare',
        destination: 'Bulawayo',
        depot_id: depotId,
      },
    });
    routeId = route.id;

    const secret = process.env.JWT_SECRET || 'supersecretkey';
    token = jwt.sign({ userId: user?.id, roles: ['SUPER_ADMIN', 'DEPOT_ADMIN'] }, secret, { expiresIn: '1h' });
  });

  afterAll(async () => {
    if (depotId) {
      // Delete in correct order to avoid FK violations
      await prisma.tblTickets.deleteMany({ where: { depot_id: depotId } });
      await prisma.tblTrips.deleteMany({ where: { depot_id: depotId } });
      await prisma.tblFares.deleteMany({ where: { depot_id: depotId } });
      await prisma.tblRoutes.deleteMany({ where: { depot_id: depotId } });
      await prisma.tblFleets.deleteMany({ where: { depot_id: depotId } });
      await prisma.tblDevices.deleteMany({ where: { depot_id: depotId } });
      await prisma.tblAgents.deleteMany({ where: { depot_id: depotId } });
      await prisma.tblDepots.deleteMany({ where: { id: depotId } });
    }
    await prisma.$disconnect();
  });

  it('creates a fare with valid route', async () => {
    const res = await request(app)
      .post('/fares')
      .set('Authorization', `Bearer ${token}`)
      .send({ route_id: routeId, currency: 'USD', amount: 10 });

    expect(res.status).toBe(201);
    expect(res.body.route_id).toBe(routeId);
    expect(res.body.currency).toBe('USD');
  });

  it('returns friendly error for invalid route_id', async () => {
    const res = await request(app)
      .post('/fares')
      .set('Authorization', `Bearer ${token}`)
      .send({ route_id: 'non-existent-route', currency: 'USD', amount: 5 });

    expect(res.status).toBe(400);
    expect(res.body.error).toMatch(/Foreign key constraint failed/i);
  });
});

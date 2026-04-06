import request from 'supertest';
import app from '../src/index';
import prisma from '../src/utils/prisma';

// Note: these tests use the DATABASE_URL from env. Ensure it points to a
// disposable test database; the tests will drop/cleanup data.

describe('Depot endpoints', () => {
  beforeAll(async () => {
    // clear all dependent tables in correct order to avoid FK violations
    await prisma.tblTickets.deleteMany({});
    await prisma.tblTrips.deleteMany({});
    await prisma.tblFares.deleteMany({});
    await prisma.tblRoutes.deleteMany({});
    await prisma.tblFleets.deleteMany({});
    await prisma.tblDevices.deleteMany({});
    await prisma.tblAgents.deleteMany({});
    await prisma.tblDepots.deleteMany({});
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });

  it('returns 409 when creating a depot with duplicate merchant_code', async () => {
    const token = process.env.TEST_SUPER_TOKEN || '';
    if (!token) {
      // we can generate one on the fly using prisma to fetch a super user
      const user = await prisma.tblAdminUsers.findFirst({ where: { username: 'super' } });
      const jwt = require('jsonwebtoken');
      const secret = process.env.JWT_SECRET || 'supersecretkey';
      const generated = jwt.sign({ userId: user?.id, roles: ['SUPER_ADMIN'] }, secret, { expiresIn: '1h' });
      process.env.TEST_SUPER_TOKEN = generated;
    }

    const agent = request(app).post('/auth/login');
    // Instead of calling login we just use token directly

    // create first depot
    const body = { merchant_code: 'DUP01', name: 'First', location: 'Test' };
    const res1 = await request(app)
      .post('/depots')
      .set('Authorization', `Bearer ${process.env.TEST_SUPER_TOKEN}`)
      .send(body);
    expect(res1.status).toBe(201);

    // create duplicate
    const res2 = await request(app)
      .post('/depots')
      .set('Authorization', `Bearer ${process.env.TEST_SUPER_TOKEN}`)
      .send(body);
    expect(res2.status).toBe(409);
    expect(res2.body.error).toMatch(/Merchant code already exists/);
  });
});

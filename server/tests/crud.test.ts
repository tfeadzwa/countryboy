import request from 'supertest';
import app from '../src/index';
import prisma from '../src/utils/prisma';
import jwt from 'jsonwebtoken';

async function getToken() {
  let token = process.env.TEST_SUPER_TOKEN;
  if (!token) {
    const user = await prisma.tblAdminUsers.findFirst({ where: { username: 'super' } });
    const depRole = await prisma.tblRoles.findFirst({ where: { name: 'DEPOT_ADMIN' } });
    if (user && depRole) {
      await prisma.tblUserRoles.upsert({
        where: { userId_roleId: { userId: user.id, roleId: depRole.id } },
        update: {},
        create: { userId: user.id, roleId: depRole.id },
      });
    }
    const secret = process.env.JWT_SECRET || 'supersecretkey';
    token = jwt.sign({ userId: user?.id, roles: ['SUPER_ADMIN', 'DEPOT_ADMIN'] }, secret, { expiresIn: '1h' });
    process.env.TEST_SUPER_TOKEN = token;
  }
  return token;
}

describe('Configuration resource endpoints', () => {
  beforeAll(async () => {
    // clear all tables we will hit
    await prisma.tblAgents.deleteMany({});
    await prisma.tblDevices.deleteMany({});
    await prisma.tblFleets.deleteMany({});
    await prisma.tblRoutes.deleteMany({});
    await prisma.tblDepots.deleteMany({});
    // create a depot just in case, and assign to super user for depotId
    const depot = await prisma.tblDepots.create({ data: { merchant_code: 'TST', name: 'Test' } });
    await prisma.tblAdminUsers.update({ where: { username: 'super' }, data: { depot_id: depot.id } });
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });

  it('should return 409 when creating duplicate agent', async () => {
    const token = await getToken();
    const body = { full_name: 'Alice', username: 'alice', agent_code: 'AG1' };
    const r1 = await request(app).post('/agents').set('Authorization', `Bearer ${token}`).send(body);
    expect(r1.status).toBe(201);
    const r2 = await request(app).post('/agents').set('Authorization', `Bearer ${token}`).send(body);
    expect(r2.status).toBe(409);
    expect(r2.body.error).toMatch(/already exists/i);
  });

  it('should return 409 when creating duplicate device', async () => {
    const token = await getToken();
    const body = { serial_number: 'SN-001' };
    const r1 = await request(app).post('/devices').set('Authorization', `Bearer ${token}`).send(body);
    expect(r1.status).toBe(201);
    const r2 = await request(app).post('/devices').set('Authorization', `Bearer ${token}`).send(body);
    expect(r2.status).toBe(409);
    expect(r2.body.error).toMatch(/Serial number already exists|already exists/);
  });

  it('should return 409 when creating duplicate fleet', async () => {
    const token = await getToken();
    const body = { number: 'FLEET1' };
    const r1 = await request(app).post('/fleets').set('Authorization', `Bearer ${token}`).send(body);
    expect(r1.status).toBe(201);
    const r2 = await request(app).post('/fleets').set('Authorization', `Bearer ${token}`).send(body);
    expect(r2.status).toBe(409);
    expect(r2.body.error).toMatch(/already exists/);
  });

  it('should return 409 when creating duplicate route with same origin/destination', async () => {
    const token = await getToken();
    const body = { origin: 'Harare', destination: 'Bulawayo' };
    const r1 = await request(app).post('/routes').set('Authorization', `Bearer ${token}`).send(body);
    expect(r1.status).toBe(201);
    const r2 = await request(app).post('/routes').set('Authorization', `Bearer ${token}`).send(body);
    expect(r2.status).toBe(409);
    expect(r2.body.error).toMatch(/already exists/);
  });
});

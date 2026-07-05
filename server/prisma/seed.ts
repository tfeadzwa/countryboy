/**
 * Prisma Seed Script
 * Generates proper bcrypt hashes and seeds the database with test data
 * Run with: npm run prisma:seed
 */

import prisma from '../src/utils/prisma';
import bcrypt from '../src/lib/bcrypt';

async function main() {
  console.log('🌱 Starting database seed...\n');

  // Generate proper bcrypt hash for default password
  const defaultPasswordHash = await bcrypt.hash('password123', 10);
  const defaultPinHash = await bcrypt.hash('1234', 10);

  console.log('✅ Generated password hashes');

  // 1. ROLES
  console.log('\n📋 Creating roles...');
  const superAdminRole = await prisma.tblRoles.upsert({
    where: { name: 'SUPER_ADMIN' },
    update: {},
    create: { name: 'SUPER_ADMIN' },
  });
  const depotAdminRole = await prisma.tblRoles.upsert({
    where: { name: 'DEPOT_ADMIN' },
    update: {},
    create: { name: 'DEPOT_ADMIN' },
  });
  const managerRole = await prisma.tblRoles.upsert({
    where: { name: 'MANAGER' },
    update: {},
    create: { name: 'MANAGER' },
  });
  const viewerRole = await prisma.tblRoles.upsert({
    where: { name: 'VIEWER' },
    update: {},
    create: { name: 'VIEWER' },
  });
  console.log(`✅ Created 4 roles`);

  // 2. DEPOTS
  console.log('\n🏢 Creating depots...');
  const depots = await Promise.all([
    prisma.tblDepots.upsert({
      where: { merchant_code: 'HRE001' },
      update: {},
      create: {
        id: 'depot-hre-001',
        merchant_code: 'HRE001',
        name: 'Harare - Roadport',
        location: 'Corner of Rotten Row & 5th St, Harare',
      },
    }),
    prisma.tblDepots.upsert({
      where: { merchant_code: 'BYO001' },
      update: {},
      create: {
        id: 'depot-byo-001',
        merchant_code: 'BYO001',
        name: 'Bulawayo - Renkini',
        location: '6th Avenue & Fife Street, Bulawayo',
      },
    }),
    prisma.tblDepots.upsert({
      where: { merchant_code: 'MUT001' },
      update: {},
      create: {
        id: 'depot-mut-001',
        merchant_code: 'MUT001',
        name: 'Mutare - Sakubva',
        location: 'Herbert Chitepo Street, Mutare',
      },
    }),
  ]);
  console.log(`✅ Created ${depots.length} depots`);

  const depotByCode = Object.fromEntries(depots.map((depot) => [depot.merchant_code, depot.id]));
  const depotId = (merchantCode: string) => {
    const id = depotByCode[merchantCode];
    if (!id) throw new Error(`Missing depot for merchant code ${merchantCode}`);
    return id;
  };

  // 3. ADMIN USERS
  console.log('\n👤 Creating admin users...');
  const adminUsers = await Promise.all([
    prisma.tblAdminUsers.upsert({
      where: { username: 'superadmin' },
      update: {},
      create: {
        id: 'admin-super-001',
        username: 'superadmin',
        email: 'superadmin@countryboy.local',
        password_hash: defaultPasswordHash,
        full_name: 'System Administrator',
        depot_id: null,
        status: 'ACTIVE',
      },
    }),
    prisma.tblAdminUsers.upsert({
      where: { username: 'admin.harare' },
      update: {},
      create: {
        id: 'admin-hre-001',
        username: 'admin.harare',
        email: 'admin.harare@countryboy.co.zw',
        password_hash: defaultPasswordHash,
        full_name: 'John Moyo',
        depot_id: depotId('HRE001'),
        status: 'ACTIVE',
      },
    }),
    prisma.tblAdminUsers.upsert({
      where: { username: 'admin.bulawayo' },
      update: {},
      create: {
        id: 'admin-byo-001',
        username: 'admin.bulawayo',
        email: 'admin.bulawayo@countryboy.co.zw',
        password_hash: defaultPasswordHash,
        full_name: 'Sarah Ncube',
        depot_id: depotId('BYO001'),
        status: 'ACTIVE',
      },
    }),
    prisma.tblAdminUsers.upsert({
      where: { username: 'admin.mutare' },
      update: {},
      create: {
        id: 'admin-mut-001',
        username: 'admin.mutare',
        email: 'admin.mutare@countryboy.co.zw',
        password_hash: defaultPasswordHash,
        full_name: 'Grace Chikwamba',
        depot_id: depotId('MUT001'),
        status: 'ACTIVE',
      },
    }),
    prisma.tblAdminUsers.upsert({
      where: { username: 'manager.harare' },
      update: {},
      create: {
        id: 'manager-hre-001',
        username: 'manager.harare',
        email: 'manager.harare@countryboy.co.zw',
        password_hash: defaultPasswordHash,
        full_name: 'Patrick Sibanda',
        depot_id: depotId('HRE001'),
        status: 'ACTIVE',
      },
    }),
    prisma.tblAdminUsers.upsert({
      where: { username: 'manager.bulawayo' },
      update: {},
      create: {
        id: 'manager-byo-001',
        username: 'manager.bulawayo',
        email: 'manager.bulawayo@countryboy.co.zw',
        password_hash: defaultPasswordHash,
        full_name: 'Alice Dube',
        depot_id: depotId('BYO001'),
        status: 'ACTIVE',
      },
    }),
  ]);
  console.log(`✅ Created ${adminUsers.length} admin users`);

  // 4. USER ROLES MAPPING
  console.log('\n🔐 Mapping user roles...');
  const userRoleMappings = [
    { userId: 'admin-super-001', roleId: superAdminRole.id },
    { userId: 'admin-hre-001', roleId: depotAdminRole.id },
    { userId: 'admin-byo-001', roleId: depotAdminRole.id },
    { userId: 'admin-mut-001', roleId: depotAdminRole.id },
    { userId: 'manager-hre-001', roleId: managerRole.id },
    { userId: 'manager-byo-001', roleId: managerRole.id },
  ];

  for (const mapping of userRoleMappings) {
    await prisma.tblUserRoles.upsert({
      where: { userId_roleId: { userId: mapping.userId, roleId: mapping.roleId } },
      update: {},
      create: mapping,
    });
  }
  console.log('✅ Mapped user roles');

  // 5. AGENTS
  console.log('\n🚍 Creating agents...');
  const agentData = [
    { id: 'agent-hre-001', full_name: 'Tinashe Moyo', agent_code: 'TMO014', merchant_code: 'HRE001', status: 'ACTIVE' },
    { id: 'agent-hre-002', full_name: 'Farai Ncube', agent_code: 'FNC015', merchant_code: 'HRE001', status: 'ACTIVE' },
    { id: 'agent-hre-003', full_name: 'Rumbidzai Chuma', agent_code: 'RCH016', merchant_code: 'HRE001', status: 'ACTIVE' },
    { id: 'agent-hre-004', full_name: 'Tendai Mapfumo', agent_code: 'TMA017', merchant_code: 'HRE001', status: 'INACTIVE' },
    { id: 'agent-byo-001', full_name: 'Nkululeko Dube', agent_code: 'NDU021', merchant_code: 'BYO001', status: 'ACTIVE' },
    { id: 'agent-byo-002', full_name: 'Thandi Ndlovu', agent_code: 'TND022', merchant_code: 'BYO001', status: 'ACTIVE' },
    { id: 'agent-byo-003', full_name: 'Siphosami Moyo', agent_code: 'SMO023', merchant_code: 'BYO001', status: 'ACTIVE' },
    { id: 'agent-mut-001', full_name: 'Patience Marufu', agent_code: 'PMA031', merchant_code: 'MUT001', status: 'ACTIVE' },
    { id: 'agent-mut-002', full_name: 'James Chikwanha', agent_code: 'JCH032', merchant_code: 'MUT001', status: 'ACTIVE' },
  ];

  for (const agent of agentData) {
    const resolvedDepotId = depotId(agent.merchant_code);
    await prisma.tblAgents.upsert({
      where: { depot_id_agent_code: { depot_id: resolvedDepotId, agent_code: agent.agent_code } },
      update: { pin: defaultPinHash, status: agent.status, full_name: agent.full_name },
      create: {
        id: agent.id,
        full_name: agent.full_name,
        agent_code: agent.agent_code,
        depot_id: resolvedDepotId,
        status: agent.status,
        pin: defaultPinHash,
      },
    });
  }
  console.log(`✅ Created ${agentData.length} agents`);

  // 6. DEVICES
  console.log('\n📱 Creating devices...');
  const deviceData = [
    { id: 'device-hre-001', serial_number: 'HRE-DEV-001', token: 'tok-a1b2c3d4-e5f6-4789-a1b2-c3d4e5f67890', pairing_code: null, paired: true, merchant_code: 'HRE001', app_version: '1.0.0' },
    { id: 'device-hre-002', serial_number: 'HRE-DEV-002', token: 'tok-b2c3d4e5-f6a7-4890-b2c3-d4e5f6a78901', pairing_code: null, paired: true, merchant_code: 'HRE001', app_version: '1.0.0' },
    { id: 'device-byo-001', serial_number: 'BYO-DEV-001', token: 'tok-c3d4e5f6-a7b8-4901-c3d4-e5f6a7b89012', pairing_code: null, paired: true, merchant_code: 'BYO001', app_version: '1.0.0' },
    { id: 'device-byo-002', serial_number: 'BYO-DEV-002', token: 'tok-d4e5f6a7-b8c9-4012-d4e5-f6a7b8c90123', pairing_code: null, paired: true, merchant_code: 'BYO001', app_version: '1.0.0' },
    { id: 'device-mut-001', serial_number: 'MUT-DEV-001', token: 'tok-e5f6a7b8-c9d0-4123-e5f6-a7b8c9d01234', pairing_code: null, paired: true, merchant_code: 'MUT001', app_version: '1.0.0' },
    { id: 'device-hre-003', serial_number: 'HRE-DEV-003', token: 'tok-f6a7b8c9-d0e1-4234-f6a7-b8c9d0e12345', pairing_code: 'ABC234', paired: false, merchant_code: 'HRE001', app_version: null },
    { id: 'device-byo-003', serial_number: 'BYO-DEV-003', token: 'tok-a7b8c9d0-e1f2-4345-a7b8-c9d0e1f23456', pairing_code: 'XYZ789', paired: false, merchant_code: 'BYO001', app_version: null },
  ];

  for (const device of deviceData) {
    const resolvedDepotId = depotId(device.merchant_code);
    await prisma.tblDevices.upsert({
      where: { serial_number: device.serial_number },
      update: {
        pairing_code: device.pairing_code,
        paired: device.paired,
        paired_at: device.paired ? new Date() : null,
        token: device.token,
        app_version: device.app_version,
      },
      create: {
        id: device.id,
        serial_number: device.serial_number,
        token: device.token,
        pairing_code: device.pairing_code,
        paired: device.paired,
        depot_id: resolvedDepotId,
        app_version: device.app_version,
        paired_at: device.paired ? new Date() : null,
        last_seen: device.paired ? new Date() : null,
      },
    });
  }
  console.log(`✅ Created ${deviceData.length} devices`);

  // 7. FLEETS
  console.log('\n🚌 Creating fleets...');
  const fleetData = [
    { id: 'fleet-hre-001', number: 'HRE-101', merchant_code: 'HRE001' },
    { id: 'fleet-hre-002', number: 'HRE-102', merchant_code: 'HRE001' },
    { id: 'fleet-hre-003', number: 'HRE-103', merchant_code: 'HRE001' },
    { id: 'fleet-hre-004', number: 'HRE-104', merchant_code: 'HRE001' },
    { id: 'fleet-hre-005', number: 'HRE-105', merchant_code: 'HRE001' },
    { id: 'fleet-byo-001', number: 'BYO-201', merchant_code: 'BYO001' },
    { id: 'fleet-byo-002', number: 'BYO-202', merchant_code: 'BYO001' },
    { id: 'fleet-byo-003', number: 'BYO-203', merchant_code: 'BYO001' },
    { id: 'fleet-byo-004', number: 'BYO-204', merchant_code: 'BYO001' },
    { id: 'fleet-mut-001', number: 'MUT-301', merchant_code: 'MUT001' },
    { id: 'fleet-mut-002', number: 'MUT-302', merchant_code: 'MUT001' },
    { id: 'fleet-mut-003', number: 'MUT-303', merchant_code: 'MUT001' },
  ];

  for (const fleet of fleetData) {
    const resolvedDepotId = depotId(fleet.merchant_code);
    await prisma.tblFleets.upsert({
      where: { depot_id_number: { depot_id: resolvedDepotId, number: fleet.number } },
      update: {},
      create: {
        id: fleet.id,
        number: fleet.number,
        depot_id: resolvedDepotId,
      },
    });
  }
  console.log(`✅ Created ${fleetData.length} fleets`);

  // 8. ROUTES
  console.log('\n🛣️  Creating routes...');
  const routeData = [
    { id: 'route-hre-001', origin: 'Harare', destination: 'Bulawayo', merchant_code: 'HRE001' },
    { id: 'route-hre-002', origin: 'Harare', destination: 'Mutare', merchant_code: 'HRE001' },
    { id: 'route-hre-003', origin: 'Harare', destination: 'Masvingo', merchant_code: 'HRE001' },
    { id: 'route-hre-004', origin: 'Harare', destination: 'Gweru', merchant_code: 'HRE001' },
    { id: 'route-hre-005', origin: 'Harare', destination: 'Chitungwiza', merchant_code: 'HRE001' },
    { id: 'route-byo-001', origin: 'Bulawayo', destination: 'Harare', merchant_code: 'BYO001' },
    { id: 'route-byo-002', origin: 'Bulawayo', destination: 'Victoria Falls', merchant_code: 'BYO001' },
    { id: 'route-byo-003', origin: 'Bulawayo', destination: 'Gwanda', merchant_code: 'BYO001' },
    { id: 'route-byo-004', origin: 'Bulawayo', destination: 'Plumtree', merchant_code: 'BYO001' },
    { id: 'route-mut-001', origin: 'Mutare', destination: 'Harare', merchant_code: 'MUT001' },
    { id: 'route-mut-002', origin: 'Mutare', destination: 'Chimanimani', merchant_code: 'MUT001' },
    { id: 'route-mut-003', origin: 'Mutare', destination: 'Nyanga', merchant_code: 'MUT001' },
  ];

  const routeByKey: Record<string, string> = {};
  for (const route of routeData) {
    const resolvedDepotId = depotId(route.merchant_code);
    const savedRoute = await prisma.tblRoutes.upsert({
      where: {
        depot_id_origin_destination: {
          depot_id: resolvedDepotId,
          origin: route.origin,
          destination: route.destination,
        },
      },
      update: { is_active: true },
      create: {
        id: route.id,
        origin: route.origin,
        destination: route.destination,
        depot_id: resolvedDepotId,
      },
    });
    routeByKey[`${route.merchant_code}:${route.origin}:${route.destination}`] = savedRoute.id;
  }
  console.log(`✅ Created ${routeData.length} routes`);

  // 9. FARES
  console.log('\n💵 Creating fares...');
  const fareData = [
    { merchant_code: 'HRE001', origin: 'Harare', destination: 'Bulawayo', currency: 'USD', amount: 15.00 },
    { merchant_code: 'HRE001', origin: 'Harare', destination: 'Mutare', currency: 'USD', amount: 12.00 },
    { merchant_code: 'HRE001', origin: 'Harare', destination: 'Masvingo', currency: 'USD', amount: 10.00 },
    { merchant_code: 'HRE001', origin: 'Harare', destination: 'Gweru', currency: 'USD', amount: 8.00 },
    { merchant_code: 'HRE001', origin: 'Harare', destination: 'Chitungwiza', currency: 'USD', amount: 2.00 },
    { merchant_code: 'BYO001', origin: 'Bulawayo', destination: 'Harare', currency: 'USD', amount: 15.00 },
    { merchant_code: 'BYO001', origin: 'Bulawayo', destination: 'Victoria Falls', currency: 'USD', amount: 20.00 },
    { merchant_code: 'BYO001', origin: 'Bulawayo', destination: 'Gwanda', currency: 'USD', amount: 7.00 },
    { merchant_code: 'BYO001', origin: 'Bulawayo', destination: 'Plumtree', currency: 'USD', amount: 5.00 },
    { merchant_code: 'MUT001', origin: 'Mutare', destination: 'Harare', currency: 'USD', amount: 12.00 },
    { merchant_code: 'MUT001', origin: 'Mutare', destination: 'Chimanimani', currency: 'USD', amount: 8.00 },
    { merchant_code: 'MUT001', origin: 'Mutare', destination: 'Nyanga', currency: 'USD', amount: 6.00 },
  ];

  let fareCount = 0;
  for (const fare of fareData) {
    const resolvedDepotId = depotId(fare.merchant_code);
    const routeKey = `${fare.merchant_code}:${fare.origin}:${fare.destination}`;
    const routeId = routeByKey[routeKey];
    if (!routeId) continue;

    const existingFare = await prisma.tblFares.findFirst({
      where: {
        route_id: routeId,
        depot_id: resolvedDepotId,
        currency: fare.currency,
      },
    });

    if (!existingFare) {
      await prisma.tblFares.create({
        data: {
          id: `fare-${Math.random().toString(36).slice(2, 11)}`,
          route_id: routeId,
          depot_id: resolvedDepotId,
          currency: fare.currency,
          amount: fare.amount,
        },
      });
      fareCount++;
    }
  }
  console.log(`✅ Created ${fareCount} fares`);

  console.log('\n✨ Seed completed successfully!\n');
  console.log('📊 Summary:');
  console.log(`   - 4 roles`);
  console.log(`   - ${depots.length} depots`);
  console.log(`   - ${adminUsers.length} admin users`);
  console.log(`   - ${agentData.length} agents`);
  console.log(`   - ${deviceData.length} devices`);
  console.log(`   - ${fleetData.length} fleets`);
  console.log(`   - ${routeData.length} routes`);
  console.log(`   - ${fareCount} fares`);
  console.log('\n🔑 Default Credentials:');
  console.log('   - Admin password: password123');
  console.log('   - Agent PIN: 1234');
  console.log('\n📖 See TEST_CREDENTIALS.md for full details\n');
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

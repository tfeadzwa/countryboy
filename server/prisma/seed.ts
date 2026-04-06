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
        depot_id: 'depot-hre-001',
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
        depot_id: 'depot-byo-001',
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
        depot_id: 'depot-mut-001',
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
        depot_id: 'depot-hre-001',
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
        depot_id: 'depot-byo-001',
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
    { id: 'agent-hre-001', full_name: 'Tinashe Moyo', agent_code: 'TMO014', depot_id: 'depot-hre-001', status: 'ACTIVE' },
    { id: 'agent-hre-002', full_name: 'Farai Ncube', agent_code: 'FNC015', depot_id: 'depot-hre-001', status: 'ACTIVE' },
    { id: 'agent-hre-003', full_name: 'Rumbidzai Chuma', agent_code: 'RCH016', depot_id: 'depot-hre-001', status: 'ACTIVE' },
    { id: 'agent-hre-004', full_name: 'Tendai Mapfumo', agent_code: 'TMA017', depot_id: 'depot-hre-001', status: 'INACTIVE' },
    { id: 'agent-byo-001', full_name: 'Nkululeko Dube', agent_code: 'NDU021', depot_id: 'depot-byo-001', status: 'ACTIVE' },
    { id: 'agent-byo-002', full_name: 'Thandi Ndlovu', agent_code: 'TND022', depot_id: 'depot-byo-001', status: 'ACTIVE' },
    { id: 'agent-byo-003', full_name: 'Siphosami Moyo', agent_code: 'SMO023', depot_id: 'depot-byo-001', status: 'ACTIVE' },
    { id: 'agent-mut-001', full_name: 'Patience Marufu', agent_code: 'PMA031', depot_id: 'depot-mut-001', status: 'ACTIVE' },
    { id: 'agent-mut-002', full_name: 'James Chikwanha', agent_code: 'JCH032', depot_id: 'depot-mut-001', status: 'ACTIVE' },
  ];

  for (const agent of agentData) {
    await prisma.tblAgents.upsert({
      where: { depot_id_agent_code: { depot_id: agent.depot_id, agent_code: agent.agent_code } },
      update: {},
      create: { ...agent, pin: defaultPinHash },
    });
  }
  console.log(`✅ Created ${agentData.length} agents`);

  // 6. DEVICES
  console.log('\n📱 Creating devices...');
  const deviceData = [
    { id: 'device-hre-001', serial_number: 'HRE-DEV-001', token: 'tok-a1b2c3d4-e5f6-4789-a1b2-c3d4e5f67890', pairing_code: null, paired: true, depot_id: 'depot-hre-001', app_version: '1.0.0' },
    { id: 'device-hre-002', serial_number: 'HRE-DEV-002', token: 'tok-b2c3d4e5-f6a7-4890-b2c3-d4e5f6a78901', pairing_code: null, paired: true, depot_id: 'depot-hre-001', app_version: '1.0.0' },
    { id: 'device-byo-001', serial_number: 'BYO-DEV-001', token: 'tok-c3d4e5f6-a7b8-4901-c3d4-e5f6a7b89012', pairing_code: null, paired: true, depot_id: 'depot-byo-001', app_version: '1.0.0' },
    { id: 'device-byo-002', serial_number: 'BYO-DEV-002', token: 'tok-d4e5f6a7-b8c9-4012-d4e5-f6a7b8c90123', pairing_code: null, paired: true, depot_id: 'depot-byo-001', app_version: '1.0.0' },
    { id: 'device-mut-001', serial_number: 'MUT-DEV-001', token: 'tok-e5f6a7b8-c9d0-4123-e5f6-a7b8c9d01234', pairing_code: null, paired: true, depot_id: 'depot-mut-001', app_version: '1.0.0' },
    { id: 'device-hre-003', serial_number: 'HRE-DEV-003', token: 'tok-f6a7b8c9-d0e1-4234-f6a7-b8c9d0e12345', pairing_code: 'ABC234', paired: false, depot_id: 'depot-hre-001', app_version: null },
    { id: 'device-byo-003', serial_number: 'BYO-DEV-003', token: 'tok-a7b8c9d0-e1f2-4345-a7b8-c9d0e1f23456', pairing_code: 'XYZ789', paired: false, depot_id: 'depot-byo-001', app_version: null },
  ];

  for (const device of deviceData) {
    await prisma.tblDevices.upsert({
      where: { serial_number: device.serial_number },
      update: {},
      create: {
        ...device,
        paired_at: device.paired ? new Date() : null,
        last_seen: device.paired ? new Date() : null,
      },
    });
  }
  console.log(`✅ Created ${deviceData.length} devices`);

  // 7. FLEETS
  console.log('\n🚌 Creating fleets...');
  const fleetData = [
    { id: 'fleet-hre-001', number: 'HRE-101', depot_id: 'depot-hre-001' },
    { id: 'fleet-hre-002', number: 'HRE-102', depot_id: 'depot-hre-001' },
    { id: 'fleet-hre-003', number: 'HRE-103', depot_id: 'depot-hre-001' },
    { id: 'fleet-hre-004', number: 'HRE-104', depot_id: 'depot-hre-001' },
    { id: 'fleet-hre-005', number: 'HRE-105', depot_id: 'depot-hre-001' },
    { id: 'fleet-byo-001', number: 'BYO-201', depot_id: 'depot-byo-001' },
    { id: 'fleet-byo-002', number: 'BYO-202', depot_id: 'depot-byo-001' },
    { id: 'fleet-byo-003', number: 'BYO-203', depot_id: 'depot-byo-001' },
    { id: 'fleet-byo-004', number: 'BYO-204', depot_id: 'depot-byo-001' },
    { id: 'fleet-mut-001', number: 'MUT-301', depot_id: 'depot-mut-001' },
    { id: 'fleet-mut-002', number: 'MUT-302', depot_id: 'depot-mut-001' },
    { id: 'fleet-mut-003', number: 'MUT-303', depot_id: 'depot-mut-001' },
  ];

  for (const fleet of fleetData) {
    await prisma.tblFleets.upsert({
      where: { depot_id_number: { depot_id: fleet.depot_id, number: fleet.number } },
      update: {},
      create: fleet,
    });
  }
  console.log(`✅ Created ${fleetData.length} fleets`);

  // 8. ROUTES
  console.log('\n🛣️  Creating routes...');
  const routeData = [
    { id: 'route-hre-001', origin: 'Harare', destination: 'Bulawayo', depot_id: 'depot-hre-001' },
    { id: 'route-hre-002', origin: 'Harare', destination: 'Mutare', depot_id: 'depot-hre-001' },
    { id: 'route-hre-003', origin: 'Harare', destination: 'Masvingo', depot_id: 'depot-hre-001' },
    { id: 'route-hre-004', origin: 'Harare', destination: 'Gweru', depot_id: 'depot-hre-001' },
    { id: 'route-hre-005', origin: 'Harare', destination: 'Chitungwiza', depot_id: 'depot-hre-001' },
    { id: 'route-byo-001', origin: 'Bulawayo', destination: 'Harare', depot_id: 'depot-byo-001' },
    { id: 'route-byo-002', origin: 'Bulawayo', destination: 'Victoria Falls', depot_id: 'depot-byo-001' },
    { id: 'route-byo-003', origin: 'Bulawayo', destination: 'Gwanda', depot_id: 'depot-byo-001' },
    { id: 'route-byo-004', origin: 'Bulawayo', destination: 'Plumtree', depot_id: 'depot-byo-001' },
    { id: 'route-mut-001', origin: 'Mutare', destination: 'Harare', depot_id: 'depot-mut-001' },
    { id: 'route-mut-002', origin: 'Mutare', destination: 'Chimanimani', depot_id: 'depot-mut-001' },
    { id: 'route-mut-003', origin: 'Mutare', destination: 'Nyanga', depot_id: 'depot-mut-001' },
  ];

  for (const route of routeData) {
    await prisma.tblRoutes.upsert({
      where: {
        depot_id_origin_destination: {
          depot_id: route.depot_id,
          origin: route.origin,
          destination: route.destination,
        },
      },
      update: {},
      create: route,
    });
  }
  console.log(`✅ Created ${routeData.length} routes`);

  // 9. FARES
  console.log('\n💵 Creating fares...');
  const fareData = [
    { route_id: 'route-hre-001', depot_id: 'depot-hre-001', currency: 'USD', amount: 15.00 },
    { route_id: 'route-hre-002', depot_id: 'depot-hre-001', currency: 'USD', amount: 12.00 },
    { route_id: 'route-hre-003', depot_id: 'depot-hre-001', currency: 'USD', amount: 10.00 },
    { route_id: 'route-hre-004', depot_id: 'depot-hre-001', currency: 'USD', amount: 8.00 },
    { route_id: 'route-hre-005', depot_id: 'depot-hre-001', currency: 'USD', amount: 2.00 },
    { route_id: 'route-byo-001', depot_id: 'depot-byo-001', currency: 'USD', amount: 15.00 },
    { route_id: 'route-byo-002', depot_id: 'depot-byo-001', currency: 'USD', amount: 20.00 },
    { route_id: 'route-byo-003', depot_id: 'depot-byo-001', currency: 'USD', amount: 7.00 },
    { route_id: 'route-byo-004', depot_id: 'depot-byo-001', currency: 'USD', amount: 5.00 },
    { route_id: 'route-mut-001', depot_id: 'depot-mut-001', currency: 'USD', amount: 12.00 },
    { route_id: 'route-mut-002', depot_id: 'depot-mut-001', currency: 'USD', amount: 8.00 },
    { route_id: 'route-mut-003', depot_id: 'depot-mut-001', currency: 'USD', amount: 6.00 },
  ];

  let fareCount = 0;
  for (const fare of fareData) {
    try {
      await prisma.tblFares.create({
        data: { id: `fare-${Math.random().toString(36).substr(2, 9)}`, ...fare },
      });
      fareCount++;
    } catch (e) {
      // Skip if already exists
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

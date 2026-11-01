import {
  BadRequestException,
  INestApplication,
  NotFoundException,
  ValidationPipe,
} from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { PrismaClient, UserRole } from '@prisma/client';
import * as dotenv from 'dotenv';
import * as path from 'path';
import { PrismaModule } from '../../prisma/prisma.module';
import { PrismaService } from '../../prisma/prisma.service';
import { seedCatalog } from '../../prisma/seed-catalog';
import {
  assertCurrentDatabaseIsTest,
  safeCleanupBookingTestTables,
  validateTestDatabaseTarget,
} from '../../prisma/test-database-safety.util';
import { AuthModule } from '../auth/auth.module';
import { AuthService } from '../auth/auth.service';
import { FixoJwtPayload, signFixoJwt } from '../auth/utils/jwt-token.util';
import { CreateAddressDto } from './dto/create-address.dto';
import { UsersController } from './users.controller';
import { UsersModule } from './users.module';
import { UsersService } from './users.service';

// Load .env configuration
dotenv.config({ path: path.resolve(__dirname, '../../../.env') });

/**
 * Real PostgreSQL Integration Test Suite for Phase 3.3A Customer Address Backend.
 *
 * Runs strictly against the dedicated local `fixo_test` database on localhost:5432.
 * Validates:
 * - Fail-closed safety guards (only fixo_test allowed)
 * - Atomic transactional default address switching
 * - Concurrency safety: concurrent default address creations serialize to strictly 1 default
 * - Global ValidationPipe rejects undeclared userId with HTTP 400 Bad Request
 * - Inactive/non-existent zone validation
 * - Client-supplied userId tampering immunity (derived exclusively from JWT)
 * - Compatibility with GET /api/v1/users/me and GET /api/v1/users/me/addresses
 * - Data preservation across customers
 */
describe('Users & Customer Addresses PostgreSQL Real Database Integration Suite (fixo_test)', () => {
  let moduleRef: TestingModule;
  let app: INestApplication;
  let baseUrl: string;
  let prisma: PrismaService;
  let usersService: UsersService;
  let usersController: UsersController;
  let authService: AuthService;
  let testDbUrl: string;

  let customerUserA: any;
  let customerUserB: any;
  let zoneZayed: any;
  let zoneCairo: any;
  let inactiveZone: any;
  let customerTokenA: string;

  beforeAll(async () => {
    // 1. Fail-closed safety validation: target MUST be local fixo_test on port 5432
    testDbUrl =
      process.env.TEST_DATABASE_URL ??
      'postgresql://fixo_user:fixo_dev_password@localhost:5432/fixo_test?schema=public';

    validateTestDatabaseTarget(testDbUrl);

    process.env.TEST_DATABASE_URL = testDbUrl;
    process.env.DATABASE_URL = testDbUrl;
    process.env.FIXO_TEST_FORCE_PRISMA = 'true';
    process.env.ALLOW_IN_MEMORY_FALLBACK = 'false';

    moduleRef = await Test.createTestingModule({
      imports: [PrismaModule, AuthModule, UsersModule],
    }).compile();

    app = moduleRef.createNestApplication();
    app.setGlobalPrefix('api/v1');
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );

    await app.listen(0);
    const address = app.getHttpServer().address();
    const port = typeof address === 'string' ? address : address.port;
    baseUrl = `http://127.0.0.1:${port}/api/v1`;

    prisma = moduleRef.get(PrismaService);
    usersService = moduleRef.get(UsersService);
    usersController = moduleRef.get(UsersController);
    authService = moduleRef.get(AuthService);

    // Verify real PostgreSQL connection was established
    expect(prisma.isDatabaseConnected()).toBe(true);
    expect(prisma.getStorageMode()).toBe('POSTGRESQL_PRISMA');

    // Fail-closed verification: runtime database must report fixo_test
    await assertCurrentDatabaseIsTest(prisma);

    // Clean up test tables and seed catalog
    await safeCleanupBookingTestTables(prisma, { testDatabaseUrl: testDbUrl });
    await seedCatalog(prisma as unknown as PrismaClient);

    // Verify seeded zones
    zoneZayed = await prisma.coverageZone.findFirst({
      where: { slug: 'sheikh-zayed' },
    });
    expect(zoneZayed).toBeDefined();

    zoneCairo = await prisma.coverageZone.findFirst({
      where: { slug: 'new-cairo' },
    });
    expect(zoneCairo).toBeDefined();

    // Create or update an inactive coverage zone for negative test verification
    inactiveZone = await prisma.coverageZone.upsert({
      where: { slug: 'inactive-test-zone' },
      update: { isActive: false },
      create: {
        slug: 'inactive-test-zone',
        nameEn: 'Inactive Test Zone',
        nameAr: 'منطقة اختبار غير مفعلة',
        governorate: 'Cairo',
        isActive: false,
      },
    });

    // Create Customer User A
    customerUserA = await prisma.user.create({
      data: {
        phone: '+201011119991',
        fullName: 'Salma El-Shazly',
        role: UserRole.CUSTOMER,
      },
    });

    // Create Customer User B (to test cross-customer isolation)
    customerUserB = await prisma.user.create({
      data: {
        phone: '+201022229992',
        fullName: 'Karim Fahmy',
        role: UserRole.CUSTOMER,
      },
    });

    // Sign valid JWT for Customer A using AuthService active secret
    customerTokenA = signFixoJwt(
      {
        sub: customerUserA.id,
        phone: customerUserA.phone,
        role: UserRole.CUSTOMER,
        type: 'access',
      },
      authService['accessSecret'],
      900,
    ).token;
  });

  afterAll(async () => {
    if (prisma && prisma.isDatabaseConnected()) {
      await safeCleanupBookingTestTables(prisma, { testDatabaseUrl: testDbUrl });
      await prisma.coverageZone.deleteMany({
        where: { slug: 'inactive-test-zone' },
      });
    }
    if (app) {
      await app.close();
    }
  });

  describe('Database Safety & Configuration', () => {
    it('strictly verifies connected runtime database is fixo_test', async () => {
      const currentDb = await assertCurrentDatabaseIsTest(prisma);
      expect(currentDb).toBe('fixo_test');
    });

    it('rejects unsafe non-fixo_test connection targets', () => {
      expect(() =>
        validateTestDatabaseTarget(
          'postgresql://fixo_user:secret@localhost:5432/fixo_dev',
        ),
      ).toThrow(/Refusing to target database "fixo_dev"/);

      expect(() =>
        validateTestDatabaseTarget(
          'postgresql://fixo_user:secret@remote-host.com:5432/fixo_test',
        ),
      ).toThrow(/Unsafe test database host/);
    });
  });

  describe('POST /api/v1/users/me/addresses — Real DB Persistence', () => {
    it('persists a new customer address in PostgreSQL linked to User and CoverageZone', async () => {
      const dto: CreateAddressDto = {
        zoneId: zoneZayed.id,
        label: 'Palm Hills Villa 14',
        buildingLine: 'Apartment 4B, Building 14',
        districtLine: 'Palm Hills, Sheikh Zayed, Giza',
        gateNotes: 'Gate 3 pre-cleared with security',
        latitude: 30.0131,
        longitude: 30.9854,
        isDefault: true,
      };

      const result = await usersService.createAddress(customerUserA.id, dto);

      expect(result.id).toBeDefined();
      expect(result.userId).toBe(customerUserA.id);
      expect(result.zoneId).toBe(zoneZayed.id);
      expect(result.label).toBe('Palm Hills Villa 14');
      expect(result.buildingLine).toBe('Apartment 4B, Building 14');
      expect(result.districtLine).toBe('Palm Hills, Sheikh Zayed, Giza');
      expect(result.gateNotes).toBe('Gate 3 pre-cleared with security');
      expect(result.latitude).toBeCloseTo(30.0131);
      expect(result.longitude).toBeCloseTo(30.9854);
      expect(result.isDefault).toBe(true);
      expect(result.zone?.slug).toBe('sheikh-zayed');

      // Verify direct PostgreSQL persistence
      const dbRow = await prisma.customerAddress.findUnique({
        where: { id: result.id },
        include: { zone: true, user: true },
      });
      expect(dbRow).not.toBeNull();
      expect(dbRow!.userId).toBe(customerUserA.id);
      expect(dbRow!.user.phone).toBe('+201011119991');
      expect(dbRow!.zone.nameEn).toBe('Sheikh Zayed, Dist. 9');
    });

    it('resolves coverage zone by slug as well as UUID', async () => {
      const dto: CreateAddressDto = {
        zoneId: 'new-cairo', // slug
        label: 'Work Office',
        buildingLine: 'Building 200, 3rd Floor',
        districtLine: 'Sector 1, New Cairo, Cairo',
        isDefault: false,
      };

      const result = await usersService.createAddress(customerUserA.id, dto);
      expect(result.zoneId).toBe(zoneCairo.id);
      expect(result.zone?.slug).toBe('new-cairo');
    });

    it('rejects address creation when coverage zone does not exist (HTTP 404)', async () => {
      const dto: CreateAddressDto = {
        zoneId: '00000000-0000-0000-0000-000000000099',
        label: 'Unknown Zone Address',
        buildingLine: '123 Fake Street',
        districtLine: 'Nowhere, Egypt',
      };

      await expect(
        usersService.createAddress(customerUserA.id, dto),
      ).rejects.toThrow(NotFoundException);
    });

    it('rejects address creation when coverage zone is inactive (HTTP 400)', async () => {
      const dto: CreateAddressDto = {
        zoneId: inactiveZone.id,
        label: 'Inactive Zone Place',
        buildingLine: 'Bldg 5',
        districtLine: 'Inactive District',
      };

      await expect(
        usersService.createAddress(customerUserA.id, dto),
      ).rejects.toThrow(BadRequestException);
    });

    it('rejects address creation when label or lines are empty or whitespace only (HTTP 400)', async () => {
      await expect(
        usersService.createAddress(customerUserA.id, {
          zoneId: zoneZayed.id,
          label: '   ',
          buildingLine: 'Bldg 1',
          districtLine: 'Dist 1',
        }),
      ).rejects.toThrow(BadRequestException);

      await expect(
        usersService.createAddress(customerUserA.id, {
          zoneId: zoneZayed.id,
          label: 'Home',
          buildingLine: '   ',
          districtLine: 'Dist 1',
        }),
      ).rejects.toThrow(BadRequestException);

      await expect(
        usersService.createAddress(customerUserA.id, {
          zoneId: zoneZayed.id,
          label: 'Home',
          buildingLine: 'Bldg 1',
          districtLine: '   ',
        }),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('Atomic Default Address Transaction & Multi-Customer Isolation', () => {
    it('clears previous default address for Customer A when setting a new default in a transaction', async () => {
      // Step 1: Customer A adds Address 1 as default
      const addr1 = await usersService.createAddress(customerUserA.id, {
        zoneId: zoneZayed.id,
        label: 'A - First Home',
        buildingLine: 'Apt 1',
        districtLine: 'Dist 1',
        isDefault: true,
      });
      expect(addr1.isDefault).toBe(true);

      // Step 2: Customer B adds their own default address
      const addrB = await usersService.createAddress(customerUserB.id, {
        zoneId: zoneCairo.id,
        label: 'B - Karims Villa',
        buildingLine: 'Villa 9',
        districtLine: 'New Cairo',
        isDefault: true,
      });
      expect(addrB.isDefault).toBe(true);

      // Step 3: Customer A adds Address 2 as new default
      const addr2 = await usersService.createAddress(customerUserA.id, {
        zoneId: zoneZayed.id,
        label: 'A - Summer House',
        buildingLine: 'Villa 22',
        districtLine: 'Zayed',
        isDefault: true,
      });
      expect(addr2.isDefault).toBe(true);

      // Verify in DB that addr1 for Customer A was updated to isDefault = false
      const addr1Reloaded = await prisma.customerAddress.findUnique({
        where: { id: addr1.id },
      });
      expect(addr1Reloaded!.isDefault).toBe(false);

      // Verify in DB that Customer B's default address remained untouched (isolation invariant)
      const addrBReloaded = await prisma.customerAddress.findUnique({
        where: { id: addrB.id },
      });
      expect(addrBReloaded!.isDefault).toBe(true);
      expect(addrBReloaded!.userId).toBe(customerUserB.id);
    });

    it('preserves existing default address when creating a non-default address (isDefault: false)', async () => {
      // Customer A adds a non-default address
      const nonDefaultAddr = await usersService.createAddress(
        customerUserA.id,
        {
          zoneId: zoneCairo.id,
          label: 'A - Parent House',
          buildingLine: 'Apt 5',
          districtLine: 'Maadi',
          isDefault: false,
        },
      );
      expect(nonDefaultAddr.isDefault).toBe(false);

      // Find Customer A's addresses
      const userAAddresses = await usersService.findUserAddresses(
        customerUserA.id,
      );
      const defaultAddresses = userAAddresses.filter((a) => a.isDefault);

      // Strictly 1 default address must exist
      expect(defaultAddresses).toHaveLength(1);
      expect(defaultAddresses[0].label).toBe('A - Summer House');
    });

    it('handles concurrent requests creating default addresses for the same customer, resulting in strictly ONE default address', async () => {
      // Trigger 2 concurrent address creations with isDefault: true for customerUserA
      const p1 = usersService.createAddress(customerUserA.id, {
        zoneId: zoneZayed.id,
        label: 'Concurrent Address 1',
        buildingLine: 'Bldg 101',
        districtLine: 'Sheikh Zayed, Giza',
        isDefault: true,
      });
      const p2 = usersService.createAddress(customerUserA.id, {
        zoneId: zoneCairo.id,
        label: 'Concurrent Address 2',
        buildingLine: 'Bldg 202',
        districtLine: 'New Cairo, Cairo',
        isDefault: true,
      });

      const [res1, res2] = await Promise.all([p1, p2]);

      expect(res1.id).toBeDefined();
      expect(res2.id).toBeDefined();

      // Query real PostgreSQL database for all default addresses of Customer A
      const defaultAddresses = await prisma.customerAddress.findMany({
        where: {
          userId: customerUserA.id,
          isDefault: true,
        },
      });

      // Concurrency Invariant: exactly 1 default address must exist
      expect(defaultAddresses).toHaveLength(1);
      expect([res1.id, res2.id]).toContain(defaultAddresses[0].id);

      // The other address must have been updated to isDefault = false
      const nonDefaultAddresses = await prisma.customerAddress.findMany({
        where: {
          id: { in: [res1.id, res2.id] },
          isDefault: false,
        },
      });
      expect(nonDefaultAddresses).toHaveLength(1);
    });
  });

  describe('Security & Controller Endpoints', () => {
    it('HTTP POST /api/v1/users/me/addresses rejects client-supplied undeclared userId with HTTP 400 Bad Request via ValidationPipe', async () => {
      const response = await fetch(`${baseUrl}/users/me/addresses`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${customerTokenA}`,
        },
        body: JSON.stringify({
          userId: customerUserB.id, // Undeclared rogue property
          zoneId: zoneZayed.id,
          label: 'Attacker Body Payload',
          buildingLine: 'Bldg 999',
          districtLine: 'Sheikh Zayed, Giza',
          isDefault: false,
        }),
      });

      expect(response.status).toBe(400);
      const data = (await response.json()) as Record<string, any>;
      expect(data.statusCode).toBe(400);
      expect(data.message).toEqual(
        expect.arrayContaining([
          expect.stringContaining('property userId should not exist'),
        ]),
      );

      // Verify that no address was created with the rogue label
      const rogueDbRow = await prisma.customerAddress.findFirst({
        where: { label: 'Attacker Body Payload' },
      });
      expect(rogueDbRow).toBeNull();
    });

    it('HTTP POST /api/v1/users/me/addresses accepts valid payload and derives userId exclusively from JWT Bearer token', async () => {
      const response = await fetch(`${baseUrl}/users/me/addresses`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${customerTokenA}`,
        },
        body: JSON.stringify({
          zoneId: zoneZayed.id,
          label: 'Authentic HTTP Address',
          buildingLine: 'Apartment 7A',
          districtLine: 'Sheikh Zayed, Giza',
          isDefault: false,
        }),
      });

      expect(response.status).toBe(201);
      const data = (await response.json()) as Record<string, any>;
      expect(data.id).toBeDefined();
      expect(data.userId).toBe(customerUserA.id);
      expect(data.label).toBe('Authentic HTTP Address');

      // Verify in DB that it belongs to customerUserA
      const dbRow = await prisma.customerAddress.findUnique({
        where: { id: data.id },
      });
      expect(dbRow!.userId).toBe(customerUserA.id);
    });

    it('HTTP POST /api/v1/users/me/addresses rejects unauthenticated request with HTTP 401 Unauthorized', async () => {
      const response = await fetch(`${baseUrl}/users/me/addresses`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          zoneId: zoneZayed.id,
          label: 'Unauth Address',
          buildingLine: 'Bldg 1',
          districtLine: 'Zayed',
        }),
      });

      expect(response.status).toBe(401);
    });

    it('POST /api/v1/users/me/addresses derives userId strictly from authenticated JWT, ignoring body tampering', async () => {
      const mockJwtA: FixoJwtPayload = {
        sub: customerUserA.id,
        phone: customerUserA.phone,
        role: UserRole.CUSTOMER,
        type: 'access',
        jti: 'jti-sec-1',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 900,
      };

      // Attacker payload trying to impersonate Customer B
      const roguePayload: any = {
        userId: customerUserB.id,
        zoneId: zoneZayed.id,
        label: 'Tamper Attempt Address',
        buildingLine: 'Bldg Tamper',
        districtLine: 'Zayed',
        isDefault: false,
      };

      const result = await usersController.createAddress(mockJwtA, roguePayload);

      // Must be owned by Customer A, NOT Customer B
      expect(result.userId).toBe(customerUserA.id);

      const dbRow = await prisma.customerAddress.findUnique({
        where: { id: result.id },
      });
      expect(dbRow!.userId).toBe(customerUserA.id);
      expect(dbRow!.userId).not.toBe(customerUserB.id);
    });

    it('GET /api/v1/users/me returns newly persisted address in user.addresses[] with nested zone', async () => {
      const mockJwtA: FixoJwtPayload = {
        sub: customerUserA.id,
        phone: customerUserA.phone,
        role: UserRole.CUSTOMER,
        type: 'access',
        jti: 'jti-sec-2',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 900,
      };

      const response = await usersController.getMe(mockJwtA);

      expect(response.user.id).toBe(customerUserA.id);
      expect(Array.isArray(response.user.addresses)).toBe(true);
      expect(response.user.addresses!.length).toBeGreaterThanOrEqual(1);

      const defaultAddr = response.user.addresses!.find((a: any) => a.isDefault);
      expect(defaultAddr).toBeDefined();
      expect(defaultAddr.zone).toBeDefined();
      expect(defaultAddr.zone.slug).toBeDefined();
    });

    it('GET /api/v1/users/me/addresses returns list response matching Flutter expectations', async () => {
      const mockJwtA: FixoJwtPayload = {
        sub: customerUserA.id,
        phone: customerUserA.phone,
        role: UserRole.CUSTOMER,
        type: 'access',
        jti: 'jti-sec-3',
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 900,
      };

      const response = await usersController.getAddresses(mockJwtA);

      expect(response.total).toBe(response.addresses.length);
      expect(response.addresses[0].isDefault).toBe(true); // First item is default
      expect(response.addresses[0].zone?.nameEn).toBeDefined();
    });
  });
});

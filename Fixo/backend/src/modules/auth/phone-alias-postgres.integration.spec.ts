import {
  INestApplication,
  ServiceUnavailableException,
  UnauthorizedException,
  ValidationPipe,
} from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { randomInt, randomUUID } from 'crypto';
import * as dotenv from 'dotenv';
import * as path from 'path';
import { PrismaModule } from '../../prisma/prisma.module';
import { PrismaService } from '../../prisma/prisma.service';
import {
  assertCurrentDatabaseIsTest,
  validateTestDatabaseTarget,
} from '../../prisma/test-database-safety.util';
import { AuthModule } from './auth.module';
import { AuthService } from './auth.service';
import { FirebaseTokenVerifier } from './firebase-identity.service';
import {
  FirebasePasswordGateway,
  PhonePasswordService,
} from './phone-password.service';

dotenv.config({ path: path.resolve(__dirname, '../../../.env') });

describe('Password-confirmed phone changes (guarded local PostgreSQL)', () => {
  let app: INestApplication,
    prisma: PrismaService,
    auth: AuthService,
    service: PhonePasswordService,
    baseUrl: string;
  let actor: any, other: any, session: any;
  const gateway = { signIn: jest.fn() },
    verifier = { verify: jest.fn() };
  const phone = () => `+2010${randomInt(10000000, 99999999)}`;
  beforeAll(async () => {
    validateTestDatabaseTarget(process.env.TEST_DATABASE_URL);
    process.env.DATABASE_URL = process.env.TEST_DATABASE_URL;
    process.env.FIXO_TEST_FORCE_PRISMA = 'true';
    process.env.ALLOW_IN_MEMORY_FALLBACK = 'false';
    const module = await Test.createTestingModule({
      imports: [PrismaModule, AuthModule],
    })
      .overrideProvider(FirebasePasswordGateway)
      .useValue(gateway)
      .overrideProvider(FirebaseTokenVerifier)
      .useValue(verifier)
      .compile();
    app = module.createNestApplication();
    app.setGlobalPrefix('api/v1');
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    await app.init();
    await app.listen(0, '127.0.0.1');
    baseUrl = await app.getUrl();
    prisma = module.get(PrismaService);
    auth = module.get(AuthService);
    service = module.get(PhonePasswordService);
    await assertCurrentDatabaseIsTest(prisma);
  });
  beforeEach(async () => {
    const id = randomUUID();
    actor = await prisma.user.create({
      data: {
        fullName: 'Fixture Owner',
        phone: phone(),
        email: `${id}@example.test`,
        firebaseUid: `firebase-${id}`,
      },
    });
    other = await prisma.user.create({
      data: {
        fullName: 'Other Fixture',
        phone: phone(),
        email: `${randomUUID()}@example.test`,
      },
    });
    gateway.signIn.mockReset().mockResolvedValue('fixture-provider-token');
    verifier.verify
      .mockReset()
      .mockResolvedValue({
        uid: actor.firebaseUid,
        email_verified: true,
        auth_time: Math.floor(Date.now() / 1000),
      });
    session = await auth.issueVerifiedUserSession(
      actor.id,
      Math.floor(Date.now() / 1000),
    );
    await auth.issueVerifiedUserSession(
      actor.id,
      Math.floor(Date.now() / 1000),
    );
    await auth.issueVerifiedUserSession(other.id);
  });
  afterEach(async () => {
    await prisma.user.deleteMany({
      where: { id: { in: [actor?.id, other?.id].filter(Boolean) } },
    });
  });
  afterAll(async () => {
    if (app) await app.close();
  });
  const patch = (data: object, authenticated = true) =>
    fetch(`${baseUrl}/api/v1/auth/phone-alias`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        ...(authenticated
          ? { Authorization: `Bearer ${session.accessToken}` }
          : {}),
      },
      body: JSON.stringify(data),
    });

  it('persists the new alias, replaces the current session and revokes only the owner’s prior refresh sessions', async () => {
    const next = phone();
    const response = await patch({
      phone: next,
      password: 'fixture-current-password',
    });
    expect(response.status).toBe(200);
    const updated = await response.json();
    expect(updated.user.id).toBe(actor.id);
    expect(updated.user.phone).toBe(next);
    expect(auth.verifyAccessToken(updated.accessToken).sub).toBe(actor.id);
    expect(
      await prisma.refreshToken.count({
        where: { userId: actor.id, revokedAt: null },
      }),
    ).toBe(1);
    expect(
      await prisma.refreshToken.count({
        where: { userId: actor.id, revokedAt: { not: null } },
      }),
    ).toBe(2);
    expect(
      await prisma.refreshToken.count({
        where: { userId: other.id, revokedAt: null },
      }),
    ).toBe(1);
    expect(
      (await prisma.user.findUniqueOrThrow({ where: { id: other.id } })).phone,
    ).toBe(other.phone);
    await expect(
      service.signIn({
        phone: actor.phone,
        password: 'fixture-current-password',
      }),
    ).rejects.toThrow(UnauthorizedException);
    expect(
      (
        await service.signIn({
          phone: next,
          password: 'fixture-current-password',
        })
      ).user.id,
    ).toBe(actor.id);
  });
  it('rolls back conflicting aliases without revoking the old sessions or exposing the other account', async () => {
    const response = await patch({
      phone: other.phone,
      password: 'fixture-current-password',
    });
    expect(response.status).toBe(409);
    expect(JSON.stringify(await response.json())).not.toContain(other.email);
    expect(
      (await prisma.user.findUniqueOrThrow({ where: { id: actor.id } })).phone,
    ).toBe(actor.phone);
    expect(
      await prisma.refreshToken.count({
        where: { userId: actor.id, revokedAt: null },
      }),
    ).toBe(2);
  });
  it('fails closed on wrong passwords, provider failure, malformed input and missing authentication', async () => {
    gateway.signIn.mockRejectedValueOnce(
      new UnauthorizedException('Invalid credentials.'),
    );
    expect((await patch({ phone: phone(), password: 'wrong' })).status).toBe(
      401,
    );
    verifier.verify.mockRejectedValueOnce(
      new ServiceUnavailableException('Provider unavailable.'),
    );
    expect((await patch({ phone: phone(), password: 'fixture' })).status).toBe(
      503,
    );
    expect((await patch({ phone: 'bad', password: 'fixture' })).status).toBe(
      400,
    );
    expect(
      (await patch({ phone: phone(), password: 'fixture', userId: other.id }))
        .status,
    ).toBe(400);
    expect(
      (await patch({ phone: phone(), password: 'fixture' }, false)).status,
    ).toBe(401);
    expect(
      (await prisma.user.findUniqueOrThrow({ where: { id: actor.id } })).phone,
    ).toBe(actor.phone);
    expect(
      await prisma.refreshToken.count({
        where: { userId: actor.id, revokedAt: null },
      }),
    ).toBe(2);
  });
  it('serializes conflicting simultaneous changes under the same original phone snapshot', async () => {
    let arrivals = 0,
      release!: () => void;
    const barrier = new Promise<void>((resolve) => {
      release = resolve;
    });
    gateway.signIn.mockImplementation(async () => {
      if (++arrivals === 2) release();
      await barrier;
      return 'fixture-provider-token';
    });
    const choices = [phone(), phone()];
    const responses = await Promise.all(
      choices.map((next) => patch({ phone: next, password: 'fixture' })),
    );
    expect(responses.map((r) => r.status).sort()).toEqual([200, 409]);
    expect(choices).toContain(
      (await prisma.user.findUniqueOrThrow({ where: { id: actor.id } })).phone,
    );
    expect(
      await prisma.refreshToken.count({
        where: { userId: actor.id, revokedAt: null },
      }),
    ).toBe(1);
  });
});

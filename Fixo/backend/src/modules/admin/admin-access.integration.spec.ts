import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { randomUUID } from 'crypto';
import * as dotenv from 'dotenv';
import * as path from 'path';
import { PrismaModule } from '../../prisma/prisma.module';
import { PrismaService } from '../../prisma/prisma.service';
import {
  assertCurrentDatabaseIsTest,
  validateTestDatabaseTarget,
} from '../../prisma/test-database-safety.util';
import { AuthService } from '../auth/auth.service';
import { FirebaseSessionPolicy } from '../auth/firebase-session-policy.service';
import { AdminAccessModule } from './admin-access.module';
import { AdminAccessService } from './admin-access.service';

dotenv.config({ path: path.resolve(__dirname, '../../../.env') });
describe('Private two-person admin access (guarded PostgreSQL)', () => {
  let app: INestApplication, db: PrismaService, auth: AuthService, url: string;
  let owner: any, friend: any, outsider: any;
  const identities = new Map<string, string>();
  const policy = { readVerifiedAccount: jest.fn() };
  const oldOwner = process.env.FIXO_OWNER_EMAIL;
  beforeAll(async () => {
    validateTestDatabaseTarget(process.env.TEST_DATABASE_URL);
    process.env.DATABASE_URL = process.env.TEST_DATABASE_URL;
    process.env.FIXO_TEST_FORCE_PRISMA = 'true';
    process.env.ALLOW_IN_MEMORY_FALLBACK = 'false';
    const module = await Test.createTestingModule({
      imports: [PrismaModule, AdminAccessModule],
    })
      .overrideProvider(FirebaseSessionPolicy)
      .useValue(policy)
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
    url = await app.getUrl();
    db = module.get(PrismaService);
    auth = module.get(AuthService);
    await assertCurrentDatabaseIsTest(db);
  });
  beforeEach(async () => {
    identities.clear();
    const create = async (role: 'CUSTOMER' | 'ADMIN' = 'CUSTOMER') => {
      const id = randomUUID();
      const u = await db.user.create({
        data: {
          email: `${id}@example.test`,
          firebaseUid: id,
          fullName: 'Fixture account',
          role,
        },
      });
      identities.set(id, u.email!);
      return u;
    };
    owner = await create();
    friend = await create();
    outsider = await create('ADMIN');
    process.env.FIXO_OWNER_EMAIL = owner.email;
    policy.readVerifiedAccount
      .mockReset()
      .mockImplementation(async (uid: string) => ({
        uid,
        email: identities.get(uid),
      }));
  });
  afterEach(async () => {
    await (db as any).adminAuditLog.deleteMany();
    await (db as any).adminMembership.deleteMany();
    await db.user.deleteMany({
      where: {
        id: { in: [owner?.id, friend?.id, outsider?.id].filter(Boolean) },
      },
    });
  });
  afterAll(async () => {
    if (oldOwner === undefined) delete process.env.FIXO_OWNER_EMAIL;
    else process.env.FIXO_OWNER_EMAIL = oldOwner;
    if (app) await app.close();
  });
  const request = async (
    actor: any,
    route = '/me',
    method = 'GET',
    body?: object,
    age = 0,
  ) => {
    const session = actor
      ? await auth.issueVerifiedUserSession(
          actor.id,
          Math.floor(Date.now() / 1000) - age,
        )
      : null;
    return fetch(`${url}/api/v1/admin${route}`, {
      method,
      headers: {
        'Content-Type': 'application/json',
        ...(session ? { Authorization: `Bearer ${session.accessToken}` } : {}),
      },
      ...(body ? { body: JSON.stringify(body) } : {}),
    });
  };
  it('denies anonymous and ordinary app ADMIN roles', async () => {
    expect((await request(null)).status).toBe(401);
    expect((await request(outsider)).status).toBe(403);
    expect(await (db as any).adminMembership.count()).toBe(0);
  });
  it('bootstraps exactly one owner under concurrent verified requests without changing app role', async () => {
    const responses = await Promise.all([request(owner), request(owner)]);
    expect(responses.map((r) => r.status)).toEqual([200, 200]);
    expect(await (db as any).adminMembership.count()).toBe(1);
    expect(await (db as any).adminAuditLog.count()).toBe(1);
    expect(
      (await db.user.findUniqueOrThrow({ where: { id: owner.id } })).role,
    ).toBe('CUSTOMER');
  });
  it('binds the invited second member, denies membership management and prevents a third slot', async () => {
    expect((await request(owner)).status).toBe(200);
    expect(
      (await request(owner, '/member', 'PUT', { email: friend.email })).status,
    ).toBe(200);
    expect((await (await request(friend)).json()).role).toBe('ADMIN');
    expect(
      (await request(friend, '/member', 'PUT', { email: outsider.email }))
        .status,
    ).toBe(403);
    await expect(
      db.$executeRawUnsafe(
        `INSERT INTO "AdminMembership" (slot,email,role,"updatedAt") VALUES (3,'third@example.test','ADMIN',NOW())`,
      ),
    ).rejects.toThrow();
    expect(await (db as any).adminMembership.count()).toBe(2);
  });
  it('revokes the second member immediately and never auto-restores an inactive invite', async () => {
    await request(owner);
    await request(owner, '/member', 'PUT', { email: friend.email });
    await request(friend);
    expect((await request(owner, '/member', 'DELETE')).status).toBe(200);
    expect((await request(friend)).status).toBe(403);
  });
  it('rejects mismatched provider emails, old proofs and self-invites', async () => {
    policy.readVerifiedAccount.mockResolvedValueOnce({
      uid: owner.firebaseUid,
      email: 'wrong@example.test',
    });
    expect((await request(owner)).status).toBe(403);
    expect(await (db as any).adminMembership.count()).toBe(0);
    expect(
      (await request(owner, '/me', 'GET', undefined, 13 * 3600)).status,
    ).toBe(403);
    await request(owner);
    expect(
      (await request(owner, '/member', 'PUT', { email: owner.email })).status,
    ).toBe(400);
    expect(
      (await request(owner, '/member', 'PUT', { email: friend.email }, 901))
        .status,
    ).toBe(403);
  });
  it('rejects expired invites and records only successful mutations', async () => {
    await request(owner);
    await request(owner, '/member', 'PUT', { email: friend.email });
    await (db as any).adminMembership.update({
      where: { slot: 2 },
      data: { expiresAt: new Date(0) },
    });
    expect((await request(friend)).status).toBe(403);
    const audit = await (await request(owner, '/audit')).json();
    expect(audit.items).toHaveLength(2);
    expect(JSON.stringify(audit)).not.toContain(friend.email);
  });
  it('rechecks stale authority and rolls back a failed operation together with its audit event', async () => {
    await request(owner);
    await request(owner, '/member', 'PUT', { email: friend.email });
    await request(friend);
    const access = app.get(AdminAccessService);
    const stale = {
      userId: friend.id,
      role: 'ADMIN' as const,
      authTime: Math.floor(Date.now() / 1000),
    };
    await request(owner, '/member', 'DELETE');
    const operation = jest.fn();
    await expect(
      access.mutate(stale, false, 'TEST', 'test', operation),
    ).rejects.toThrow();
    expect(operation).not.toHaveBeenCalled();
    const count = await (db as any).adminAuditLog.count();
    await expect(
      access.mutate(
        {
          userId: owner.id,
          role: 'OWNER',
          authTime: Math.floor(Date.now() / 1000),
        },
        true,
        'TEST',
        'test',
        async (tx) => {
          await tx.user.update({
            where: { id: owner.id },
            data: { fullName: 'Should roll back' },
          });
          throw Error('Synthetic operation failure');
        },
      ),
    ).rejects.toThrow('Synthetic operation failure');
    expect(
      (await db.user.findUniqueOrThrow({ where: { id: owner.id } })).fullName,
    ).toBe('Fixture account');
    expect(await (db as any).adminAuditLog.count()).toBe(count);
  });
});

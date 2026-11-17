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
import { PrivateStorageService } from '../media/private-storage.service';
import { ProModule } from '../pro/pro.module';
const sharp: typeof import('sharp').default = require('sharp');
dotenv.config({ path: path.resolve(__dirname, '../../../.env') });

describe('Private professional administration (local PostgreSQL only)', () => {
  let app: INestApplication, db: PrismaService, auth: AuthService, url: string;
  let owner: any,
    friend: any,
    outsider: any,
    applicant: any,
    profile: any,
    category: any,
    zone: any;
  let bytes: Buffer;
  const identities = new Map<string, string>();
  const objects = new Map<string, Buffer>();
  const storage = {
    get: jest.fn(async (key: string) => {
      if (!objects.has(key)) throw Error('Missing fixture');
      return objects.get(key)!;
    }),
  };
  const provider = {
    readVerifiedAccount: jest.fn(async (uid: string) => ({
      uid,
      email: identities.get(uid),
    })),
  };
  const oldOwner = process.env.FIXO_OWNER_EMAIL;
  beforeAll(async () => {
    validateTestDatabaseTarget(process.env.TEST_DATABASE_URL);
    process.env.DATABASE_URL = process.env.TEST_DATABASE_URL;
    process.env.FIXO_TEST_FORCE_PRISMA = 'true';
    process.env.ALLOW_IN_MEMORY_FALLBACK = 'false';
    const module = await Test.createTestingModule({
      imports: [PrismaModule, ProModule],
    })
      .overrideProvider(FirebaseSessionPolicy)
      .useValue(provider)
      .overrideProvider(PrivateStorageService)
      .useValue(storage)
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
    bytes = await sharp({
      create: { width: 32, height: 32, channels: 3, background: '#173f35' },
    })
      .webp()
      .toBuffer();
    const key = randomUUID();
    category = await db.serviceCategory.create({
      data: {
        slug: key,
        nameEn: 'Fixture',
        nameAr: 'اختبار',
        subtitleEn: 'Fixture',
        subtitleAr: 'اختبار',
        iconName: 'build',
        startingPriceEgp: 100,
      },
    });
    zone = await db.coverageZone.create({
      data: {
        slug: key,
        nameEn: 'Fixture',
        nameAr: 'اختبار',
        governorate: 'Cairo',
      },
    });
  });
  const dossier = async (userId: string) => {
    const p = await db.proProfile.create({
      data: {
        userId,
        dossierCode: randomUUID(),
        legalName: 'Fixture Legal Applicant',
        nationalIdSynthetic: '00000000000000',
        verificationStatus: 'PENDING_REVIEW',
        primaryCategoryId: category.id,
        primaryZoneId: zone.id,
        coverageZones: { connect: { id: zone.id } },
        toolkitCommitmentConfirmed: true,
      },
    });
    for (const docType of [
      'NATIONAL_ID_FRONT',
      'NATIONAL_ID_BACK',
      'CRIMINAL_RECORD_CERT',
    ] as const) {
      const key = `documents/${p.id}/${randomUUID()}.webp`;
      objects.set(key, bytes);
      await db.proVerificationDocument.create({
        data: {
          proProfileId: p.id,
          docType,
          fileName: 'synthetic-fixture.webp',
          fileSizeBytes: bytes.length,
          storageKey: `obj::fixture-hash::image/webp::${key}`,
        },
      });
    }
    return p;
  };
  beforeEach(async () => {
    identities.clear();
    objects.clear();
    storage.get.mockClear();
    const user = async (role: 'CUSTOMER' | 'ADMIN' = 'CUSTOMER') => {
      const uid = randomUUID();
      const u = await db.user.create({
        data: {
          email: `${uid}@example.test`,
          firebaseUid: uid,
          fullName: 'Fixture',
          role,
        },
      });
      identities.set(uid, u.email!);
      return u;
    };
    owner = await user();
    friend = await user();
    outsider = await user('ADMIN');
    applicant = await user();
    process.env.FIXO_OWNER_EMAIL = owner.email;
    profile = await dossier(applicant.id);
  });
  afterEach(async () => {
    await db.adminAuditLog.deleteMany();
    await db.adminMembership.deleteMany();
    await db.user.deleteMany({
      where: {
        id: {
          in: [owner?.id, friend?.id, outsider?.id, applicant?.id].filter(
            Boolean,
          ),
        },
      },
    });
  });
  afterAll(async () => {
    if (oldOwner === undefined) delete process.env.FIXO_OWNER_EMAIL;
    else process.env.FIXO_OWNER_EMAIL = oldOwner;
    if (category)
      await db.serviceCategory.delete({ where: { id: category.id } });
    if (zone) await db.coverageZone.delete({ where: { id: zone.id } });
    if (app) await app.close();
  });
  const request = async (
    actor: any,
    route: string,
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
    return fetch(`${url}/api/v1${route}`, {
      method,
      headers: {
        'Content-Type': 'application/json',
        ...(session ? { Authorization: `Bearer ${session.accessToken}` } : {}),
      },
      ...(body ? { body: JSON.stringify(body) } : {}),
    });
  };
  const details = async (actor = owner, p = profile) => {
    const r = await request(actor, `/admin/professionals/${p.id}`);
    expect(r.status).toBe(200);
    return r.json();
  };
  const approve = async (
    actor = owner,
    snapshot?: any,
    p = profile,
    age = 0,
  ) => {
    const d = snapshot ?? (await details(actor, p));
    return request(
      actor,
      `/admin/professionals/${p.id}/review`,
      'PATCH',
      {
        status: 'APPROVED',
        reviewVersion: d.reviewVersion,
        confirmDocumentsReviewed: true,
      },
      age,
    );
  };
  it('denies anonymous and ordinary app ADMIN access, including legacy document/review routes', async () => {
    expect((await request(null, '/admin/professionals')).status).toBe(401);
    expect((await request(outsider, '/admin/professionals')).status).toBe(403);
    const doc = await db.proVerificationDocument.findFirstOrThrow({
      where: { proProfileId: profile.id },
    });
    expect(
      (await request(outsider, `/pro/onboarding/documents/${doc.id}/access`))
        .status,
    ).toBe(403);
    expect(
      (await request(outsider, `/pro/onboarding/documents/${doc.id}/content`))
        .status,
    ).toBe(403);
    expect(
      (
        await request(
          outsider,
          `/pro/admin/profiles/${profile.id}/review`,
          'PATCH',
          { status: 'APPROVED' },
        )
      ).status,
    ).toBe(403);
    expect(storage.get).not.toHaveBeenCalled();
  });
  it('lists bounded safe summaries and serves explicit private details without storage references', async () => {
    const r = await request(
      owner,
      '/admin/professionals?status=PENDING_REVIEW',
    );
    expect(r.status).toBe(200);
    const list = await r.json();
    expect(list.items.some((p: any) => p.id === profile.id)).toBe(true);
    expect(list.items.length).toBeLessThanOrEqual(20);
    expect(JSON.stringify(list)).not.toContain('00000000000000');
    expect(JSON.stringify(list)).not.toContain('storageKey');
    const d = await details();
    expect(d.legalName).toBe('Fixture Legal Applicant');
    expect(d.reviewVersion).toMatch(/^[a-f0-9]{64}$/);
    expect(d.documents).toHaveLength(3);
    expect(JSON.stringify(d)).not.toContain('obj::');
    expect(JSON.stringify(d)).not.toContain('base64');
    expect(JSON.stringify(await db.adminAuditLog.findMany())).not.toContain(
      '00000000000000',
    );
  });
  it('uses authenticated bounded document bytes and rejects an unrelated dossier path', async () => {
    const d = await details();
    const doc = d.documents[0];
    const r = await request(
      owner,
      `/admin/professionals/${profile.id}/documents/${doc.id}/content`,
    );
    expect(r.status).toBe(200);
    expect(r.headers.get('cache-control')).toContain('no-store');
    expect(r.headers.get('content-type')).toContain('image/webp');
    expect(Buffer.from(await r.arrayBuffer())).toEqual(bytes);
    storage.get.mockClear();
    expect(
      (
        await request(
          owner,
          `/admin/professionals/${randomUUID()}/documents/${doc.id}/content`,
        )
      ).status,
    ).toBe(404);
    expect(storage.get).not.toHaveBeenCalled();
    expect(
      (await request(applicant, `/pro/onboarding/documents/${doc.id}/content`))
        .status,
    ).toBe(200);
  });
  it('allows actual Owner/Admin reviews without granting a general app ADMIN role', async () => {
    const snapshot = await details();
    expect(
      (
        await request(
          owner,
          `/admin/professionals/${profile.id}/review`,
          'PATCH',
          {
            status: 'APPROVED',
            reviewVersion: snapshot.reviewVersion,
            confirmDocumentsReviewed: true,
            documentDecisions: [
              { docType: 'NATIONAL_ID_FRONT', status: 'VERIFIED' },
            ],
          },
        )
      ).status,
    ).toBe(200);
    expect(
      await db.proVerificationDocument.count({
        where: { proProfileId: profile.id, status: 'VERIFIED' },
      }),
    ).toBe(3);
    expect(
      (await db.proProfile.findUniqueOrThrow({ where: { id: profile.id } }))
        .verificationStatus,
    ).toBe('APPROVED');
    expect(
      (await db.user.findUniqueOrThrow({ where: { id: applicant.id } })).role,
    ).toBe('PRO');
    expect(
      (await db.user.findUniqueOrThrow({ where: { id: owner.id } })).role,
    ).toBe('CUSTOMER');
    expect(
      await db.adminAuditLog.count({
        where: { action: 'PRO_PROFILE_REVIEWED', entityId: profile.id },
      }),
    ).toBe(1);
    await request(owner, '/admin/member', 'PUT', { email: friend.email });
    const p = await dossier(outsider.id);
    expect((await approve(friend, undefined, p)).status).toBe(200);
    await request(owner, '/admin/member', 'DELETE');
    expect((await request(friend, '/admin/professionals')).status).toBe(403);
  });
  it('refuses self-review, stale snapshots and stale account confirmation', async () => {
    const own = await dossier(owner.id);
    const self = await details(owner, own);
    expect(self.canReview).toBe(false);
    expect((await approve(owner, self, own)).status).toBe(403);
    expect(
      (
        await request(
          owner,
          `/admin/professionals/${profile.id}`,
          'GET',
          undefined,
          1000,
        )
      ).status,
    ).toBe(403);
    const snapshot = await details();
    const doc = await db.proVerificationDocument.findFirstOrThrow({
      where: { proProfileId: profile.id },
    });
    await db.proVerificationDocument.update({
      where: { id: doc.id },
      data: {
        storageKey: doc.storageKey.replace('fixture-hash', 'new-fixture-hash'),
      },
    });
    expect((await approve(owner, snapshot)).status).toBe(409);
    expect(
      await db.adminAuditLog.count({
        where: { action: 'PRO_PROFILE_REVIEWED' },
      }),
    ).toBe(0);
  });
  it('requires the three usable documents and an explicit review confirmation; corrections carry a reason', async () => {
    let d = await details();
    expect(
      (
        await request(
          owner,
          `/admin/professionals/${profile.id}/review`,
          'PATCH',
          { status: 'APPROVED', reviewVersion: d.reviewVersion },
        )
      ).status,
    ).toBe(400);
    expect(
      (
        await request(
          owner,
          `/admin/professionals/${profile.id}/review`,
          'PATCH',
          { status: 'ACTION_REQUIRED', reviewVersion: d.reviewVersion },
        )
      ).status,
    ).toBe(400);
    await db.proVerificationDocument.deleteMany({
      where: { proProfileId: profile.id, docType: 'NATIONAL_ID_BACK' },
    });
    d = await details();
    expect((await approve(owner, d)).status).toBe(400);
    const r = await request(
      owner,
      `/admin/professionals/${profile.id}/review`,
      'PATCH',
      {
        status: 'ACTION_REQUIRED',
        reviewVersion: d.reviewVersion,
        reviewerNote: 'Upload the missing back photo.',
        documentDecisions: [
          { docType: 'NATIONAL_ID_FRONT', status: 'REJECTED' },
        ],
      },
    );
    expect(r.status).toBe(200);
    expect((await r.json()).verificationStatus).toBe('ACTION_REQUIRED');
    expect(
      (
        await db.proVerificationDocument.findFirstOrThrow({
          where: { proProfileId: profile.id, docType: 'NATIONAL_ID_FRONT' },
        })
      ).reviewerComment,
    ).toBe('Upload the missing back photo.');
    expect(
      (await db.user.findUniqueOrThrow({ where: { id: applicant.id } })).role,
    ).toBe('CUSTOMER');
  });
  it('rolls the decision, document statuses and role back if audit persistence fails', async () => {
    const d = await details();
    const originalTransaction = db.$transaction.bind(db);
    // The transaction delegate differs from the root Prisma delegate. Inject only
    // the audit failure into the real transaction; all domain writes remain SQL.
    const audit = jest.spyOn(db, '$transaction').mockImplementation(((
      input: any,
      options: any,
    ) => {
      if (Array.isArray(input)) return originalTransaction(input);
      return originalTransaction(
        async (tx: any) =>
          input(
            new Proxy(tx, {
              get(target, key) {
                if (key !== 'adminAuditLog') return Reflect.get(target, key);
                return new Proxy(target.adminAuditLog, {
                  get(delegate, method) {
                    if (method !== 'create')
                      return Reflect.get(delegate, method);
                    return (args: any) => {
                      if (args.data.action === 'PRO_PROFILE_REVIEWED')
                        throw Error('Synthetic audit failure');
                      return delegate.create(args);
                    };
                  },
                });
              },
            }),
          ),
        options,
      );
    }) as any);
    try {
      expect((await approve(owner, d)).status).toBe(500);
    } finally {
      audit.mockRestore();
    }
    expect(
      (await db.proProfile.findUniqueOrThrow({ where: { id: profile.id } }))
        .verificationStatus,
    ).toBe('PENDING_REVIEW');
    expect(
      await db.proVerificationDocument.count({
        where: { proProfileId: profile.id, status: 'VERIFIED' },
      }),
    ).toBe(0);
    expect(
      (await db.user.findUniqueOrThrow({ where: { id: applicant.id } })).role,
    ).toBe('CUSTOMER');
  });
});

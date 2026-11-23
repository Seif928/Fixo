import {
  ConflictException,
  ForbiddenException,
  ServiceUnavailableException,
  UnauthorizedException,
  ValidationPipe,
} from "@nestjs/common";
import { Test } from "@nestjs/testing";
import { PrismaService } from "../../prisma/prisma.service";
import { InMemoryStoreService } from "../../prisma/in-memory-store.service";
import {
  assertCurrentDatabaseIsTest,
  safeCleanupTestDatabase,
  validateTestDatabaseTarget,
} from "../../prisma/test-database-safety.util";
import { AuthService } from "./auth.service";
import { FirebaseTokenVerifier } from "./firebase-identity.service";
import { FirebaseSessionPolicy } from "./firebase-session-policy.service";
import { ClerkIdentityService } from "./clerk-identity.service";
import { ClerkSessionPolicy } from "./clerk-session-policy.service";
import {
  ClerkIdentityController,
  ClerkTrialRateGuard,
} from "./clerk-identity.controller";
import { JwtAuthGuard } from "./guards/jwt-auth.guard";
import { AdminAccessService } from "../admin/admin-access.service";
import { hashTokenSha256 } from "./utils/jwt-token.util";

describe("Staged Clerk identity linking and FIXO refresh (local PostgreSQL)", () => {
  let db: PrismaService;
  let auth: AuthService;
  let service: ClerkIdentityService;
  let policy: ClerkSessionPolicy;
  const binding = {
    issuer: "https://fixture.clerk.accounts.dev",
    subject: "user_fixture",
    sessionId: "sess_fixture",
  };
  const config = {
    enabled: true,
    issuer: binding.issuer,
    secretKey: "sk_test_fixture",
    jwtKey: "fixture public key",
    authorizedParties: ["https://fixo.example.test"],
  };
  const firebase = { verify: jest.fn() };
  const providerSessions = { assertValid: jest.fn() };
  let owner: { id: string; firebaseUid: string | null };
  let other: { id: string; firebaseUid: string | null };
  let oldEnvironment: Record<string, string | undefined>;
  const envKeys = [
    "DATABASE_URL",
    "FIXO_TEST_FORCE_PRISMA",
    "ALLOW_IN_MEMORY_FALLBACK",
  ];
  const security = {
    accessSecret: "a".repeat(64),
    refreshSecret: "b".repeat(64),
    otpHmacSecret: "c".repeat(64),
    smsProviderType: "DEV_SANDBOX_SMS" as const,
    isProduction: false,
    allowDevSms: true,
    allowInMemoryFallback: false,
    allowTestFixedOtp: true,
  };

  beforeAll(async () => {
    validateTestDatabaseTarget(process.env.TEST_DATABASE_URL);
    oldEnvironment = Object.fromEntries(
      envKeys.map((key) => [key, process.env[key]]),
    );
    process.env.DATABASE_URL = process.env.TEST_DATABASE_URL;
    process.env.FIXO_TEST_FORCE_PRISMA = "true";
    process.env.ALLOW_IN_MEMORY_FALLBACK = "false";
    db = new PrismaService();
    await db.onModuleInit();
    await assertCurrentDatabaseIsTest(db);
  }, 30000);
  beforeEach(async () => {
    await safeCleanupTestDatabase(db);
    owner = await db.user.create({
      data: {
        firebaseUid: "firebase-owner",
        email: "owner@example.test",
        phone: "+201023456789",
        fullName: "Existing FIXO User",
      },
    });
    other = await db.user.create({
      data: { firebaseUid: "firebase-other", email: "other@example.test" },
    });
    jest.clearAllMocks();
    policy = new ClerkSessionPolicy(config);
    jest.spyOn(policy, "verify").mockResolvedValue(binding);
    jest.spyOn(policy, "assertValid").mockResolvedValue();
    firebase.verify.mockResolvedValue({
      uid: owner.firebaseUid,
      auth_time: Math.floor(Date.now() / 1000),
      email_verified: true,
    });
    auth = new AuthService(
      db,
      new InMemoryStoreService(),
      {} as never,
      providerSessions as unknown as FirebaseSessionPolicy,
      policy,
    );
    auth.configureSecurity(security);
    service = new ClerkIdentityService(
      db,
      firebase as unknown as FirebaseTokenVerifier,
      auth,
      policy,
    );
  }, 30000);
  afterAll(async () => {
    if (db) {
      await safeCleanupTestDatabase(db);
      await db.onModuleDestroy();
    }
    for (const key of envKeys) {
      if (oldEnvironment?.[key] === undefined) delete process.env[key];
      else process.env[key] = oldEnvironment[key];
    }
  });

  it("links two proven identities without changing FIXO account, role or email", async () => {
    const prior = await db.user.findUniqueOrThrow({ where: { id: owner.id } });
    await expect(
      service.link(owner.id, "firebase-proof", "clerk-proof"),
    ).resolves.toEqual({ linked: true });
    expect(await db.clerkIdentityLink.count()).toBe(1);
    expect(await db.user.findUnique({ where: { id: owner.id } })).toEqual(
      prior,
    );
    expect(await db.refreshToken.count()).toBe(0);
  });
  it("keeps the identity-link table private behind RLS and without client grants", async () => {
    const rows = await db.$queryRaw<
      Array<{ rls: boolean; public_grants: bigint; client_grants: bigint }>
    >`
      SELECT c.relrowsecurity AS rls,
        (SELECT count(*) FROM aclexplode(coalesce(c.relacl, acldefault('r', c.relowner))) a WHERE a.grantee=0) AS public_grants,
        (SELECT count(*) FROM pg_roles r WHERE r.rolname IN ('anon','authenticated')
          AND has_table_privilege(r.oid, c.oid, 'SELECT,INSERT,UPDATE,DELETE,TRUNCATE')) AS client_grants
      FROM pg_class c JOIN pg_namespace n ON c.relnamespace=n.oid
      WHERE c.relname='ClerkIdentityLink' AND n.nspname='public';
    `;
    expect(rows).toEqual([{ rls: true, public_grants: 0n, client_grants: 0n }]);
  });
  it("rejects a Firebase proof for another FIXO account", async () => {
    await expect(
      service.link(other.id, "firebase-proof", "clerk-proof"),
    ).rejects.toThrow(UnauthorizedException);
    expect(await db.clerkIdentityLink.count()).toBe(0);
  });
  it("requires fresh Firebase reauthentication rather than a refreshed old ID token", async () => {
    firebase.verify.mockResolvedValue({
      uid: owner.firebaseUid,
      auth_time: Math.floor(Date.now() / 1000) - 601,
      email_verified: true,
    });
    await expect(
      service.link(owner.id, "firebase-proof", "clerk-proof"),
    ).rejects.toThrow(UnauthorizedException);
    expect(await db.clerkIdentityLink.count()).toBe(0);
  });
  it("is duplicate-safe under concurrent linking", async () => {
    await Promise.all(
      Array.from({ length: 4 }, () =>
        service.link(owner.id, "firebase-proof", "clerk-proof"),
      ),
    );
    expect(await db.clerkIdentityLink.count()).toBe(1);
  });
  it("cannot move a Clerk identity to a second FIXO account", async () => {
    await service.link(owner.id, "firebase-proof", "clerk-proof");
    firebase.verify.mockResolvedValue({
      uid: other.firebaseUid,
      auth_time: Math.floor(Date.now() / 1000),
      email_verified: true,
    });
    await expect(
      service.link(other.id, "firebase-proof", "clerk-proof"),
    ).rejects.toThrow(ConflictException);
    expect((await db.clerkIdentityLink.findFirstOrThrow()).userId).toBe(
      owner.id,
    );
  });
  it("cannot replace an already linked Clerk identity", async () => {
    await service.link(owner.id, "firebase-proof", "clerk-proof");
    jest
      .mocked(policy.verify)
      .mockResolvedValue({ ...binding, subject: "user_other" });
    await expect(
      service.link(owner.id, "firebase-proof", "clerk-proof"),
    ).rejects.toThrow(ConflictException);
    expect((await db.clerkIdentityLink.findFirstOrThrow()).subject).toBe(
      binding.subject,
    );
  });
  it("requires an explicit link even if verified email could match", async () => {
    await expect(service.exchange("clerk-proof")).rejects.toThrow(
      UnauthorizedException,
    );
    expect(await db.user.count()).toBe(2);
    expect(await db.refreshToken.count()).toBe(0);
  });
  it("preserves the FIXO ID and authoritative role through exchange and refresh", async () => {
    await service.link(owner.id, "firebase-proof", "clerk-proof");
    const session = await service.exchange("clerk-proof");
    expect(session.user.id).toBe(owner.id);
    expect(session.user.role).toBe("CUSTOMER");
    expect(auth.verifyAccessToken(session.accessToken).clerkSession).toEqual(
      binding,
    );
    expect(
      auth.verifyAccessToken(session.accessToken).firebaseAuthTime,
    ).toBeUndefined();
    const rotated = await auth.refreshTokens({
      refreshToken: session.refreshToken,
    });
    expect(rotated.user.id).toBe(owner.id);
    expect(auth.verifyAccessToken(rotated.accessToken).clerkSession).toEqual(
      binding,
    );
    expect(policy.assertValid).toHaveBeenCalledWith(binding);
    expect(providerSessions.assertValid).not.toHaveBeenCalled();
  });
  it("rejects refresh immediately after provider revocation without consuming the token", async () => {
    await service.link(owner.id, "firebase-proof", "clerk-proof");
    const session = await service.exchange("clerk-proof");
    jest
      .mocked(policy.assertValid)
      .mockRejectedValue(new UnauthorizedException("Revoked"));
    await expect(
      auth.refreshTokens({ refreshToken: session.refreshToken }),
    ).rejects.toThrow(UnauthorizedException);
    expect(
      (
        await db.refreshToken.findUniqueOrThrow({
          where: { tokenHash: hashTokenSha256(session.refreshToken) },
        })
      ).revokedAt,
    ).toBeNull();
  });
  it("rejects refresh if the database link is removed or belongs to another user", async () => {
    await service.link(owner.id, "firebase-proof", "clerk-proof");
    const session = await service.exchange("clerk-proof");
    await db.clerkIdentityLink.deleteMany();
    await expect(
      auth.refreshTokens({ refreshToken: session.refreshToken }),
    ).rejects.toThrow(UnauthorizedException);
    await db.clerkIdentityLink.create({
      data: {
        issuer: binding.issuer,
        subject: binding.subject,
        userId: other.id,
      },
    });
    await expect(
      auth.refreshTokens({ refreshToken: session.refreshToken }),
    ).rejects.toThrow(UnauthorizedException);
  });
  it("rejects deleted FIXO accounts on both exchange and linking", async () => {
    await service.link(owner.id, "firebase-proof", "clerk-proof");
    await db.user.update({
      where: { id: owner.id },
      data: { isDeleted: true },
    });
    await expect(service.exchange("clerk-proof")).rejects.toThrow(
      UnauthorizedException,
    );
    await expect(
      service.link(owner.id, "firebase-proof", "clerk-proof"),
    ).rejects.toThrow(UnauthorizedException);
    expect(await db.refreshToken.count()).toBe(0);
  });
  it("requires Clerk binding validation for dedicated session issuance", async () => {
    jest
      .mocked(policy.assertValid)
      .mockRejectedValue(new UnauthorizedException("Revoked"));
    await expect(auth.issueClerkUserSession(owner.id, binding)).rejects.toThrow(
      UnauthorizedException,
    );
    expect(await db.refreshToken.count()).toBe(0);
  });
  it("does not bypass the original Firebase policy for ordinary sessions", async () => {
    const session = await auth.issueVerifiedUserSession(owner.id, 12345);
    await auth.refreshTokens({ refreshToken: session.refreshToken });
    expect(providerSessions.assertValid).toHaveBeenCalledWith(
      owner.firebaseUid,
      12345,
    );
    expect(policy.assertValid).not.toHaveBeenCalled();
  });
  it("fails closed when disabled, without reading or changing links", async () => {
    const disabled = new ClerkSessionPolicy({ ...config, enabled: false });
    service = new ClerkIdentityService(
      db,
      firebase as unknown as FirebaseTokenVerifier,
      auth,
      disabled,
    );
    await expect(
      service.link(owner.id, "firebase-proof", "clerk-proof"),
    ).rejects.toThrow(ServiceUnavailableException);
    await expect(service.exchange("clerk-proof")).rejects.toThrow(
      ServiceUnavailableException,
    );
    expect(await db.clerkIdentityLink.count()).toBe(0);
  });
  it("does not provide Firebase administrative proof through a linked Clerk session", async () => {
    await service.link(owner.id, "firebase-proof", "clerk-proof");
    const session = await service.exchange("clerk-proof");
    const admin = new AdminAccessService(
      db,
      providerSessions as unknown as FirebaseSessionPolicy,
    );
    await expect(
      admin.resolve(auth.verifyAccessToken(session.accessToken)),
    ).rejects.toThrow(ForbiddenException);
  });
  it("revokes the original Clerk-backed FIXO refresh on logout", async () => {
    await service.link(owner.id, "firebase-proof", "clerk-proof");
    const session = await service.exchange("clerk-proof");
    expect(
      (await auth.logout({ refreshToken: session.refreshToken })).revoked,
    ).toBe(true);
    await expect(
      auth.refreshTokens({ refreshToken: session.refreshToken }),
    ).rejects.toThrow(UnauthorizedException);
  });
  it("enforces signature, body validation and explicit identity pairing over real HTTP", async () => {
    // External provider proofs are fixtures; JWTs, HTTP guards, DTOs and PostgreSQL are real.
    jest
      .spyOn(auth, "onModuleInit")
      .mockImplementation(() => auth.configureSecurity(security));
    const moduleRef = await Test.createTestingModule({
      controllers: [ClerkIdentityController],
      providers: [
        JwtAuthGuard,
        ClerkTrialRateGuard,
        { provide: ClerkIdentityService, useValue: service },
        { provide: ClerkSessionPolicy, useValue: policy },
        { provide: AuthService, useValue: auth },
      ],
    }).compile();
    const app = moduleRef.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );
    await app.listen(0, "127.0.0.1");
    try {
      const url = await app.getUrl();
      const post = (path: string, body: unknown, token?: string) =>
        fetch(url + "/auth/clerk/trial/" + path, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            ...(token ? { Authorization: "Bearer " + token } : {}),
          },
          body: JSON.stringify(body),
          signal: AbortSignal.timeout(5000),
        });
      const body = {
        firebaseIdToken: "firebase-proof".repeat(3),
        clerkToken: "clerk-proof".repeat(3),
      };
      expect((await post("link", body)).status).toBe(401);
      expect((await post("link", body, "forged-token")).status).toBe(401);
      const current = await auth.issueVerifiedUserSession(
        owner.id,
        Math.floor(Date.now() / 1000),
      );
      expect(
        (await post("link", { ...body, role: "ADMIN" }, current.accessToken))
          .status,
      ).toBe(400);
      expect((await post("exchange", { clerkToken: "short" })).status).toBe(
        400,
      );
      expect((await post("link", body, current.accessToken)).status).toBe(200);
      const exchanged = await post("exchange", { clerkToken: body.clerkToken });
      expect(exchanged.status).toBe(200);
      expect(
        ((await exchanged.json()) as { user: { id: string } }).user.id,
      ).toBe(owner.id);
      expect(await db.clerkIdentityLink.count()).toBe(1);
    } finally {
      await app.close();
    }
  });
});

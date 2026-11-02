import {
  HttpException,
  HttpStatus,
  Inject,
  Injectable,
  Logger,
  OnModuleInit,
  UnauthorizedException,
} from '@nestjs/common';
import { Prisma, UserRole } from '@prisma/client';
import { randomInt } from 'crypto';
import {
  InMemoryStoreService,
  StoredOtpChallenge,
} from '../../prisma/in-memory-store.service';
import {
  PrismaService,
  StoragePersistenceMode,
} from '../../prisma/prisma.service';
import {
  validateAuthSecurityConfig,
  ValidatedAuthSecurityConfig,
} from './config/auth-security.config';
import {
  LogoutDto,
  RefreshTokenDto,
  RequestOtpDto,
  VerifyOtpDto,
} from './dto/auth.dto';
import { SMS_PROVIDER, SmsProvider, SupportedSmsProvider } from './sms/sms.provider';
import { normalizeEgyptPhone } from './utils/egypt-phone.util';
import {
  FixoJwtPayload,
  hashOtpHmacSha256,
  hashTokenSha256,
  signFixoJwt,
  verifyFixoJwt,
  verifyOtpHmacTimingSafe,
} from './utils/jwt-token.util';

export interface AuthenticatedUserProfile {
  id: string;
  phone: string;
  fullName: string | null;
  email: string | null;
  role: UserRole;
  preferredLocale: string;
  arrivalAlertsEnabled: boolean;
  rewardPoints: number;
  addresses?: any[];
  requiresProfileSetup?: boolean;
}

export interface OtpRequestResponse {
  challengeId: string;
  phone: string;
  resendAvailableInSec: number;
  expiresInSec: number;
  smsProvider: SupportedSmsProvider;
  storageMode: StoragePersistenceMode;
}

export interface AuthTokensResponse {
  accessToken: string;
  refreshToken: string;
  expiresInSec: number;
  user: AuthenticatedUserProfile;
  storageMode: StoragePersistenceMode;
}

@Injectable()
export class AuthService implements OnModuleInit {
  private readonly logger = new Logger(AuthService.name);

  public static readonly OTP_TTL_SECONDS = 300; // 5 minutes
  public static readonly RESEND_COOLDOWN_SECONDS = 45;
  public static readonly MAX_OTP_ATTEMPTS = 5;
  public static readonly MAX_REQUESTS_PER_WINDOW = 5;
  public static readonly RATE_LIMIT_WINDOW_MS = 15 * 60 * 1000; // 15 minutes
  public static readonly ACCESS_TOKEN_TTL_SECONDS = 15 * 60; // 15 minutes
  public static readonly REFRESH_TOKEN_TTL_SECONDS = 7 * 24 * 60 * 60; // 7 days

  private config!: ValidatedAuthSecurityConfig;

  constructor(
    private readonly prisma: PrismaService,
    private readonly memoryStore: InMemoryStoreService,
    @Inject(SMS_PROVIDER) private readonly smsProvider: SmsProvider,
  ) {}

  onModuleInit(): void {
    // Fails startup immediately if configuration is insecure, missing, weak, or identical
    this.config = validateAuthSecurityConfig();
    this.logger.log(
      `AuthService initialized with verified independent cryptographic keys. (SMS Provider: ${this.config.smsProviderType}, Production: ${this.config.isProduction})`,
    );
  }

  /**
   * Allows injecting configuration directly (for isolated unit tests).
   */
  configureSecurity(config: ValidatedAuthSecurityConfig): void {
    this.config = config;
  }

  private get accessSecret(): string {
    if (!this.config?.accessSecret) {
      this.config = validateAuthSecurityConfig();
    }
    return this.config.accessSecret;
  }

  private get refreshSecret(): string {
    if (!this.config?.refreshSecret) {
      this.config = validateAuthSecurityConfig();
    }
    return this.config.refreshSecret;
  }

  private get otpHmacSecret(): string {
    if (!this.config?.otpHmacSecret) {
      this.config = validateAuthSecurityConfig();
    }
    return this.config.otpHmacSecret;
  }

  private generateOtpCode(): string {
    // Permit deterministic demo OTP when explicitly enabled in non-production environments
    if (
      this.config?.allowTestFixedOtp &&
      !this.config.isProduction
    ) {
      return process.env.FIXO_DEV_OTP_CODE ?? '482910';
    }
    // Cryptographically secure random 6-digit integer in range [100000, 999999]
    return String(randomInt(100000, 1000000));
  }

  async requestOtp(dto: RequestOtpDto): Promise<OtpRequestResponse> {
    if ((this.config ?? validateAuthSecurityConfig()).smsProviderType === 'DISABLED') {
      throw new HttpException('Phone sign-in is unavailable. Use verified email sign-in.', HttpStatus.SERVICE_UNAVAILABLE);
    }
    const phone = normalizeEgyptPhone(dto.phone);
    const otpCode = this.generateOtpCode();
    const codeHash = hashOtpHmacSha256(phone, otpCode, this.otpHmacSecret);
    const expiresAt = new Date(Date.now() + AuthService.OTP_TTL_SECONDS * 1000);

    let challenge: StoredOtpChallenge;

    if (this.prisma.isDatabaseConnected()) {
      type OtpRequestTxResult =
        | { status: 'SUCCESS'; challenge: StoredOtpChallenge }
        | { status: 'COOLDOWN_ACTIVE'; remainingSec: number }
        | { status: 'RATE_LIMIT_EXCEEDED' };

      const txResult: OtpRequestTxResult = await this.prisma.$transaction(
        async (tx) => {
          // Advisory lock strictly serializes concurrent requests for the SAME phone number
          await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${'fixo_otp_req_lock:' + phone}))`;

          // 1. Check server-side 45s resend cooldown
          const latest = await tx.otpChallenge.findFirst({
            where: { phone },
            orderBy: { createdAt: 'desc' },
          });

          if (latest) {
            const elapsedMs = Date.now() - latest.createdAt.getTime();
            const cooldownMs = AuthService.RESEND_COOLDOWN_SECONDS * 1000;
            if (elapsedMs < cooldownMs) {
              const remainingSec = Math.ceil((cooldownMs - elapsedMs) / 1000);
              return { status: 'COOLDOWN_ACTIVE', remainingSec };
            }
          }

          // 2. Check distributed rate limit (5 requests / 15 minutes)
          const windowStart = new Date(Date.now() - AuthService.RATE_LIMIT_WINDOW_MS);
          const recentCount = await tx.otpChallenge.count({
            where: { phone, createdAt: { gte: windowStart } },
          });

          if (recentCount >= AuthService.MAX_REQUESTS_PER_WINDOW) {
            return { status: 'RATE_LIMIT_EXCEEDED' };
          }

          // 3. Atomically create challenge in the same transaction
          const created = await tx.otpChallenge.create({
            data: { phone, codeHash, expiresAt },
          });

          return { status: 'SUCCESS', challenge: created };
        },
        {
          isolationLevel: 'ReadCommitted',
          timeout: 5000,
        },
      );

      if (txResult.status === 'COOLDOWN_ACTIVE') {
        throw new HttpException(
          `Resend cooldown active. Please wait ${txResult.remainingSec} seconds before requesting a new code.`,
          HttpStatus.TOO_MANY_REQUESTS,
        );
      }

      if (txResult.status === 'RATE_LIMIT_EXCEEDED') {
        throw new HttpException(
          'Too many OTP requests for this mobile number. Please wait 15 minutes before trying again.',
          HttpStatus.TOO_MANY_REQUESTS,
        );
      }

      challenge = txResult.challenge;
    } else {
      // In-Memory atomic execution (synchronous turn prevents race conditions)
      const memResult = this.memoryStore.atomicRequestOtpChallenge({
        phone,
        codeHash,
        expiresAt,
        cooldownSeconds: AuthService.RESEND_COOLDOWN_SECONDS,
        rateLimitWindowMs: AuthService.RATE_LIMIT_WINDOW_MS,
        maxRequestsPerWindow: AuthService.MAX_REQUESTS_PER_WINDOW,
      });

      if (memResult.status === 'COOLDOWN_ACTIVE') {
        throw new HttpException(
          `Resend cooldown active. Please wait ${memResult.remainingCooldownSec} seconds before requesting a new code.`,
          HttpStatus.TOO_MANY_REQUESTS,
        );
      }

      if (memResult.status === 'RATE_LIMIT_EXCEEDED') {
        throw new HttpException(
          'Too many OTP requests for this mobile number. Please wait 15 minutes before trying again.',
          HttpStatus.TOO_MANY_REQUESTS,
        );
      }

      challenge = memResult.challenge!;
    }

    const smsResult = await this.smsProvider.sendOtpCode(
      phone,
      otpCode,
      AuthService.OTP_TTL_SECONDS,
    );

    return {
      challengeId: challenge.id,
      phone,
      resendAvailableInSec: AuthService.RESEND_COOLDOWN_SECONDS,
      expiresInSec: AuthService.OTP_TTL_SECONDS,
      smsProvider: smsResult.provider,
      storageMode: this.prisma.getStorageMode(),
    };
  }

  async verifyOtp(dto: VerifyOtpDto): Promise<AuthTokensResponse> {
    const phone = normalizeEgyptPhone(dto.phone);

    if (this.prisma.isDatabaseConnected()) {
      // 1. Find challenge
      const challenge = await this.findChallengeForVerification(
        phone,
        dto.challengeId,
      );
      if (!challenge) {
        throw new UnauthorizedException(
          'No active verification challenge found for this number. Please request a new code.',
        );
      }

      if (challenge.consumedAt !== null) {
        throw new UnauthorizedException(
          'Verification code has already been used. Please request a new code.',
        );
      }

      if (challenge.expiresAt.getTime() <= Date.now()) {
        throw new UnauthorizedException(
          'Verification code has expired. Please request a new code.',
        );
      }

      if (challenge.attempts >= AuthService.MAX_OTP_ATTEMPTS) {
        throw new HttpException(
          'Maximum verification attempts exceeded. Please request a new OTP code.',
          HttpStatus.TOO_MANY_REQUESTS,
        );
      }

      const isValid = verifyOtpHmacTimingSafe(
        phone,
        dto.code,
        challenge.codeHash,
        this.otpHmacSecret,
      );

      if (!isValid) {
        // Atomic attempt counter increment
        const updated = await this.prisma.otpChallenge.update({
          where: { id: challenge.id },
          data: { attempts: { increment: 1 } },
        });

        if (updated.attempts >= AuthService.MAX_OTP_ATTEMPTS) {
          throw new HttpException(
            'Maximum verification attempts exceeded. Please request a new OTP code.',
            HttpStatus.TOO_MANY_REQUESTS,
          );
        }

        const remaining = AuthService.MAX_OTP_ATTEMPTS - updated.attempts;
        throw new UnauthorizedException(
          `Invalid verification code. ${remaining} attempt(s) remaining.`,
        );
      }

      // 2. Atomic Conditional Consumption: Prevents race condition where two concurrent
      // requests with the same valid code both consume the challenge independently
      const claimed = await this.prisma.otpChallenge.updateMany({
        where: {
          id: challenge.id,
          phone,
          consumedAt: null,
          attempts: { lt: AuthService.MAX_OTP_ATTEMPTS },
          expiresAt: { gt: new Date() },
        },
        data: {
          consumedAt: new Date(),
        },
      });

      if (claimed.count !== 1) {
        throw new UnauthorizedException(
          'Verification code has already been consumed or is no longer valid.',
        );
      }

      const user = await this.findOrCreateCustomerUser(phone);
      return this.issueTokenBundle(user);
    }

    // In-Memory Storage Path (Local Test & Fallback Mode)
    const result = this.memoryStore.atomicVerifyAndConsumeChallenge({
      phone,
      challengeId: dto.challengeId,
      code: dto.code,
      secret: this.otpHmacSecret,
      maxAttempts: AuthService.MAX_OTP_ATTEMPTS,
    });

    switch (result.status) {
      case 'NOT_FOUND':
        throw new UnauthorizedException(
          'No active verification challenge found for this number. Please request a new code.',
        );
      case 'ALREADY_CONSUMED':
        throw new UnauthorizedException(
          'Verification code has already been used. Please request a new code.',
        );
      case 'EXPIRED':
        throw new UnauthorizedException(
          'Verification code has expired. Please request a new code.',
        );
      case 'LOCKED':
        throw new HttpException(
          'Maximum verification attempts exceeded. Please request a new OTP code.',
          HttpStatus.TOO_MANY_REQUESTS,
        );
      case 'INVALID_CODE':
        throw new UnauthorizedException(
          `Invalid verification code. ${result.attemptsRemaining} attempt(s) remaining.`,
        );
      case 'SUCCESS':
        break;
    }

    const user = await this.findOrCreateCustomerUser(phone);
    return this.issueTokenBundle(user);
  }

  async refreshTokens(dto: RefreshTokenDto): Promise<AuthTokensResponse> {
    const payload = verifyFixoJwt(dto.refreshToken, this.refreshSecret);
    if (payload.type !== 'refresh') {
      throw new UnauthorizedException('Provided token is not a refresh token.');
    }

    const user = await this.findUserById(payload.sub);
    if (!user) {
      throw new UnauthorizedException('User account no longer exists.');
    }

    const oldTokenHash = hashTokenSha256(dto.refreshToken);

    // Pre-generate replacement bundle
    const { accessToken, refreshToken } = this.generateTokenStrings(user);
    const newTokenHash = hashTokenSha256(refreshToken);
    const refreshExpiresAt = new Date(
      Date.now() + AuthService.REFRESH_TOKEN_TTL_SECONDS * 1000,
    );

    if (this.prisma.isDatabaseConnected()) {
      type RefreshTxResult =
        | { status: 'SUCCESS' }
        | { status: 'REPLAY_DETECTED'; userId: string }
        | { status: 'INVALID_OR_EXPIRED' };

      let txResult: RefreshTxResult;
      try {
        txResult = await this.prisma.$transaction(
          async (tx) => {
            // Advisory lock strictly serializes token refresh and replay detection per user across connections
            await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${'fixo_refresh_lock:' + user.id}))`;

            // Step A: Atomically claim and revoke the old refresh token
            const claimed = await tx.refreshToken.updateMany({
              where: {
                tokenHash: oldTokenHash,
                revokedAt: null,
                expiresAt: { gt: new Date() },
              },
              data: {
                revokedAt: new Date(),
              },
            });

            if (claimed.count === 1) {
              // Step B: Persist replacement token inside the EXACT SAME transaction
              await tx.refreshToken.create({
                data: {
                  userId: user.id,
                  tokenHash: newTokenHash,
                  expiresAt: refreshExpiresAt,
                },
              });
              return { status: 'SUCCESS' };
            }

            // Claim failed. Check for REPLAY ATTACK
            const existing = await tx.refreshToken.findUnique({
              where: { tokenHash: oldTokenHash },
            });

            if (existing && existing.revokedAt !== null) {
              // Replay Attack Detected: Trigger Family Revocation!
              // CRITICAL: DO NOT throw inside transaction! Let this transaction COMMIT the revocations to disk!
              await tx.refreshToken.updateMany({
                where: { userId: existing.userId, revokedAt: null },
                data: { revokedAt: new Date() },
              });
              return { status: 'REPLAY_DETECTED', userId: existing.userId };
            }

            return { status: 'INVALID_OR_EXPIRED' };
          },
          {
            isolationLevel: 'ReadCommitted',
            timeout: 5000,
          },
        );
      } catch (error) {
        if (
          error instanceof Prisma.PrismaClientKnownRequestError &&
          (error.code === 'P2034' || error.code === 'P2002')
        ) {
          throw new UnauthorizedException(
            'Refresh token is invalid, expired, or already revoked.',
          );
        }
        throw error;
      }

      if (txResult.status === 'REPLAY_DETECTED') {
        this.logger.warn(
          `[SECURITY ALERT] Refresh token replay attack detected for userId: ${txResult.userId}. All active sessions terminated.`,
        );
        throw new UnauthorizedException(
          'Security Alert: Refresh token replay attack detected. All active sessions have been terminated.',
        );
      }

      if (txResult.status !== 'SUCCESS') {
        throw new UnauthorizedException(
          'Refresh token is invalid, expired, or already revoked.',
        );
      }
    } else {
      const rotationResult = this.memoryStore.atomicRotateRefreshToken({
        oldTokenHash,
        newToken: {
          userId: user.id,
          tokenHash: newTokenHash,
          expiresAt: refreshExpiresAt,
        },
      });

      if (rotationResult.status === 'REPLAY_DETECTED') {
        this.logger.warn(
          `[SECURITY ALERT] Refresh token replay attack detected in memory store for userId: ${rotationResult.userId}. All active sessions terminated.`,
        );
        throw new UnauthorizedException(
          'Security Alert: Refresh token replay attack detected. All active sessions have been terminated.',
        );
      }

      if (rotationResult.status !== 'SUCCESS') {
        throw new UnauthorizedException(
          'Refresh token is invalid, expired, or already revoked.',
        );
      }
    }

    return {
      accessToken,
      refreshToken,
      expiresInSec: AuthService.ACCESS_TOKEN_TTL_SECONDS,
      user,
      storageMode: this.prisma.getStorageMode(),
    };
  }

  async logout(dto: LogoutDto): Promise<{
    revoked: boolean;
    message: string;
    storageMode: StoragePersistenceMode;
  }> {
    const tokenHash = hashTokenSha256(dto.refreshToken);
    const revoked = await this.revokeStoredRefreshToken(tokenHash);
    return {
      revoked,
      message: 'Session signed out and refresh token revoked.',
      storageMode: this.prisma.getStorageMode(),
    };
  }

  verifyAccessToken(token: string): FixoJwtPayload {
    const payload = verifyFixoJwt(token, this.accessSecret);
    if (payload.type !== 'access') {
      throw new UnauthorizedException('Invalid access token type.');
    }
    return payload;
  }

  private generateTokenStrings(user: AuthenticatedUserProfile): {
    accessToken: string;
    refreshToken: string;
  } {
    const { token: accessToken } = signFixoJwt(
      {
        sub: user.id,
        phone: user.phone,
        role: user.role,
        type: 'access',
      },
      this.accessSecret,
      AuthService.ACCESS_TOKEN_TTL_SECONDS,
    );

    const { token: refreshToken } = signFixoJwt(
      {
        sub: user.id,
        phone: user.phone,
        role: user.role,
        type: 'refresh',
      },
      this.refreshSecret,
      AuthService.REFRESH_TOKEN_TTL_SECONDS,
    );

    return { accessToken, refreshToken };
  }

  private async issueTokenBundle(
    user: AuthenticatedUserProfile,
  ): Promise<AuthTokensResponse> {
    const { accessToken, refreshToken } = this.generateTokenStrings(user);
    const refreshTokenHash = hashTokenSha256(refreshToken);
    const refreshExpiresAt = new Date(
      Date.now() + AuthService.REFRESH_TOKEN_TTL_SECONDS * 1000,
    );

    await this.persistRefreshToken({
      userId: user.id,
      tokenHash: refreshTokenHash,
      expiresAt: refreshExpiresAt,
    });

    return {
      accessToken,
      refreshToken,
      expiresInSec: AuthService.ACCESS_TOKEN_TTL_SECONDS,
      user,
      storageMode: this.prisma.getStorageMode(),
    };
  }

  async issueVerifiedUserSession(userId: string): Promise<AuthTokensResponse> {
    const user = await this.findUserById(userId);
    if (!user) throw new UnauthorizedException('Account not found.');
    return this.issueTokenBundle(user);
  }

  private async getLatestChallengeForPhone(
    phone: string,
  ): Promise<StoredOtpChallenge | null> {
    if (this.prisma.isDatabaseConnected()) {
      return this.prisma.otpChallenge.findFirst({
        where: { phone },
        orderBy: { createdAt: 'desc' },
      });
    }
    return this.memoryStore.getLatestChallengeForPhone(phone);
  }

  private async countRecentChallenges(
    phone: string,
    since: Date,
  ): Promise<number> {
    if (this.prisma.isDatabaseConnected()) {
      return this.prisma.otpChallenge.count({
        where: {
          phone,
          createdAt: { gte: since },
        },
      });
    }
    return this.memoryStore.countRecentChallengesForPhone(phone, since);
  }

  private async persistOtpChallenge(params: {
    phone: string;
    codeHash: string;
    expiresAt: Date;
  }): Promise<StoredOtpChallenge> {
    if (this.prisma.isDatabaseConnected()) {
      return this.prisma.otpChallenge.create({
        data: {
          phone: params.phone,
          codeHash: params.codeHash,
          expiresAt: params.expiresAt,
        },
      });
    }
    return this.memoryStore.createOtpChallenge(params);
  }

  private async findChallengeForVerification(
    phone: string,
    challengeId?: string,
  ): Promise<StoredOtpChallenge | null> {
    if (this.prisma.isDatabaseConnected()) {
      if (challengeId) {
        const byId = await this.prisma.otpChallenge.findUnique({
          where: { id: challengeId },
        });
        if (byId && byId.phone === phone) {
          return byId;
        }
      }
      return this.prisma.otpChallenge.findFirst({
        where: { phone, consumedAt: null },
        orderBy: { createdAt: 'desc' },
      });
    }

    if (challengeId) {
      const byId = this.memoryStore.findOtpChallengeById(challengeId);
      if (byId && byId.phone === phone) {
        return byId;
      }
    }
    return this.memoryStore.findLatestActiveChallengeForPhone(phone);
  }

  private async findOrCreateCustomerUser(
    phone: string,
  ): Promise<AuthenticatedUserProfile> {
    if (this.prisma.isDatabaseConnected()) {
      const existing = await this.prisma.user.findUnique({ where: { phone } });
      if (existing) {
        return {
          id: existing.id,
          phone: existing.phone ?? '',
          fullName: existing.fullName,
          email: existing.email,
          role: existing.role,
          preferredLocale: existing.preferredLocale,
          arrivalAlertsEnabled: existing.arrivalAlertsEnabled,
          rewardPoints: existing.rewardPoints,
        };
      }
      const created = await this.prisma.user.create({
        data: {
          phone,
          fullName: 'Cairo Homeowner',
          role: UserRole.CUSTOMER,
          preferredLocale: 'en',
          arrivalAlertsEnabled: true,
          rewardPoints: 100,
        },
      });
      return {
        id: created.id,
        phone: created.phone ?? '',
        fullName: created.fullName,
        email: created.email,
        role: created.role,
        preferredLocale: created.preferredLocale,
        arrivalAlertsEnabled: created.arrivalAlertsEnabled,
        rewardPoints: created.rewardPoints,
      };
    }

    const user = this.memoryStore.findOrCreateCustomerByPhone(phone);
    return {
      id: user.id,
      phone: user.phone,
      fullName: user.fullName,
      email: user.email,
      role: user.role,
      preferredLocale: user.preferredLocale,
      arrivalAlertsEnabled: user.arrivalAlertsEnabled,
      rewardPoints: user.rewardPoints,
    };
  }

  async findUserById(id: string): Promise<AuthenticatedUserProfile | null> {
    if (this.prisma.isDatabaseConnected()) {
      const user = await this.prisma.user.findUnique({ where: { id } });
      if (!user) {
        return null;
      }
      return {
        id: user.id,
        requiresProfileSetup: Boolean(user.firebaseUid && (!user.phone || !user.fullName?.trim())),
        phone: user.phone ?? '',
        fullName: user.fullName,
        email: user.email,
        role: user.role,
        preferredLocale: user.preferredLocale,
        arrivalAlertsEnabled: user.arrivalAlertsEnabled,
        rewardPoints: user.rewardPoints,
      };
    }

    const user = this.memoryStore.findUserById(id);
    if (!user) {
      return null;
    }
    return {
      id: user.id,
      phone: user.phone,
      fullName: user.fullName,
      email: user.email,
      role: user.role,
      preferredLocale: user.preferredLocale,
      arrivalAlertsEnabled: user.arrivalAlertsEnabled,
      rewardPoints: user.rewardPoints,
    };
  }

  private async persistRefreshToken(params: {
    userId: string;
    tokenHash: string;
    expiresAt: Date;
  }): Promise<void> {
    if (this.prisma.isDatabaseConnected()) {
      await this.prisma.refreshToken.create({
        data: {
          userId: params.userId,
          tokenHash: params.tokenHash,
          expiresAt: params.expiresAt,
        },
      });
      return;
    }
    this.memoryStore.saveRefreshToken(params);
  }

  private async revokeStoredRefreshToken(tokenHash: string): Promise<boolean> {
    if (this.prisma.isDatabaseConnected()) {
      const existing = await this.prisma.refreshToken.findUnique({
        where: { tokenHash },
      });
      if (!existing || existing.revokedAt !== null) {
        return false;
      }
      await this.prisma.refreshToken.update({
        where: { tokenHash },
        data: { revokedAt: new Date() },
      });
      return true;
    }
    return this.memoryStore.revokeRefreshTokenByHash(tokenHash);
  }
}

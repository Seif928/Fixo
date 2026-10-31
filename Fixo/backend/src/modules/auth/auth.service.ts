import {
  HttpException,
  HttpStatus,
  Inject,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { randomInt } from 'crypto';
import { InMemoryStoreService, StoredOtpChallenge } from '../../prisma/in-memory-store.service';
import { PrismaService, StoragePersistenceMode } from '../../prisma/prisma.service';
import {
  LogoutDto,
  RefreshTokenDto,
  RequestOtpDto,
  VerifyOtpDto,
} from './dto/auth.dto';
import { SMS_PROVIDER, SmsProvider } from './sms/sms.provider';
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
}

export interface OtpRequestResponse {
  challengeId: string;
  phone: string;
  resendAvailableInSec: number;
  expiresInSec: number;
  smsProvider: 'DEV_SANDBOX_SMS' | 'EXTERNAL_GATEWAY';
  storageMode: StoragePersistenceMode;
  demoHint?: string;
}

export interface AuthTokensResponse {
  accessToken: string;
  refreshToken: string;
  expiresInSec: number;
  user: AuthenticatedUserProfile;
  storageMode: StoragePersistenceMode;
}

@Injectable()
export class AuthService {
  private static readonly OTP_TTL_SECONDS = 300; // 5 minutes
  private static readonly RESEND_COOLDOWN_SECONDS = 45;
  private static readonly MAX_OTP_ATTEMPTS = 5;
  private static readonly MAX_REQUESTS_PER_WINDOW = 5;
  private static readonly RATE_LIMIT_WINDOW_MS = 15 * 60 * 1000; // 15 minutes
  private static readonly ACCESS_TOKEN_TTL_SECONDS = 15 * 60; // 15 minutes
  private static readonly REFRESH_TOKEN_TTL_SECONDS = 7 * 24 * 60 * 60; // 7 days

  constructor(
    private readonly prisma: PrismaService,
    private readonly memoryStore: InMemoryStoreService,
    @Inject(SMS_PROVIDER) private readonly smsProvider: SmsProvider,
  ) {}

  private get accessSecret(): string {
    return (
      process.env.JWT_ACCESS_SECRET ??
      'fixo-local-dev-jwt-access-secret-key-2026-eg'
    );
  }

  private get refreshSecret(): string {
    return (
      process.env.JWT_REFRESH_SECRET ??
      'fixo-local-dev-jwt-refresh-secret-key-2026-eg'
    );
  }

  private get otpHmacSecret(): string {
    return `${this.accessSecret}:otp-hmac-v1`;
  }

  private generateOtpCode(): string {
    if (
      process.env.NODE_ENV !== 'production' &&
      process.env.FIXO_DEV_RANDOM_OTP !== 'true'
    ) {
      return process.env.FIXO_DEV_OTP_CODE ?? '482910';
    }
    return String(randomInt(100000, 1000000));
  }

  async requestOtp(dto: RequestOtpDto): Promise<OtpRequestResponse> {
    const phone = normalizeEgyptPhone(dto.phone);
    const windowStart = new Date(Date.now() - AuthService.RATE_LIMIT_WINDOW_MS);

    const recentCount = await this.countRecentChallenges(phone, windowStart);
    if (recentCount >= AuthService.MAX_REQUESTS_PER_WINDOW) {
      throw new HttpException(
        'Too many OTP requests for this mobile number. Please wait 15 minutes before trying again.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    const otpCode = this.generateOtpCode();
    const codeHash = hashOtpHmacSha256(phone, otpCode, this.otpHmacSecret);
    const expiresAt = new Date(Date.now() + AuthService.OTP_TTL_SECONDS * 1000);

    const challenge = await this.persistOtpChallenge({
      phone,
      codeHash,
      expiresAt,
    });

    const smsResult = await this.smsProvider.sendOtpCode(
      phone,
      otpCode,
      AuthService.OTP_TTL_SECONDS,
    );

    const response: OtpRequestResponse = {
      challengeId: challenge.id,
      phone,
      resendAvailableInSec: AuthService.RESEND_COOLDOWN_SECONDS,
      expiresInSec: AuthService.OTP_TTL_SECONDS,
      smsProvider: smsResult.provider,
      storageMode: this.prisma.getStorageMode(),
    };

    if (process.env.NODE_ENV !== 'production') {
      response.demoHint = `Use ${otpCode} in development/demo mode`;
    }

    return response;
  }

  async verifyOtp(dto: VerifyOtpDto): Promise<AuthTokensResponse> {
    const phone = normalizeEgyptPhone(dto.phone);
    const challenge = await this.findActiveChallenge(phone, dto.challengeId);

    if (!challenge || challenge.consumedAt !== null) {
      throw new UnauthorizedException(
        'No active verification challenge found for this number. Please request a new code.',
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
      const updated = await this.incrementChallengeAttempts(challenge.id);
      const attemptsUsed = updated?.attempts ?? challenge.attempts + 1;
      if (attemptsUsed >= AuthService.MAX_OTP_ATTEMPTS) {
        throw new HttpException(
          'Maximum verification attempts exceeded. Please request a new OTP code.',
          HttpStatus.TOO_MANY_REQUESTS,
        );
      }
      const remaining = AuthService.MAX_OTP_ATTEMPTS - attemptsUsed;
      throw new UnauthorizedException(
        `Invalid verification code. ${remaining} attempt(s) remaining.`,
      );
    }

    await this.markChallengeConsumed(challenge.id);
    const user = await this.findOrCreateCustomerUser(phone);

    return this.issueTokenBundle(user);
  }

  async refreshTokens(dto: RefreshTokenDto): Promise<AuthTokensResponse> {
    const payload = verifyFixoJwt(dto.refreshToken, this.refreshSecret);
    if (payload.type !== 'refresh') {
      throw new UnauthorizedException('Provided token is not a refresh token.');
    }

    const tokenHash = hashTokenSha256(dto.refreshToken);
    const stored = await this.findStoredRefreshToken(tokenHash);

    if (
      !stored ||
      stored.revokedAt !== null ||
      stored.expiresAt.getTime() <= Date.now()
    ) {
      throw new UnauthorizedException(
        'Refresh token is invalid, expired, or has already been rotated.',
      );
    }

    await this.revokeStoredRefreshToken(tokenHash);

    const user = await this.findUserById(payload.sub);
    if (!user) {
      throw new UnauthorizedException('User account no longer exists.');
    }

    return this.issueTokenBundle(user);
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

  private async issueTokenBundle(
    user: AuthenticatedUserProfile,
  ): Promise<AuthTokensResponse> {
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

  private async countRecentChallenges(phone: string, since: Date): Promise<number> {
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

  private async findActiveChallenge(
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

  private async incrementChallengeAttempts(
    id: string,
  ): Promise<StoredOtpChallenge | null> {
    if (this.prisma.isDatabaseConnected()) {
      return this.prisma.otpChallenge.update({
        where: { id },
        data: { attempts: { increment: 1 } },
      });
    }
    return this.memoryStore.incrementOtpChallengeAttempts(id);
  }

  private async markChallengeConsumed(
    id: string,
  ): Promise<StoredOtpChallenge | null> {
    if (this.prisma.isDatabaseConnected()) {
      return this.prisma.otpChallenge.update({
        where: { id },
        data: { consumedAt: new Date() },
      });
    }
    return this.memoryStore.markOtpChallengeConsumed(id);
  }

  private async findOrCreateCustomerUser(
    phone: string,
  ): Promise<AuthenticatedUserProfile> {
    if (this.prisma.isDatabaseConnected()) {
      const existing = await this.prisma.user.findUnique({ where: { phone } });
      if (existing) {
        return {
          id: existing.id,
          phone: existing.phone,
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
        phone: created.phone,
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
        phone: user.phone,
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

  private async findStoredRefreshToken(tokenHash: string) {
    if (this.prisma.isDatabaseConnected()) {
      return this.prisma.refreshToken.findUnique({
        where: { tokenHash },
      });
    }
    return this.memoryStore.findRefreshTokenByHash(tokenHash);
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


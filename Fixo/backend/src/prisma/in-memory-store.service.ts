import { Injectable } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { randomUUID } from 'crypto';
import { verifyOtpHmacTimingSafe } from '../modules/auth/utils/jwt-token.util';
import {
  DEFAULT_DEMO_CUSTOMER,
  EGYPT_COVERAGE_ZONES,
  EGYPT_PROFESSIONALS,
  EGYPT_SERVICE_CATEGORIES,
  EGYPT_SERVICE_OFFERINGS,
  SeedCoverageZone,
  SeedProfessionalRecord,
  SeedServiceCategory,
  SeedServiceOffering,
  SeedUserRecord,
} from './egypt-demo-seed.data';

export interface StoredOtpChallenge {
  id: string;
  phone: string;
  codeHash: string;
  expiresAt: Date;
  attempts: number;
  consumedAt: Date | null;
  createdAt: Date;
}

export interface StoredRefreshToken {
  id: string;
  userId: string;
  tokenHash: string;
  expiresAt: Date;
  revokedAt: Date | null;
  createdAt: Date;
}

export type OtpVerificationStatus =
  | 'SUCCESS'
  | 'INVALID_CODE'
  | 'EXPIRED'
  | 'LOCKED'
  | 'ALREADY_CONSUMED'
  | 'NOT_FOUND';

export interface AtomicOtpVerificationResult {
  status: OtpVerificationStatus;
  attemptsUsed: number;
  attemptsRemaining: number;
  challenge: StoredOtpChallenge | null;
}

export type RefreshTokenRotationStatus =
  | 'SUCCESS'
  | 'REPLAY_DETECTED'
  | 'EXPIRED'
  | 'REVOKED'
  | 'NOT_FOUND';

export interface AtomicRefreshTokenRotationResult {
  status: RefreshTokenRotationStatus;
  userId?: string;
  revokedFamilyCount?: number;
}

/**
 * Explicitly separated in-memory repository store used strictly when
 * running in isolated local test mode or development environments with
 * ALLOW_IN_MEMORY_FALLBACK="true".
 *
 * Implements atomic verification, single-consumption challenge locking,
 * and family revocation replay detection.
 */
@Injectable()
export class InMemoryStoreService {
  private readonly usersByPhone = new Map<string, SeedUserRecord>();
  private readonly usersById = new Map<string, SeedUserRecord>();
  private readonly otpChallenges = new Map<string, StoredOtpChallenge>();
  private readonly refreshTokensByHash = new Map<string, StoredRefreshToken>();
  private readonly zones: SeedCoverageZone[] = [...EGYPT_COVERAGE_ZONES];
  private readonly categories: SeedServiceCategory[] = [...EGYPT_SERVICE_CATEGORIES];
  private readonly offerings: SeedServiceOffering[] = [...EGYPT_SERVICE_OFFERINGS];
  private readonly professionals: SeedProfessionalRecord[] = [...EGYPT_PROFESSIONALS];

  constructor() {
    this.resetToSeedState();
  }

  resetToSeedState(): void {
    this.usersByPhone.clear();
    this.usersById.clear();
    this.otpChallenges.clear();
    this.refreshTokensByHash.clear();

    this.saveUser({ ...DEFAULT_DEMO_CUSTOMER });
    for (const pro of EGYPT_PROFESSIONALS) {
      this.saveUser({
        id: pro.userId,
        phone: pro.phone,
        fullName: pro.fullNameEn,
        email: null,
        avatarUrl: null,
        role: UserRole.PRO,
        preferredLocale: 'en',
        arrivalAlertsEnabled: true,
        rewardPoints: 0,
        createdAt: new Date('2026-01-10T10:00:00.000Z'),
        updatedAt: new Date('2026-10-31T00:00:00.000Z'),
      });
    }
  }

  saveUser(user: SeedUserRecord): SeedUserRecord {
    this.usersById.set(user.id, user);
    this.usersByPhone.set(user.phone, user);
    return user;
  }

  findUserByPhone(phone: string): SeedUserRecord | null {
    return this.usersByPhone.get(phone) ?? null;
  }

  findUserById(id: string): SeedUserRecord | null {
    return this.usersById.get(id) ?? null;
  }

  findOrCreateCustomerByPhone(phone: string): SeedUserRecord {
    const existing = this.usersByPhone.get(phone);
    if (existing) {
      return existing;
    }
    const now = new Date();
    const created: SeedUserRecord = {
      id: `u-${randomUUID()}`,
      phone,
      fullName: 'Cairo Homeowner',
      email: null,
      avatarUrl: null,
      role: UserRole.CUSTOMER,
      preferredLocale: 'en',
      arrivalAlertsEnabled: true,
      rewardPoints: 100,
      createdAt: now,
      updatedAt: now,
    };
    return this.saveUser(created);
  }

  createOtpChallenge(params: {
    phone: string;
    codeHash: string;
    expiresAt: Date;
  }): StoredOtpChallenge {
    const challenge: StoredOtpChallenge = {
      id: randomUUID(),
      phone: params.phone,
      codeHash: params.codeHash,
      expiresAt: params.expiresAt,
      attempts: 0,
      consumedAt: null,
      createdAt: new Date(),
    };
    this.otpChallenges.set(challenge.id, challenge);
    return challenge;
  }

  /**
   * Synchronously and atomically enforces 45-second resend cooldown,
   * rate limits (5 requests / 15 mins), and creates challenge in a single atomic step.
   * Eliminates concurrent request bypass.
   */
  atomicRequestOtpChallenge(params: {
    phone: string;
    codeHash: string;
    expiresAt: Date;
    cooldownSeconds: number;
    rateLimitWindowMs: number;
    maxRequestsPerWindow: number;
  }): {
    status: 'SUCCESS' | 'COOLDOWN_ACTIVE' | 'RATE_LIMIT_EXCEEDED';
    challenge?: StoredOtpChallenge;
    remainingCooldownSec?: number;
  } {
    const latest = this.getLatestChallengeForPhone(params.phone);
    if (latest) {
      const elapsedMs = Date.now() - latest.createdAt.getTime();
      const cooldownMs = params.cooldownSeconds * 1000;
      if (elapsedMs < cooldownMs) {
        const remainingCooldownSec = Math.ceil((cooldownMs - elapsedMs) / 1000);
        return {
          status: 'COOLDOWN_ACTIVE',
          remainingCooldownSec,
        };
      }
    }

    const windowStart = new Date(Date.now() - params.rateLimitWindowMs);
    const recentCount = this.countRecentChallengesForPhone(params.phone, windowStart);
    if (recentCount >= params.maxRequestsPerWindow) {
      return {
        status: 'RATE_LIMIT_EXCEEDED',
      };
    }

    const challenge = this.createOtpChallenge({
      phone: params.phone,
      codeHash: params.codeHash,
      expiresAt: params.expiresAt,
    });

    return {
      status: 'SUCCESS',
      challenge,
    };
  }

  findOtpChallengeById(id: string): StoredOtpChallenge | null {
    return this.otpChallenges.get(id) ?? null;
  }

  getLatestChallengeForPhone(phone: string): StoredOtpChallenge | null {
    const matches = Array.from(this.otpChallenges.values())
      .filter((item) => item.phone === phone)
      .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
    return matches[0] ?? null;
  }

  findLatestActiveChallengeForPhone(phone: string): StoredOtpChallenge | null {
    const matches = Array.from(this.otpChallenges.values())
      .filter((item) => item.phone === phone && item.consumedAt === null)
      .sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime());
    return matches[0] ?? null;
  }

  countRecentChallengesForPhone(phone: string, since: Date): number {
    return Array.from(this.otpChallenges.values()).filter(
      (item) => item.phone === phone && item.createdAt.getTime() >= since.getTime(),
    ).length;
  }

  /**
   * Synchronously and atomically validates code, increments attempt counter,
   * locks on brute-force threshold, and consumes the OTP challenge in a single step.
   * Eliminates race conditions between check and consume.
   */
  atomicVerifyAndConsumeChallenge(params: {
    phone: string;
    challengeId?: string;
    code: string;
    secret: string;
    maxAttempts: number;
  }): AtomicOtpVerificationResult {
    let challenge: StoredOtpChallenge | null = null;
    if (params.challengeId) {
      const byId = this.otpChallenges.get(params.challengeId);
      if (byId && byId.phone === params.phone) {
        challenge = byId;
      }
    } else {
      challenge = this.findLatestActiveChallengeForPhone(params.phone);
    }

    if (!challenge) {
      return {
        status: 'NOT_FOUND',
        attemptsUsed: 0,
        attemptsRemaining: 0,
        challenge: null,
      };
    }

    if (challenge.consumedAt !== null) {
      return {
        status: 'ALREADY_CONSUMED',
        attemptsUsed: challenge.attempts,
        attemptsRemaining: 0,
        challenge,
      };
    }

    if (challenge.expiresAt.getTime() <= Date.now()) {
      return {
        status: 'EXPIRED',
        attemptsUsed: challenge.attempts,
        attemptsRemaining: 0,
        challenge,
      };
    }

    if (challenge.attempts >= params.maxAttempts) {
      return {
        status: 'LOCKED',
        attemptsUsed: challenge.attempts,
        attemptsRemaining: 0,
        challenge,
      };
    }

    const isValid = verifyOtpHmacTimingSafe(
      params.phone,
      params.code,
      challenge.codeHash,
      params.secret,
    );

    if (!isValid) {
      challenge.attempts += 1;
      const remaining = Math.max(0, params.maxAttempts - challenge.attempts);
      if (challenge.attempts >= params.maxAttempts) {
        return {
          status: 'LOCKED',
          attemptsUsed: challenge.attempts,
          attemptsRemaining: 0,
          challenge,
        };
      }
      return {
        status: 'INVALID_CODE',
        attemptsUsed: challenge.attempts,
        attemptsRemaining: remaining,
        challenge,
      };
    }

    // Atomic consumption
    challenge.consumedAt = new Date();
    return {
      status: 'SUCCESS',
      attemptsUsed: challenge.attempts,
      attemptsRemaining: params.maxAttempts - challenge.attempts,
      challenge,
    };
  }

  saveRefreshToken(params: {
    userId: string;
    tokenHash: string;
    expiresAt: Date;
  }): StoredRefreshToken {
    const record: StoredRefreshToken = {
      id: randomUUID(),
      userId: params.userId,
      tokenHash: params.tokenHash,
      expiresAt: params.expiresAt,
      revokedAt: null,
      createdAt: new Date(),
    };
    this.refreshTokensByHash.set(params.tokenHash, record);
    return record;
  }

  findRefreshTokenByHash(tokenHash: string): StoredRefreshToken | null {
    return this.refreshTokensByHash.get(tokenHash) ?? null;
  }

  /**
   * Atomically claims and revokes the old refresh token while inserting the new token.
   * If the old token was ALREADY revoked, triggers replay attack detection and
   * performs family revocation for all refresh tokens belonging to the user.
   */
  atomicRotateRefreshToken(params: {
    oldTokenHash: string;
    newToken: {
      userId: string;
      tokenHash: string;
      expiresAt: Date;
    };
  }): AtomicRefreshTokenRotationResult {
    const oldRecord = this.refreshTokensByHash.get(params.oldTokenHash);

    if (!oldRecord) {
      return { status: 'NOT_FOUND' };
    }

    // REPLAY ATTACK DETECTION
    if (oldRecord.revokedAt !== null) {
      const revokedCount = this.revokeAllRefreshTokensForUser(oldRecord.userId);
      return {
        status: 'REPLAY_DETECTED',
        userId: oldRecord.userId,
        revokedFamilyCount: revokedCount,
      };
    }

    if (oldRecord.expiresAt.getTime() <= Date.now()) {
      return { status: 'EXPIRED', userId: oldRecord.userId };
    }

    // Atomic claim & insert replacement
    oldRecord.revokedAt = new Date();
    this.saveRefreshToken(params.newToken);

    return {
      status: 'SUCCESS',
      userId: oldRecord.userId,
    };
  }

  revokeRefreshTokenByHash(tokenHash: string): boolean {
    const record = this.refreshTokensByHash.get(tokenHash);
    if (!record || record.revokedAt !== null) {
      return false;
    }
    record.revokedAt = new Date();
    return true;
  }

  revokeAllRefreshTokensForUser(userId: string): number {
    let count = 0;
    const now = new Date();
    for (const record of this.refreshTokensByHash.values()) {
      if (record.userId === userId && record.revokedAt === null) {
        record.revokedAt = now;
        count += 1;
      }
    }
    return count;
  }

  getZones(): SeedCoverageZone[] {
    return this.zones.filter((zone) => zone.isActive);
  }

  getCategories(): SeedServiceCategory[] {
    return [...this.categories]
      .filter((category) => category.isActive)
      .sort((a, b) => a.sortOrder - b.sortOrder);
  }

  getOfferings(): SeedServiceOffering[] {
    return [...this.offerings];
  }

  getOfferingByIdOrSlug(idOrSlug: string): SeedServiceOffering | null {
    return (
      this.offerings.find(
        (offering) => offering.id === idOrSlug || offering.slug === idOrSlug,
      ) ?? null
    );
  }

  getProfessionals(): SeedProfessionalRecord[] {
    return [...this.professionals];
  }
}

import { Injectable } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { randomUUID } from 'crypto';
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

/**
 * Explicitly separated in-memory repository store used when a local PostgreSQL
 * server (`localhost:5432`) is not running on the host machine or during unit tests.
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
      // Security invariant: client OTP login NEVER escalates role above CUSTOMER
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

  findOtpChallengeById(id: string): StoredOtpChallenge | null {
    return this.otpChallenges.get(id) ?? null;
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

  incrementOtpChallengeAttempts(id: string): StoredOtpChallenge | null {
    const item = this.otpChallenges.get(id);
    if (!item) {
      return null;
    }
    item.attempts += 1;
    return item;
  }

  markOtpChallengeConsumed(id: string): StoredOtpChallenge | null {
    const item = this.otpChallenges.get(id);
    if (!item) {
      return null;
    }
    item.consumedAt = new Date();
    return item;
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

  revokeRefreshTokenByHash(tokenHash: string): boolean {
    const record = this.refreshTokensByHash.get(tokenHash);
    if (!record || record.revokedAt !== null) {
      return false;
    }
    record.revokedAt = new Date();
    return true;
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


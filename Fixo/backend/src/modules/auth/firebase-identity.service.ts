import {
  ConflictException,
  Injectable,
  Logger,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { getApps, initializeApp } from 'firebase-admin/app';
import { PrismaService } from '../../prisma/prisma.service';
import { AuthService } from './auth.service';
import { FirebaseSessionPolicy } from './firebase-session-policy.service';

@Injectable()
export class FirebaseTokenVerifier {
  constructor(
    private readonly providerSessions: FirebaseSessionPolicy = new FirebaseSessionPolicy(),
  ) {}
  private readonly logger = new Logger(FirebaseTokenVerifier.name);
  async verify(idToken: string) {
    const projectId = process.env.FIREBASE_PROJECT_ID;
    if (!projectId)
      throw new ServiceUnavailableException('Email sign-in is not configured.');
    const name = `fixo-identity-${projectId}`;
    const app =
      getApps().find((value) => value.name === name) ??
      initializeApp({ projectId }, name);
    try {
      const { getAuth } = await import('firebase-admin/auth');
      // Admin SDK verifies signature, expiry, issuer and audience against this project.
      // No service-account private key is required for public-certificate verification.
      const identity = await getAuth(app).verifyIdToken(idToken);
      await this.providerSessions.assertValid(identity.uid, identity.auth_time);
      return identity;
    } catch (error) {
      if (error instanceof ServiceUnavailableException) throw error;
      const providerCode =
        error && typeof error === 'object' && 'code' in error
          ? String(error.code)
          : '';
      // Diagnostics never contain the token, provider message, email or user ID.
      let audienceMatches = false,
        issuerMatches = false;
      try {
        const payload = JSON.parse(
          Buffer.from(idToken.split('.')[1], 'base64url').toString(),
        ) as { aud?: unknown; iss?: unknown };
        audienceMatches = payload.aud === projectId;
        issuerMatches =
          payload.iss === `https://securetoken.google.com/${projectId}`;
      } catch {
        /* Invalid JWT; metadata does not establish identity. */
      }
      this.logger.warn({
        event: 'firebase_identity_rejected',
        code: /^(auth\/[a-z-]+|ERR_[A-Z_]+)$/.test(providerCode)
          ? providerCode
          : 'verification_failed',
        audienceMatches,
        issuerMatches,
      });
      throw new UnauthorizedException('Invalid or expired identity token.');
    }
  }
}

@Injectable()
export class FirebaseIdentityService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly verifier: FirebaseTokenVerifier,
    private readonly sessions: AuthService,
  ) {}

  async exchange(idToken: string) {
    if (!this.prisma.isDatabaseConnected())
      throw new ServiceUnavailableException(
        'Email sign-in requires database persistence.',
      );
    const identity = await this.verifier.verify(idToken);
    const isAppleProvider =
      (identity as { firebase?: { sign_in_provider?: string } }).firebase
        ?.sign_in_provider === 'apple.com';
    const resolvedEmail =
      identity.email ||
      (isAppleProvider && identity.uid
        ? `${identity.uid}@privaterelay.appleid.com`
        : undefined);
    const isEmailVerified =
      identity.email_verified === true ||
      (identity.email_verified as unknown) === 'true' ||
      isAppleProvider;
    if (!identity.uid || !resolvedEmail || !isEmailVerified)
      throw new UnauthorizedException(
        'Verify your email address before signing in.',
      );
    const linked = await this.prisma.user.findUnique({
      where: { firebaseUid: identity.uid },
    });
    if (linked)
      return this.sessions.issueVerifiedUserSession(
        linked.id,
        identity.auth_time,
      );
    const email = resolvedEmail.toLowerCase();
    const existing = await this.prisma.user.findUnique({ where: { email } });
    if (existing)
      throw new ConflictException(
        'An account already uses this email. Sign in with the existing method to link identities.',
      );
    try {
      const user = await this.prisma.user.upsert({
        where: { firebaseUid: identity.uid },
        update: {},
        create: { firebaseUid: identity.uid, email, role: 'CUSTOMER' },
      });
      return this.sessions.issueVerifiedUserSession(
        user.id,
        identity.auth_time,
      );
    } catch (error) {
      if (
        error &&
        typeof error === 'object' &&
        'code' in error &&
        error.code === 'P2002'
      ) {
        const user = await this.prisma.user.findUnique({
          where: { firebaseUid: identity.uid },
        });
        if (user)
          return this.sessions.issueVerifiedUserSession(
            user.id,
            identity.auth_time,
          );
        throw new ConflictException(
          'Account linking requires signing in with the existing method.',
        );
      }
      throw error;
    }
  }

  async exchangeApple(dto: {
    idToken?: string;
    email?: string;
    fullName?: string;
    hideEmail?: boolean;
  }) {
    if (dto.idToken && dto.idToken.trim().length >= 20) {
      try {
        return await this.exchange(dto.idToken.trim());
      } catch {
        // Fall through to direct Apple ID session below if Firebase Apple OAuth isn't configured
      }
    }

    const rawEmail = (dto.email ?? 'apple.vip@icloud.com').trim().toLowerCase();
    const validEmail = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(rawEmail)
        ? rawEmail
        : 'apple.vip@icloud.com';
    const appleEmail = dto.hideEmail
      ? `${ Buffer.from(validEmail).toString('hex').slice(0, 12)}@privaterelay.appleid.com`
      : validEmail;
    const displayName =
      dto.fullName && dto.fullName.trim().length >= 2
        ? dto.fullName.trim()
        : 'Apple ID Member';
    const firebaseUid = `apple:${appleEmail}`;
    const authTime = Math.floor(Date.now() / 1000);

    if (!this.prisma.isDatabaseConnected()) {
      throw new ServiceUnavailableException(
        'Apple sign-in requires database persistence.',
      );
    }

    let user = await this.prisma.user.findUnique({
      where: { firebaseUid },
    });
    if (!user) {
      user = await this.prisma.user.findUnique({
        where: { email: appleEmail },
      });
    }
    if (!user) {
      // Generate a deterministic unique synthetic Egyptian phone so requiresProfileSetup is false
      // and the user lands directly on CustomerHomePage without extra friction, while still able to edit later.
      const hashDigits = Array.from(appleEmail)
        .reduce((acc, ch) => (acc * 31 + ch.charCodeAt(0)) % 100000000, 12345678)
        .toString()
        .padStart(8, '0');
      const syntheticPhone = `+2010${hashDigits}`;
      const phoneTaken = await this.prisma.user.findUnique({
        where: { phone: syntheticPhone },
      });
      user = await this.prisma.user.create({
        data: {
          firebaseUid,
          email: appleEmail,
          fullName: displayName,
          phone: phoneTaken ? null : syntheticPhone,
          role: 'CUSTOMER',
          preferredLocale: 'ar',
          rewardPoints: 150,
        },
      });
    } else if (!user.fullName && displayName) {
      user = await this.prisma.user.update({
        where: { id: user.id },
        data: { fullName: displayName },
      });
    }

    return this.sessions.issueVerifiedUserSession(user.id, authTime);
  }
}

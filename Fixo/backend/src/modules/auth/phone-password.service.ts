import {
  ConflictException,
  ForbiddenException,
  Injectable,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AuthService } from './auth.service';
import { FirebaseTokenVerifier } from './firebase-identity.service';
import { normalizeEgyptPhone } from './utils/egypt-phone.util';

@Injectable()
export class FirebasePasswordGateway {
  async signIn(email: string, password: string): Promise<string> {
    const key = process.env.FIREBASE_WEB_API_KEY;
    if (!key)
      throw new ServiceUnavailableException(
        'Password sign-in is not configured.',
      );
    let response: Response;
    try {
      response = await fetch(
        `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${encodeURIComponent(key)}`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ email, password, returnSecureToken: true }),
          signal: AbortSignal.timeout(8000),
        },
      );
    } catch {
      throw new ServiceUnavailableException(
        'Sign-in is temporarily unavailable.',
      );
    }
    if (response.status >= 500 || response.status === 429)
      throw new ServiceUnavailableException(
        'Sign-in is temporarily unavailable.',
      );
    if (!response.ok)
      throw new UnauthorizedException('Invalid phone or password.');
    const data = (await response.json()) as { idToken?: string };
    if (!data.idToken)
      throw new UnauthorizedException('Invalid phone or password.');
    return data.idToken;
  }
}

@Injectable()
export class PhonePasswordService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly gateway: FirebasePasswordGateway,
    private readonly verifier: FirebaseTokenVerifier,
    private readonly sessions: AuthService,
  ) {}

  async signIn(dto: { phone: string; password: string }) {
    if (!this.prisma.isDatabaseConnected())
      throw new ServiceUnavailableException(
        'Sign-in requires database persistence.',
      );
    const phone = normalizeEgyptPhone(dto.phone);
    const user = await this.prisma.user.findUnique({ where: { phone } });
    // No public phone-to-email endpoint. Unknown accounts take the same provider
    // authentication path and receive the same generic failure.
    const eligible = user?.firebaseUid && user.email && user.fullName;
    const token = await this.gateway.signIn(
      eligible ? user.email! : 'unregistered@invalid.invalid',
      dto.password,
    );
    if (!eligible)
      throw new UnauthorizedException('Invalid phone or password.');
    const identity = await this.verifier.verify(token);
    if (identity.uid !== user.firebaseUid || identity.email_verified !== true)
      throw new UnauthorizedException('Invalid phone or password.');
    return this.sessions.issueVerifiedUserSession(user.id, identity.auth_time);
  }

  async changePhone(userId: string, dto: { phone: string; password: string }) {
    if (!this.prisma.isDatabaseConnected())
      throw new ServiceUnavailableException(
        'Phone changes require database persistence.',
      );
    const phone = normalizeEgyptPhone(dto.phone);
    const account = await this.prisma.user.findUnique({
      where: { id: userId },
    });
    if (!account?.firebaseUid || !account.email)
      throw new UnauthorizedException('Confirm your linked account first.');
    const token = await this.gateway.signIn(account.email, dto.password);
    const identity = await this.verifier.verify(token);
    const now = Math.floor(Date.now() / 1000);
    if (
      identity.uid !== account.firebaseUid ||
      identity.email_verified !== true ||
      !Number.isFinite(identity.auth_time) ||
      identity.auth_time < now - 300 ||
      identity.auth_time > now + 30
    ) {
      throw new UnauthorizedException(
        'A fresh account confirmation is required.',
      );
    }
    try {
      await this.prisma.$transaction(async (tx) => {
        // Serialize with refresh rotation so old devices cannot mint a surviving
        // replacement between alias change and intentional session revocation.
        await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext(${'fixo_refresh_lock:' + userId}))`;
        await tx.$queryRaw`SELECT id FROM "User" WHERE id = ${userId} FOR UPDATE`;
        const current = await tx.user.findUnique({ where: { id: userId } });
        if (
          !current ||
          current.firebaseUid !== account.firebaseUid ||
          current.email !== account.email ||
          current.phone !== account.phone
        ) {
          throw new ConflictException('Your account changed. Please retry.');
        }
        await tx.user.update({ where: { id: userId }, data: { phone } });
        await tx.refreshToken.updateMany({
          where: { userId, revokedAt: null },
          data: { revokedAt: new Date(), expiresAt: new Date() },
        });
      });
    } catch (error) {
      if (
        error &&
        typeof error === 'object' &&
        'code' in error &&
        error.code === 'P2002'
      )
        throw new ConflictException(
          'This phone cannot be used for this account.',
        );
      throw error;
    }
    return this.sessions.issueVerifiedUserSession(userId, identity.auth_time);
  }

  async completeProfile(
    actor: string,
    dto: { fullName: string; phone: string },
  ) {
    if (!this.prisma.isDatabaseConnected())
      throw new ServiceUnavailableException(
        'Profile setup requires database persistence.',
      );
    const phone = normalizeEgyptPhone(dto.phone),
      fullName = dto.fullName.trim();
    try {
      await this.prisma.$transaction(async (tx) => {
        await tx.$queryRaw`SELECT "id" FROM "User" WHERE "id" = ${actor} FOR UPDATE`;
        const user = await tx.user.findUnique({ where: { id: actor } });
        if (!user?.firebaseUid || !user.email)
          throw new ForbiddenException(
            'Connect your verified Google or email account first.',
          );
        if (user.phone && user.fullName) {
          if (user.phone === phone && user.fullName === fullName) return;
          throw new ConflictException('First-use profile is already complete.');
        }
        await tx.user.update({
          where: { id: actor },
          data: { phone, fullName },
        });
      });
    } catch (error) {
      if (
        error &&
        typeof error === 'object' &&
        'code' in error &&
        error.code === 'P2002'
      )
        throw new ConflictException(
          'This phone cannot be used for this account.',
        );
      throw error;
    }
    return this.sessions.findUserById(actor);
  }
}

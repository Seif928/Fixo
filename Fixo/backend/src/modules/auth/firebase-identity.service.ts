import { ConflictException, Injectable, ServiceUnavailableException, UnauthorizedException } from '@nestjs/common';
import { getApps, initializeApp } from 'firebase-admin/app';
import { PrismaService } from '../../prisma/prisma.service';
import { AuthService } from './auth.service';

@Injectable()
export class FirebaseTokenVerifier {
  async verify(idToken: string) {
    const projectId = process.env.FIREBASE_PROJECT_ID;
    if (!projectId) throw new ServiceUnavailableException('Email sign-in is not configured.');
    const name = `fixo-identity-${projectId}`;
    const app = getApps().find(value => value.name === name) ?? initializeApp({ projectId }, name);
    try {
      const { getAuth } = await import('firebase-admin/auth');
      // Admin SDK verifies signature, expiry, issuer and audience against this project.
      // No service-account private key is required for public-certificate verification.
      return await getAuth(app).verifyIdToken(idToken);
    } catch {
      throw new UnauthorizedException('Invalid or expired identity token.');
    }
  }
}

@Injectable()
export class FirebaseIdentityService {
  constructor(private readonly prisma: PrismaService, private readonly verifier: FirebaseTokenVerifier, private readonly sessions: AuthService) {}

  async exchange(idToken: string) {
    if (!this.prisma.isDatabaseConnected()) throw new ServiceUnavailableException('Email sign-in requires database persistence.');
    const identity = await this.verifier.verify(idToken);
    if (!identity.uid || !identity.email || identity.email_verified !== true) throw new UnauthorizedException('Verify your email address before signing in.');
    const linked = await this.prisma.user.findUnique({ where: { firebaseUid: identity.uid } });
    if (linked) return this.sessions.issueVerifiedUserSession(linked.id);
    const email = identity.email.toLowerCase();
    const existing = await this.prisma.user.findUnique({ where: { email } });
    if (existing) throw new ConflictException('An account already uses this email. Sign in with the existing method to link identities.');
    try {
      const user = await this.prisma.user.upsert({ where: { firebaseUid: identity.uid }, update: {}, create: { firebaseUid: identity.uid, email, role: 'CUSTOMER' } });
      return this.sessions.issueVerifiedUserSession(user.id);
    } catch (error) {
      if (error && typeof error === 'object' && 'code' in error && error.code === 'P2002') {
        const user = await this.prisma.user.findUnique({ where: { firebaseUid: identity.uid } });
        if (user) return this.sessions.issueVerifiedUserSession(user.id);
        throw new ConflictException('Account linking requires signing in with the existing method.');
      }
      throw error;
    }
  }
}

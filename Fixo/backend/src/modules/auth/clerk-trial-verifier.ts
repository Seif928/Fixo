import { ServiceUnavailableException, UnauthorizedException } from '@nestjs/common';
import { verifyToken } from '@clerk/backend';

export interface ClerkTrialConfiguration {
  enabled: boolean;
  issuer: string;
  jwtKey: string;
  authorizedParties: string[];
}

/** Trial-only verification boundary. Not registered in AuthModule or JwtAuthGuard.
 * It issues no FIXO session, does not link emails and does not grant app roles.
 * Provider account/session revocation and stable identity mapping remain cutover gates.
 */
export class ClerkTrialVerifier {
  constructor(private readonly configuration: ClerkTrialConfiguration) {}

  async verify(token: string): Promise<{ provider: 'clerk'; subject: string; sessionId: string; issuedAt: number }> {
    const config = this.configuration;
    let validIssuer = false;
    try {
      const issuer = new URL(config.issuer);
      validIssuer = issuer.protocol === 'https:' && issuer.origin === config.issuer;
    } catch { /* Configuration must be supplied by server composition, never a request. */ }
    if (!config.enabled || !validIssuer || !config.jwtKey.trim() || !config.authorizedParties.length) {
      throw new ServiceUnavailableException('Clerk trial verification is not configured.');
    }
    try {
      if (typeof token !== 'string' || token.length < 20 || token.length > 10000) throw new Error('Invalid token');
      // Public-key verification is networkless; a missing key never falls back to a secret/API lookup.
      const identity = await verifyToken(token, {
        jwtKey: config.jwtKey,
        issuer: config.issuer,
        authorizedParties: config.authorizedParties,
        clockSkewInMs: 0,
      });
      if (
        typeof identity.sub !== 'string' || !identity.sub.startsWith('user_') ||
        typeof identity.sid !== 'string' || !identity.sid.startsWith('sess_') ||
        !Number.isSafeInteger(identity.iat) || !Number.isSafeInteger(identity.exp) ||
        identity.exp <= Math.floor(Date.now() / 1000) ||
        (identity.sts !== undefined && identity.sts !== 'active')
      ) throw new Error('Invalid session');
      return { provider: 'clerk', subject: identity.sub, sessionId: identity.sid, issuedAt: identity.iat };
    } catch {
      // Never log a bearer token, provider response or identity data.
      throw new UnauthorizedException('Clerk trial token is invalid or expired.');
    }
  }
}

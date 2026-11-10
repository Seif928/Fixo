import { generateKeyPairSync, sign } from 'crypto';
import { ServiceUnavailableException, UnauthorizedException } from '@nestjs/common';
import { ClerkTrialVerifier } from './clerk-trial-verifier';

describe('Isolated Clerk token verifier (no FIXO session exchange)', () => {
  const pair = generateKeyPairSync('rsa', { modulusLength: 2048 });
  const issuer = 'https://fixture.clerk.accounts.dev';
  const party = 'https://fixo.example.test';
  const config = { enabled: true, issuer, authorizedParties: [party], jwtKey: pair.publicKey.export({ type: 'spki', format: 'pem' }).toString() };
  const token = (changes: Record<string, unknown> = {}, privateKey = pair.privateKey) => {
    const now = Math.floor(Date.now() / 1000);
    const header = Buffer.from(JSON.stringify({ alg: 'RS256', typ: 'JWT', kid: 'fixture' })).toString('base64url');
    const payload = Buffer.from(JSON.stringify({ iss: issuer, sub: 'user_fixture', sid: 'sess_fixture', azp: party, iat: now, nbf: now - 1, exp: now + 60, v: 2, ...changes })).toString('base64url');
    const input = `${header}.${payload}`;
    return `${input}.${sign('RSA-SHA256', Buffer.from(input), privateKey).toString('base64url')}`;
  };
  it('verifies a real signature but returns no FIXO tokens, role or email linkage', async () => {
    const result = await new ClerkTrialVerifier(config).verify(token({ role: 'ADMIN', email: 'untrusted@example.test' }));
    expect(result).toMatchObject({ provider: 'clerk', subject: 'user_fixture', sessionId: 'sess_fixture' });
    expect(Object.keys(result).sort()).toEqual(['issuedAt', 'provider', 'sessionId', 'subject']);
  });
  it.each([
    { iss: 'https://other.clerk.accounts.dev' },
    { azp: 'https://attacker.example.test' },
    { exp: Math.floor(Date.now() / 1000) - 60 },
    { nbf: Math.floor(Date.now() / 1000) + 3600 },
    { sts: 'pending' }, { sid: 'machine_fixture' }, { sub: 'machine_fixture' },
  ])('rejects invalid session claims %j', async changes => {
    await expect(new ClerkTrialVerifier(config).verify(token(changes))).rejects.toThrow(UnauthorizedException);
  });
  it('rejects a forged signature', async () => {
    const other = generateKeyPairSync('rsa', { modulusLength: 2048 });
    await expect(new ClerkTrialVerifier(config).verify(token({}, other.privateKey))).rejects.toThrow(UnauthorizedException);
  });
  it.each([{ enabled: false }, { jwtKey: '' }, { authorizedParties: [] }])('fails closed for unavailable trial configuration %j', async change => {
    await expect(new ClerkTrialVerifier({ ...config, ...change }).verify(token())).rejects.toThrow(ServiceUnavailableException);
  });
});

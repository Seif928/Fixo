import { UnauthorizedException } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { createHash, createHmac, randomUUID, timingSafeEqual } from 'crypto';

export interface FixoJwtPayload {
  sub: string;
  phone: string;
  role: UserRole;
  type: 'access' | 'refresh';
  jti: string;
  iat: number;
  exp: number;
}

function base64UrlEncode(input: Buffer | string): string {
  const buf = typeof input === 'string' ? Buffer.from(input, 'utf8') : input;
  return buf
    .toString('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
}

function base64UrlDecode(input: string): Buffer {
  const normalized = input.replace(/-/g, '+').replace(/_/g, '/');
  const padLength = (4 - (normalized.length % 4)) % 4;
  return Buffer.from(normalized + '='.repeat(padLength), 'base64');
}

export function signFixoJwt(
  payload: Omit<FixoJwtPayload, 'iat' | 'exp' | 'jti'>,
  secret: string,
  expiresInSeconds: number,
): { token: string; payload: FixoJwtPayload } {
  const nowSec = Math.floor(Date.now() / 1000);
  const fullPayload: FixoJwtPayload = {
    ...payload,
    jti: randomUUID(),
    iat: nowSec,
    exp: nowSec + expiresInSeconds,
  };

  const headerSegment = base64UrlEncode(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
  const payloadSegment = base64UrlEncode(JSON.stringify(fullPayload));
  const signingInput = `${headerSegment}.${payloadSegment}`;
  const signature = createHmac('sha256', secret).update(signingInput).digest();
  const signatureSegment = base64UrlEncode(signature);

  return {
    token: `${signingInput}.${signatureSegment}`,
    payload: fullPayload,
  };
}

export function verifyFixoJwt(token: string, secret: string): FixoJwtPayload {
  if (!token || typeof token !== 'string') {
    throw new UnauthorizedException('Missing or malformed authentication token.');
  }

  const segments = token.split('.');
  if (segments.length !== 3) {
    throw new UnauthorizedException('Malformed JWT structure.');
  }

  const [headerSegment, payloadSegment, signatureSegment] = segments;
  const signingInput = `${headerSegment}.${payloadSegment}`;
  const expectedSig = createHmac('sha256', secret).update(signingInput).digest();
  const actualSig = base64UrlDecode(signatureSegment);

  if (
    expectedSig.length !== actualSig.length ||
    !timingSafeEqual(expectedSig, actualSig)
  ) {
    throw new UnauthorizedException('Invalid token signature.');
  }

  let parsed: FixoJwtPayload;
  try {
    parsed = JSON.parse(base64UrlDecode(payloadSegment).toString('utf8')) as FixoJwtPayload;
  } catch {
    throw new UnauthorizedException('Invalid JWT payload encoding.');
  }

  const nowSec = Math.floor(Date.now() / 1000);
  if (typeof parsed.exp !== 'number' || parsed.exp <= nowSec) {
    throw new UnauthorizedException('Authentication token has expired.');
  }

  return parsed;
}

export function hashTokenSha256(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}

export function hashOtpHmacSha256(phone: string, code: string, secret: string): string {
  return createHmac('sha256', secret).update(`${phone}:${code}`).digest('hex');
}

export function verifyOtpHmacTimingSafe(
  phone: string,
  submittedCode: string,
  expectedHashHex: string,
  secret: string,
): boolean {
  const actualHashHex = hashOtpHmacSha256(phone, submittedCode, secret);
  const actualBuf = Buffer.from(actualHashHex, 'hex');
  const expectedBuf = Buffer.from(expectedHashHex, 'hex');
  if (actualBuf.length !== expectedBuf.length) {
    return false;
  }
  return timingSafeEqual(actualBuf, expectedBuf);
}


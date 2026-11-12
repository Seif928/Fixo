import {
  BadRequestException,
  ForbiddenException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { createHash, createHmac, randomBytes, timingSafeEqual } from 'crypto';

export const MAX_PRIVATE_UPLOAD_BYTES = 2 * 1024 * 1024; // 2 MB

export type AllowedUploadMimeType =
  | 'image/jpeg'
  | 'image/png'
  | 'image/webp'
  | 'application/pdf';

export interface ValidatedPrivateUpload {
  fileName: string;
  mimeType: AllowedUploadMimeType;
  fileSizeBytes: number;
  sha256: string;
  normalizedBase64: string;
}

export interface SignedUploadAccessClaims {
  ownerUserId: string;
  purpose: 'BOOKING_ISSUE' | 'REVIEW_PHOTO' | 'PRO_DOCUMENT';
  sha256: string;
  mimeType: AllowedUploadMimeType;
  fileName: string;
  exp: number;
}

let ephemeralDevUploadKey: string | undefined;

function getUploadSigningSecret(): string {
  const configured =
    process.env.PRIVATE_UPLOAD_SECRET?.trim() ||
    process.env.JWT_ACCESS_SECRET?.trim();
  if (configured) {
    return createHmac('sha256', configured)
      .update('fixo:private-upload-signing:v1')
      .digest('hex');
  }
  if (process.env.NODE_ENV === 'production') {
    throw new ServiceUnavailableException(
      'Private upload signing key is not configured.',
    );
  }
  ephemeralDevUploadKey ??= randomBytes(32).toString('hex');
  return ephemeralDevUploadKey;
}

/**
 * Validates file name, MIME type, decoded byte size (<= 2 MB), and binary
 * magic-byte headers (JPEG, PNG, WebP, or PDF) to prevent disguised payloads.
 */
export function validatePrivateUploadPayload(params: {
  purpose: 'BOOKING_ISSUE' | 'REVIEW_PHOTO' | 'PRO_DOCUMENT';
  fileName: string;
  mimeType: string;
  contentBase64: string;
}): ValidatedPrivateUpload {
  const { purpose, fileName, mimeType, contentBase64 } = params;

  const allowedImageMimes: AllowedUploadMimeType[] = [
    'image/jpeg',
    'image/png',
    'image/webp',
  ];
  const allowedMimes: AllowedUploadMimeType[] =
    purpose === 'PRO_DOCUMENT'
      ? [...allowedImageMimes, 'application/pdf']
      : allowedImageMimes;

  if (!allowedMimes.includes(mimeType as AllowedUploadMimeType)) {
    throw new BadRequestException(
      `Unsupported file MIME type "${mimeType}" for ${purpose}. Allowed: ${allowedMimes.join(', ')}.`,
    );
  }

  const sanitizedFileName = fileName
    .trim()
    .replace(/[^a-zA-Z0-9._-\u0600-\u06FF ]/g, '_')
    .slice(0, 120);

  if (!sanitizedFileName) {
    throw new BadRequestException('A valid file name is required.');
  }

  // Strip optional data URI prefix
  const rawBase64 = contentBase64
    .trim()
    .replace(/^data:[^;]+;base64,/, '')
    .replace(/\s+/g, '');

  if (!rawBase64 || !/^[A-Za-z0-9+/=]+$/.test(rawBase64)) {
    throw new BadRequestException('Invalid base64 file content.');
  }

  const buffer = Buffer.from(rawBase64, 'base64');
  if (buffer.length === 0) {
    throw new BadRequestException('Uploaded file content cannot be empty.');
  }

  if (buffer.length > MAX_PRIVATE_UPLOAD_BYTES) {
    throw new BadRequestException(
      `Uploaded file exceeds the 2 MB maximum limit (${buffer.length} bytes).`,
    );
  }

  // Verify binary magic bytes match declared MIME type
  if (!matchesMagicBytes(buffer, mimeType as AllowedUploadMimeType)) {
    throw new BadRequestException(
      `File binary header does not match declared MIME type "${mimeType}".`,
    );
  }

  const sha256 = createHash('sha256').update(buffer).digest('hex');

  return {
    fileName: sanitizedFileName,
    mimeType: mimeType as AllowedUploadMimeType,
    fileSizeBytes: buffer.length,
    sha256,
    normalizedBase64: buffer.toString('base64'),
  };
}

function matchesMagicBytes(
  buffer: Buffer,
  mimeType: AllowedUploadMimeType,
): boolean {
  if (buffer.length < 4) {
    return false;
  }

  switch (mimeType) {
    case 'image/jpeg':
      // FF D8 FF
      return buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff;
    case 'image/png':
      // 89 50 4E 47
      return (
        buffer[0] === 0x89 &&
        buffer[1] === 0x50 &&
        buffer[2] === 0x4e &&
        buffer[3] === 0x47
      );
    case 'image/webp':
      // RIFF....WEBP
      return (
        buffer.length >= 12 &&
        buffer.subarray(0, 4).toString('ascii') === 'RIFF' &&
        buffer.subarray(8, 12).toString('ascii') === 'WEBP'
      );
    case 'application/pdf':
      // %PDF
      return buffer.subarray(0, 4).toString('ascii') === '%PDF';
    default:
      return false;
  }
}

/**
 * Creates a short-lived HMAC-signed token (default 15 minutes) for accessing
 * a private upload.
 */
export function signPrivateUploadAccessToken(
  claims: Omit<SignedUploadAccessClaims, 'exp'>,
  ttlSeconds = 900,
): { token: string; expiresAt: string } {
  const exp = Math.floor(Date.now() / 1000) + ttlSeconds;
  const payload: SignedUploadAccessClaims = { ...claims, exp };
  const encodedPayload = Buffer.from(JSON.stringify(payload), 'utf8').toString(
    'base64url',
  );
  const signature = createHmac('sha256', getUploadSigningSecret())
    .update(encodedPayload)
    .digest('base64url');

  return {
    token: `${encodedPayload}.${signature}`,
    expiresAt: new Date(exp * 1000).toISOString(),
  };
}

export function verifyPrivateUploadAccessToken(
  token: string,
): SignedUploadAccessClaims {
  const parts = token.split('.');
  if (parts.length !== 2) {
    throw new ForbiddenException('Malformed private upload access token.');
  }

  const [encodedPayload, signature] = parts;
  const expectedSig = createHmac('sha256', getUploadSigningSecret())
    .update(encodedPayload)
    .digest('base64url');

  const sigBuf = Buffer.from(signature);
  const expectedBuf = Buffer.from(expectedSig);
  if (
    sigBuf.length !== expectedBuf.length ||
    !timingSafeEqual(sigBuf, expectedBuf)
  ) {
    throw new ForbiddenException('Invalid private upload signature.');
  }

  let claims: SignedUploadAccessClaims;
  try {
    claims = JSON.parse(
      Buffer.from(encodedPayload, 'base64url').toString('utf8'),
    ) as SignedUploadAccessClaims;
  } catch {
    throw new ForbiddenException('Invalid private upload token payload.');
  }

  const nowSec = Math.floor(Date.now() / 1000);
  if (!claims.exp || claims.exp < nowSec) {
    throw new ForbiddenException('Private upload access token has expired.');
  }

  return claims;
}

import { BadRequestException } from '@nestjs/common';

export const EGYPT_E164_MOBILE_REGEX = /^\+201[0125]\d{8}$/;

/**
 * Normalizes an Egyptian mobile input string (`010 2345 6789`, `+20 102 345 6789`,
 * `+201023456789`, `201023456789`) into canonical E.164 format (`+201XXXXXXXXX`).
 */
export function normalizeEgyptPhone(rawInput: string): string {
  if (typeof rawInput !== 'string') {
    throw new BadRequestException(
      'Invalid Egyptian mobile number. Expected +20 10/11/12/15 followed by 8 digits.',
    );
  }

  const compact = rawInput.replace(/[\s\-().]/g, '');

  let candidate = compact;
  if (candidate.startsWith('0020')) {
    candidate = `+20${candidate.slice(4)}`;
  } else if (candidate.startsWith('+2001')) {
    candidate = `+201${candidate.slice(5)}`;
  } else if (candidate.startsWith('201') && candidate.length === 12) {
    candidate = `+${candidate}`;
  } else if (candidate.startsWith('01') && candidate.length === 11) {
    candidate = `+20${candidate.slice(1)}`;
  } else if (candidate.startsWith('1') && candidate.length === 10) {
    candidate = `+20${candidate}`;
  }

  if (!EGYPT_E164_MOBILE_REGEX.test(candidate)) {
    throw new BadRequestException(
      'Invalid Egyptian mobile number. Must start with +20 (or 010, 011, 012, 015) and contain 10 subscriber digits.',
    );
  }

  return candidate;
}


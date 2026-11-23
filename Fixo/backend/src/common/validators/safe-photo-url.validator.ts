import {
  registerDecorator,
  ValidationArguments,
  ValidationOptions,
} from 'class-validator';

const SAFE_RELATIVE_PHOTO_PATH = /^\/api\/v1\/[a-zA-Z0-9/_-]+$/;
const SAFE_DATA_IMAGE_URI =
  /^data:image\/(jpeg|png|webp);base64,[A-Za-z0-9+/=]+$/;
const BLOCKED_HOSTS = new Set([
  'localhost',
  '127.0.0.1',
  '0.0.0.0',
  '::1',
  '[::1]',
  '169.254.169.254',
]);

export function isSafePhotoReference(
  value: unknown,
  maxHttpLength = 2048,
  maxDataUriLength = 2_800_000,
): boolean {
  if (typeof value !== 'string') {
    return false;
  }
  const trimmed = value.trim();
  if (!trimmed || /[\x00-\x1f\x7f\s]/.test(trimmed)) {
    return false;
  }
  if (trimmed.startsWith('/api/v1/')) {
    return (
      trimmed.length <= maxHttpLength &&
      !trimmed.includes('..') &&
      SAFE_RELATIVE_PHOTO_PATH.test(trimmed)
    );
  }
  if (trimmed.startsWith('data:')) {
    return (
      trimmed.length <= maxDataUriLength && SAFE_DATA_IMAGE_URI.test(trimmed)
    );
  }
  if (trimmed.length > maxHttpLength) {
    return false;
  }
  try {
    const parsed = new URL(trimmed);
    if (parsed.protocol !== 'https:') {
      return false;
    }
    const host = parsed.hostname.toLowerCase();
    if (!host || BLOCKED_HOSTS.has(host) || host.endsWith('.local')) {
      return false;
    }
    return true;
  } catch {
    return false;
  }
}

export function IsSafePhotoUrl(
  options?: {
    maxHttpLength?: number;
    maxDataUriLength?: number;
    each?: boolean;
  } & ValidationOptions,
) {
  const {
    maxHttpLength = 2048,
    maxDataUriLength = 2_800_000,
    ...validationOptions
  } = options ?? {};

  return function (object: object, propertyName: string) {
    registerDecorator({
      name: 'isSafePhotoUrl',
      target: object.constructor,
      propertyName,
      options: validationOptions,
      validator: {
        validate(value: unknown) {
          return isSafePhotoReference(value, maxHttpLength, maxDataUriLength);
        },
        defaultMessage(args: ValidationArguments) {
          return `${args.property} must be an HTTPS URL, private API image path, or safe base64 JPEG/PNG/WebP image.`;
        },
      },
    });
  };
}


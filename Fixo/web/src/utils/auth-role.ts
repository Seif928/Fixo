export interface AuthUserLike {
  email?: string | null;
  email_confirmed_at?: string | null;
  confirmed_at?: string | null;
  app_metadata?: Record<string, unknown> | null;
  user_metadata?: Record<string, unknown> | null;
}

const DEFAULT_OWNER_EMAIL = 'gamal6507@gmail.com';

/**
 * Rejects protocol-relative (`//evil.com`), backslash, or external redirect URLs
 * so login & OAuth callbacks stay strictly on the local origin.
 */
export function sanitizeRedirectPath(
  raw: string | null | undefined,
  fallback = '/dashboard',
): string {
  if (!raw) return fallback;
  const trimmed = raw.trim();
  if (
    !trimmed.startsWith('/') ||
    trimmed.startsWith('//') ||
    trimmed.includes('\\') ||
    /[\r\n\0]/.test(trimmed)
  ) {
    return fallback;
  }
  try {
    const parsed = new URL(trimmed, 'http://localhost');
    if (parsed.origin !== 'http://localhost') {
      return fallback;
    }
    return `${parsed.pathname}${parsed.search}`;
  } catch {
    return fallback;
  }
}

/**
 * Checks admin privileges using server-controlled claims only (`app_metadata`
 * or confirmed owner email). Never trusts user-mutable `user_metadata.role`.
 */
export function isVerifiedAdmin(user: AuthUserLike | null | undefined): boolean {
  if (!user) return false;

  if (user.app_metadata?.role === 'ADMIN') {
    return true;
  }

  const ownerEmail = (process.env.FIXO_OWNER_EMAIL || DEFAULT_OWNER_EMAIL)
    .trim()
    .toLowerCase();
  const userEmail = (user.email ?? '').trim().toLowerCase();
  const isEmailConfirmed = Boolean(user.email_confirmed_at || user.confirmed_at);

  return Boolean(ownerEmail && userEmail === ownerEmail && isEmailConfirmed);
}

export function getUserDisplayRole(
  user: AuthUserLike | null | undefined,
): 'ADMIN' | 'PRO' | 'CUSTOMER' {
  if (isVerifiedAdmin(user)) {
    return 'ADMIN';
  }
  return user?.user_metadata?.role === 'PRO' ? 'PRO' : 'CUSTOMER';
}

/**
 * Normalizes and validates Egyptian mobile numbers (+201[0125]XXXXXXXX).
 */
export function normalizeEgyptianPhone(raw: string): string | null {
  const cleaned = raw.trim().replace(/[\s()-]/g, '');
  if (!cleaned) return null;

  let normalized = cleaned;
  if (normalized.startsWith('0020')) {
    normalized = `+20${normalized.slice(4)}`;
  } else if (normalized.startsWith('20') && !normalized.startsWith('+')) {
    normalized = `+${normalized}`;
  } else if (normalized.startsWith('01')) {
    normalized = `+20${normalized.slice(1)}`;
  } else if (/^1[0125]\d{8}$/.test(normalized)) {
    normalized = `+20${normalized}`;
  }

  return /^\+201[0125]\d{8}$/.test(normalized) ? normalized : null;
}

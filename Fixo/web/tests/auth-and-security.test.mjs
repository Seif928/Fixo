import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import {
  getUserDisplayRole,
  isVerifiedAdmin,
  normalizeEgyptianPhone,
  sanitizeRedirectPath,
} from '../src/utils/auth-role.ts';

test('sanitizeRedirectPath allows valid relative paths and blocks open redirects', () => {
  assert.equal(sanitizeRedirectPath('/dashboard'), '/dashboard');
  assert.equal(sanitizeRedirectPath('/admin?tab=users'), '/admin?tab=users');
  assert.equal(sanitizeRedirectPath('//evil.com'), '/dashboard');
  assert.equal(sanitizeRedirectPath('https://evil.com/phish'), '/dashboard');
  assert.equal(sanitizeRedirectPath('/\\evil.com'), '/dashboard');
  assert.equal(sanitizeRedirectPath('javascript:alert(1)'), '/dashboard');
  assert.equal(sanitizeRedirectPath('/profile\r\nSet-Cookie: a=b'), '/dashboard');
});

test('isVerifiedAdmin rejects user_metadata privilege escalation and unconfirmed emails', () => {
  assert.equal(isVerifiedAdmin(null), false);

  // User tries to escalate themselves via client-editable user_metadata.role
  assert.equal(
    isVerifiedAdmin({
      email: 'attacker@example.com',
      email_confirmed_at: '2026-11-14T00:00:00Z',
      user_metadata: { role: 'ADMIN' },
      app_metadata: {},
    }),
    false,
  );

  // Attacker signs up with owner email without confirming ownership
  assert.equal(
    isVerifiedAdmin({
      email: 'gamal6507@gmail.com',
      email_confirmed_at: null,
      confirmed_at: null,
      user_metadata: { role: 'ADMIN' },
      app_metadata: {},
    }),
    false,
  );

  // Confirmed owner email or server-signed app_metadata admin succeeds
  assert.equal(
    isVerifiedAdmin({
      email: 'gamal6507@gmail.com',
      email_confirmed_at: '2026-11-14T00:00:00Z',
      app_metadata: {},
    }),
    true,
  );
  assert.equal(
    isVerifiedAdmin({
      email: 'ops-admin@fixo.app',
      email_confirmed_at: '2026-11-14T00:00:00Z',
      app_metadata: { role: 'ADMIN' },
    }),
    true,
  );
});

test('getUserDisplayRole never returns ADMIN from user_metadata', () => {
  assert.equal(
    getUserDisplayRole({
      email: 'user@example.com',
      user_metadata: { role: 'ADMIN' },
    }),
    'CUSTOMER',
  );
  assert.equal(
    getUserDisplayRole({
      email: 'pro@example.com',
      user_metadata: { role: 'PRO' },
    }),
    'PRO',
  );
});

test('normalizeEgyptianPhone strictly validates +20 mobile numbers', () => {
  assert.equal(normalizeEgyptianPhone('01012345678'), '+201012345678');
  assert.equal(normalizeEgyptianPhone('+20 11 2345 6789'), '+201123456789');
  assert.equal(normalizeEgyptianPhone('00201234567890'), '+201234567890');
  assert.equal(normalizeEgyptianPhone('01555555555'), '+201555555555');
  assert.equal(normalizeEgyptianPhone('12345'), null);
  assert.equal(normalizeEgyptianPhone('01312345678'), null);
});

test('security regression: web source never trusts user_metadata.role for ADMIN and has no leaked secrets', () => {
  const srcRoot = path.resolve(import.meta.dirname, '../src');
  const files = [];
  function walk(dir) {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) walk(full);
      else if (/\.(ts|tsx)$/.test(entry.name)) files.push(full);
    }
  }
  walk(srcRoot);

  for (const file of files) {
    const content = fs.readFileSync(file, 'utf8');
    assert.equal(
      /user_metadata\??\.role\s*===\s*['"]ADMIN['"]/.test(content),
      false,
      `Unsafe user_metadata.role === 'ADMIN' check in ${file}`,
    );
    assert.equal(
      /NEXT_PUBLIC_.*SERVICE_ROLE|NEXT_PUBLIC_.*SECRET/.test(content),
      false,
      `Secret env var exposed via NEXT_PUBLIC_ in ${file}`,
    );
  }
});

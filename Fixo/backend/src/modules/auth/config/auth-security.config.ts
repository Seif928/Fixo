import { createHmac } from 'crypto';
import {
  isSupportedSmsProvider,
  SupportedSmsProvider,
  SUPPORTED_SMS_PROVIDERS,
} from '../sms/sms.provider';

export interface ValidatedAuthSecurityConfig {
  accessSecret: string;
  refreshSecret: string;
  otpHmacSecret: string;
  smsProviderType: SupportedSmsProvider;
  isProduction: boolean;
  allowDevSms: boolean;
  allowInMemoryFallback: boolean;
  allowTestFixedOtp: boolean;
}

const FORBIDDEN_SECRET_SUBSTRINGS = [
  'fixo-local-dev',
  'replace-with-local',
  'change-me',
  'your-secret',
  'default-secret',
  'secret-key',
  'admin123',
  '12345678',
  'password',
];

function isKnownInsecureSecret(secret: string): boolean {
  const lower = secret.trim().toLowerCase();
  return FORBIDDEN_SECRET_SUBSTRINGS.some((forbidden) =>
    lower.includes(forbidden.toLowerCase()),
  );
}

export function validateAuthSecurityConfig(
  env: NodeJS.ProcessEnv = process.env,
): ValidatedAuthSecurityConfig {
  const isProduction = env.NODE_ENV === 'production';
  const isTest = env.NODE_ENV === 'test';

  const accessSecret = env.JWT_ACCESS_SECRET?.trim();
  const refreshSecret = env.JWT_REFRESH_SECRET?.trim();
  const otpHmacSecretEnv = env.OTP_HMAC_SECRET?.trim();

  // 1. Access Secret Validation
  if (!accessSecret) {
    throw new Error(
      'FATAL AUTH CONFIGURATION ERROR: JWT_ACCESS_SECRET is required and cannot be empty.',
    );
  }
  if (accessSecret.length < 32) {
    throw new Error(
      `FATAL AUTH CONFIGURATION ERROR: JWT_ACCESS_SECRET must be at least 32 characters long (received ${accessSecret.length}).`,
    );
  }
  if (isKnownInsecureSecret(accessSecret)) {
    throw new Error(
      'FATAL AUTH CONFIGURATION ERROR: JWT_ACCESS_SECRET contains a known insecure or example value. Production and local deployments must configure an independent random secret.',
    );
  }

  // 2. Refresh Secret Validation
  if (!refreshSecret) {
    throw new Error(
      'FATAL AUTH CONFIGURATION ERROR: JWT_REFRESH_SECRET is required and cannot be empty.',
    );
  }
  if (refreshSecret.length < 32) {
    throw new Error(
      `FATAL AUTH CONFIGURATION ERROR: JWT_REFRESH_SECRET must be at least 32 characters long (received ${refreshSecret.length}).`,
    );
  }
  if (isKnownInsecureSecret(refreshSecret)) {
    throw new Error(
      'FATAL AUTH CONFIGURATION ERROR: JWT_REFRESH_SECRET contains a known insecure or example value. Production and local deployments must configure an independent random secret.',
    );
  }
  if (refreshSecret === accessSecret) {
    throw new Error(
      'FATAL AUTH CONFIGURATION ERROR: JWT_ACCESS_SECRET and JWT_REFRESH_SECRET must be distinct and independent keys.',
    );
  }

  // 3. OTP HMAC Secret Validation
  let otpHmacSecret: string;
  if (otpHmacSecretEnv) {
    if (otpHmacSecretEnv.length < 32) {
      throw new Error(
        `FATAL AUTH CONFIGURATION ERROR: OTP_HMAC_SECRET must be at least 32 characters long (received ${otpHmacSecretEnv.length}).`,
      );
    }
    if (isKnownInsecureSecret(otpHmacSecretEnv)) {
      throw new Error(
        'FATAL AUTH CONFIGURATION ERROR: OTP_HMAC_SECRET contains a known insecure or example value.',
      );
    }
    if (
      otpHmacSecretEnv === accessSecret ||
      otpHmacSecretEnv === refreshSecret
    ) {
      throw new Error(
        'FATAL AUTH CONFIGURATION ERROR: OTP_HMAC_SECRET must be distinct from both JWT_ACCESS_SECRET and JWT_REFRESH_SECRET.',
      );
    }
    otpHmacSecret = otpHmacSecretEnv;
  } else if (isProduction) {
    throw new Error(
      'FATAL AUTH CONFIGURATION ERROR: Production environment requires an explicit, independent OTP_HMAC_SECRET of at least 32 characters.',
    );
  } else {
    // Cryptographically derive in local dev / test if not explicitly set
    otpHmacSecret = createHmac('sha256', accessSecret)
      .update('fixo:auth:otp-hmac:salt:2026:independent')
      .digest('hex');
  }

  // 4. Telecom SMS Provider & Sandbox Isolation
  const rawSmsProvider = env.SMS_PROVIDER_TYPE?.trim();
  if (rawSmsProvider && !isSupportedSmsProvider(rawSmsProvider)) {
    throw new Error(
      `FATAL AUTH CONFIGURATION ERROR: Unknown SMS_PROVIDER_TYPE '${rawSmsProvider}'. Supported options: ${SUPPORTED_SMS_PROVIDERS.join(', ')}.`,
    );
  }

  const smsProviderType = (rawSmsProvider ??
    (isProduction ? '' : 'DEV_SANDBOX_SMS')) as SupportedSmsProvider;

  const allowDevSms = env.ALLOW_DEV_SMS === 'true';

  if (isProduction) {
    if (smsProviderType === 'DISABLED' && !env.FIREBASE_PROJECT_ID?.trim()) {
      throw new Error('FATAL AUTH CONFIGURATION ERROR: Disabling SMS requires a configured FIREBASE_PROJECT_ID for verified email sign-in.');
    }
    if (!smsProviderType || smsProviderType === 'DEV_SANDBOX_SMS') {
      throw new Error(
        "FATAL AUTH CONFIGURATION ERROR: Production environment requires a configured telecom SMS provider ('TWILIO', 'VICTORYLINK', or 'VODAFONE_EG'). 'DEV_SANDBOX_SMS' is strictly forbidden in production.",
      );
    }
    if (allowDevSms) {
      throw new Error(
        'FATAL AUTH CONFIGURATION ERROR: ALLOW_DEV_SMS cannot be enabled in production.',
      );
    }
  } else if (smsProviderType === 'DEV_SANDBOX_SMS' && !allowDevSms && !isTest) {
    throw new Error(
      "AUTH CONFIGURATION ERROR: DEV_SANDBOX_SMS requested but ALLOW_DEV_SMS is not set to 'true'. Explicit configuration required for local mock SMS dispatch.",
    );
  }

  // 5. Database & Fallback Invariants
  const allowInMemoryFallback = env.ALLOW_IN_MEMORY_FALLBACK === 'true';
  if (isProduction && allowInMemoryFallback) {
    throw new Error(
      'FATAL CONFIGURATION ERROR: ALLOW_IN_MEMORY_FALLBACK is strictly forbidden in production mode.',
    );
  }

  // 6. Test Fixed-OTP Invariant
  const allowTestFixedOtp = env.ALLOW_TEST_FIXED_OTP === 'true';
  if (isProduction && allowTestFixedOtp) {
    throw new Error(
      'FATAL CONFIGURATION ERROR: ALLOW_TEST_FIXED_OTP is strictly forbidden in production mode.',
    );
  }

  return {
    accessSecret,
    refreshSecret,
    otpHmacSecret,
    smsProviderType: smsProviderType || 'DEV_SANDBOX_SMS',
    isProduction,
    allowDevSms,
    allowInMemoryFallback,
    allowTestFixedOtp,
  };
}


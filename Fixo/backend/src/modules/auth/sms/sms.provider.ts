import {
  HttpException,
  HttpStatus,
  Injectable,
  Logger,
} from '@nestjs/common';

export const SMS_PROVIDER = Symbol('SMS_PROVIDER');

export const SUPPORTED_SMS_PROVIDERS = [
  'DEV_SANDBOX_SMS',
  'TWILIO',
  'VICTORYLINK',
  'VODAFONE_EG',
] as const;

export type SupportedSmsProvider = (typeof SUPPORTED_SMS_PROVIDERS)[number];

export function isSupportedSmsProvider(val: unknown): val is SupportedSmsProvider {
  return (
    typeof val === 'string' &&
    (SUPPORTED_SMS_PROVIDERS as readonly string[]).includes(val)
  );
}

export interface SmsDispatchResult {
  provider: SupportedSmsProvider;
  delivered: boolean;
  simulated: boolean;
  dispatchedAt: string;
}

export interface SmsProvider {
  sendOtpCode(
    phone: string,
    code: string,
    expiresInSeconds: number,
  ): Promise<SmsDispatchResult>;
  getLastDispatchedCodeForPhone?(phone: string): string | null;
}

export function maskEgyptPhone(phone: string): string {
  if (phone.length <= 6) {
    return '***';
  }
  return `${phone.slice(0, 5)}*****${phone.slice(-3)}`;
}

/**
 * Isolated development/test SMS provider.
 * Allowed ONLY in non-production environments when ALLOW_DEV_SMS="true" or NODE_ENV="test".
 * Never logs authentication codes.
 * Explicitly identifies dispatch as simulated (`delivered: false, simulated: true`).
 */
@Injectable()
export class DevSmsProvider implements SmsProvider {
  private readonly logger = new Logger(DevSmsProvider.name);
  private readonly sentCodesByPhone = new Map<string, string>();

  async sendOtpCode(
    phone: string,
    code: string,
    expiresInSeconds: number,
  ): Promise<SmsDispatchResult> {
    this.sentCodesByPhone.set(phone, code);

    if (process.env.NODE_ENV !== 'test') {
      const masked = maskEgyptPhone(phone);
      this.logger.log(
        `[DEV_SANDBOX_SMS] Simulated OTP delivery to ${masked} (delivered: false, simulated: true, TTL: ${expiresInSeconds}s)`,
      );
    }

    return {
      provider: 'DEV_SANDBOX_SMS',
      delivered: false,
      simulated: true,
      dispatchedAt: new Date().toISOString(),
    };
  }

  getLastDispatchedCodeForPhone(phone: string): string | null {
    return this.sentCodesByPhone.get(phone) ?? null;
  }
}

/**
 * Production telecom SMS provider adapter.
 *
 * Security Invariant:
 * - Fails closed: until live telecom gateway credentials (VictoryLink / Vodafone Egypt / Twilio)
 *   are connected, it explicitly rejects delivery with HTTP 503 (SERVICE_UNAVAILABLE).
 * - Never fabricates fake delivery success.
 * - Validates provider against runtime allowlist.
 */
@Injectable()
export class ProductionTelecomSmsProvider implements SmsProvider {
  private readonly logger = new Logger(ProductionTelecomSmsProvider.name);

  async sendOtpCode(
    phone: string,
    _code: string,
    _expiresInSeconds: number,
  ): Promise<SmsDispatchResult> {
    const rawProvider = process.env.SMS_PROVIDER_TYPE?.trim();

    if (!isSupportedSmsProvider(rawProvider) || rawProvider === 'DEV_SANDBOX_SMS') {
      this.logger.error(
        `[TELECOM_SMS_ERROR] Invalid or unauthorized SMS provider '${rawProvider}' in production.`,
      );
      throw new HttpException(
        'Telecom SMS gateway configuration is invalid or missing.',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }

    const masked = maskEgyptPhone(phone);
    this.logger.error(
      `[TELECOM_SMS_ERROR] Telecom gateway adapter for ${rawProvider} is pending live gateway credentials. Rejecting delivery to ${masked} (fail-closed).`,
    );

    throw new HttpException(
      `SMS delivery is temporarily unavailable. Live telecom gateway adapter for ${rawProvider} requires production credentials.`,
      HttpStatus.SERVICE_UNAVAILABLE,
    );
  }
}

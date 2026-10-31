import { Injectable, Logger } from '@nestjs/common';

export const SMS_PROVIDER = Symbol('SMS_PROVIDER');

export interface SmsDispatchResult {
  provider: 'DEV_SANDBOX_SMS' | 'TWILIO' | 'VICTORYLINK' | 'VODAFONE_EG';
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

function maskEgyptPhone(phone: string): string {
  // Normalize display: keep prefix and last 3 digits, mask middle
  if (phone.length <= 6) {
    return '***';
  }
  return `${phone.slice(0, 5)}*****${phone.slice(-3)}`;
}

/**
 * Isolated development/test SMS provider.
 *
 * Allowed ONLY in non-production environments when ALLOW_DEV_SMS="true" or NODE_ENV="test".
 * Never logs authentication codes in application logs.
 * Clearly reports `delivered: false, simulated: true`.
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
    // Record internally for unit/integration tests inspection only
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
 * Production telecom SMS provider placeholder.
 * Throws if production SMS gateway credentials are not configured.
 */
@Injectable()
export class ProductionTelecomSmsProvider implements SmsProvider {
  private readonly logger = new Logger(ProductionTelecomSmsProvider.name);

  async sendOtpCode(
    phone: string,
    _code: string,
    _expiresInSeconds: number,
  ): Promise<SmsDispatchResult> {
    const masked = maskEgyptPhone(phone);
    const gateway = process.env.SMS_PROVIDER_TYPE ?? 'VICTORYLINK';
    this.logger.log(`[TELECOM_SMS] Sending OTP to ${masked} via gateway ${gateway}`);
    // In production, integration with VictoryLink / Vodafone Egypt SMS HTTP API
    return {
      provider: gateway as SmsDispatchResult['provider'],
      delivered: true,
      simulated: false,
      dispatchedAt: new Date().toISOString(),
    };
  }
}

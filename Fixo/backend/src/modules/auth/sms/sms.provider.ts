import { Injectable, Logger } from '@nestjs/common';

export const SMS_PROVIDER = Symbol('SMS_PROVIDER');

export interface SmsDispatchResult {
  provider: 'DEV_SANDBOX_SMS' | 'EXTERNAL_GATEWAY';
  delivered: boolean;
  dispatchedAt: string;
}

export interface SmsProvider {
  sendOtpCode(phone: string, code: string, expiresInSeconds: number): Promise<SmsDispatchResult>;
  getLastDispatchedCodeForPhone?(phone: string): string | null;
}

/**
 * Isolated development/test SMS provider.
 *
 * Clearly separated from production telecom gateways (VictoryLink / Vodafone Egypt / Twilio).
 * Never bypasses OTP hashing or verification; it only records the outbound 6-digit OTP
 * in memory/logs when real SMS credentials are not configured.
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
      this.logger.log(
        `[DEV_SANDBOX_SMS] Dispatched 6-digit OTP [${code}] to ${phone} (TTL: ${expiresInSeconds}s)`,
      );
    }
    return {
      provider: 'DEV_SANDBOX_SMS',
      delivered: true,
      dispatchedAt: new Date().toISOString(),
    };
  }

  getLastDispatchedCodeForPhone(phone: string): string | null {
    return this.sentCodesByPhone.get(phone) ?? null;
  }
}


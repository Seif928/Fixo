import { UnauthorizedException } from '@nestjs/common';
import { UserRole } from '@prisma/client';
import { AuthService } from './auth.service';
import { signFixoJwt, verifyFixoJwt } from './utils/jwt-token.util';

describe('Provider recovery invalidates custom refresh sessions', () => {
  const secret = 'b'.repeat(64);
  const authTime = Math.floor(Date.now() / 1000) - 3600;
  let service: AuthService, db: any, policy: any;
  const user = {
    id: 'fixture-user',
    firebaseUid: 'fixture-provider',
    phone: '',
    email: 'fixture@example.test',
    fullName: 'Fixture',
    role: UserRole.CUSTOMER,
    preferredLocale: 'en',
    arrivalAlertsEnabled: false,
    rewardPoints: 0,
  };
  beforeEach(() => {
    db = {
      isDatabaseConnected: () => true,
      getStorageMode: () => 'POSTGRES_PRISMA',
      user: { findUnique: jest.fn().mockResolvedValue(user) },
      $transaction: jest.fn().mockResolvedValue({ status: 'SUCCESS' }),
    };
    policy = { assertValid: jest.fn().mockResolvedValue(undefined) };
    service = new AuthService(db, {} as any, {} as any, policy);
    service.configureSecurity({
      accessSecret: 'a'.repeat(64),
      refreshSecret: secret,
      otpHmacSecret: 'c'.repeat(64),
      smsProviderType: 'DISABLED',
      isProduction: true,
      allowDevSms: false,
      allowInMemoryFallback: false,
      allowTestFixedOtp: false,
    });
  });
  function refreshToken(time: number | undefined) {
    return signFixoJwt(
      {
        sub: user.id,
        phone: '',
        role: user.role,
        type: 'refresh',
        ...(time === undefined ? {} : { firebaseAuthTime: time }),
      } as any,
      secret,
      3600,
    ).token;
  }
  it('rejects a provider-revoked session before creating any replacement', async () => {
    policy.assertValid.mockRejectedValue(
      new UnauthorizedException('Provider session revoked.'),
    );
    await expect(
      service.refreshTokens({ refreshToken: refreshToken(authTime) }),
    ).rejects.toThrow(UnauthorizedException);
    expect(policy.assertValid).toHaveBeenCalledWith(user.firebaseUid, authTime);
    expect(db.$transaction).not.toHaveBeenCalled();
  });
  it('carries the original provider authentication time through rotation', async () => {
    const result = await service.refreshTokens({
      refreshToken: refreshToken(authTime),
    });
    expect(policy.assertValid).toHaveBeenCalledWith(user.firebaseUid, authTime);
    expect(verifyFixoJwt(result.refreshToken, secret)).toMatchObject({
      firebaseAuthTime: authTime,
    });
  });
  it('requires linked legacy sessions without provider evidence to sign in again', async () => {
    await expect(
      service.refreshTokens({ refreshToken: refreshToken(undefined) }),
    ).rejects.toThrow(UnauthorizedException);
    expect(db.$transaction).not.toHaveBeenCalled();
  });
});

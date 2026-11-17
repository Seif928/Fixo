import { ConflictException, UnauthorizedException } from '@nestjs/common';
import { FirebaseIdentityService } from './firebase-identity.service';
import { validateAuthSecurityConfig } from './config/auth-security.config';

describe('Verified Firebase email session exchange', () => {
  let service: FirebaseIdentityService;
  let verifier: any;
  let db: any;
  let sessions: any;
  beforeEach(() => {
    verifier = {
      verify: jest
        .fn()
        .mockResolvedValue({
          uid: 'verified-uid',
          email: 'owner@example.test',
          email_verified: true,
          auth_time: 1234,
        }),
    };
    db = {
      isDatabaseConnected: () => true,
      user: {
        findUnique: jest.fn().mockResolvedValue(null),
        upsert: jest.fn().mockResolvedValue({ id: 'local-user' }),
      },
    };
    sessions = {
      issueVerifiedUserSession: jest
        .fn()
        .mockResolvedValue({ accessToken: 'TEST-ONLY' }),
    };
    service = new FirebaseIdentityService(db, verifier, sessions);
  });
  it('rejects unverified email before reading or creating an application user', async () => {
    verifier.verify.mockResolvedValue({
      uid: 'uid',
      email: 'owner@example.test',
      email_verified: false,
    });
    await expect(service.exchange('id-token')).rejects.toThrow(
      UnauthorizedException,
    );
    expect(db.user.findUnique).not.toHaveBeenCalled();
    expect(sessions.issueVerifiedUserSession).not.toHaveBeenCalled();
  });
  it('never links an existing phone account solely because an email matches', async () => {
    db.user.findUnique
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce({ id: 'existing-phone-account' });
    await expect(service.exchange('id-token')).rejects.toThrow(
      ConflictException,
    );
    expect(db.user.upsert).not.toHaveBeenCalled();
    expect(sessions.issueVerifiedUserSession).not.toHaveBeenCalled();
  });
  it('creates a customer identity without fabricating a phone or accepting a role from the client', async () => {
    await service.exchange('signed-id-token');
    expect(verifier.verify).toHaveBeenCalledWith('signed-id-token');
    expect(db.user.upsert).toHaveBeenCalledWith({
      where: { firebaseUid: 'verified-uid' },
      update: {},
      create: {
        firebaseUid: 'verified-uid',
        email: 'owner@example.test',
        role: 'CUSTOMER',
      },
    });
    expect(sessions.issueVerifiedUserSession).toHaveBeenCalledWith(
      'local-user',
      1234,
    );
  });
  it('uses the already linked identity without silently changing email or role', async () => {
    db.user.findUnique.mockResolvedValueOnce({ id: 'existing-linked-user' });
    await service.exchange('signed-id-token');
    expect(db.user.upsert).not.toHaveBeenCalled();
    expect(sessions.issueVerifiedUserSession).toHaveBeenCalledWith(
      'existing-linked-user',
      1234,
    );
  });

  it('allows explicit email-only production but still rejects sandbox SMS and missing email configuration', () => {
    const production = {
      NODE_ENV: 'production',
      JWT_ACCESS_SECRET: 'a'.repeat(64),
      JWT_REFRESH_SECRET: 'b'.repeat(64),
      OTP_HMAC_SECRET: 'c'.repeat(64),
      SMS_PROVIDER_TYPE: 'DISABLED',
      FIREBASE_PROJECT_ID: 'fixo-home-services-6507',
    };
    expect(validateAuthSecurityConfig(production).smsProviderType).toBe(
      'DISABLED',
    );
    expect(() =>
      validateAuthSecurityConfig({ ...production, FIREBASE_PROJECT_ID: '' }),
    ).toThrow(/FIREBASE_PROJECT_ID/);
    expect(() =>
      validateAuthSecurityConfig({
        ...production,
        SMS_PROVIDER_TYPE: 'DEV_SANDBOX_SMS',
      }),
    ).toThrow(/forbidden in production/);
  });
});

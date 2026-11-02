import { ConflictException, UnauthorizedException } from '@nestjs/common';
import { PhonePasswordService } from './phone-password.service';

describe('Phone alias and Firebase password authentication', () => {
  let db: any,
    gateway: any,
    verifier: any,
    sessions: any,
    service: PhonePasswordService;
  const account = {
    id: 'customer',
    firebaseUid: 'google-uid',
    email: 'owner@example.test',
    phone: '+201023456789',
    fullName: 'Test Customer',
  };
  beforeEach(() => {
    db = {
      isDatabaseConnected: () => true,
      user: {
        findUnique: jest.fn().mockResolvedValue(account),
        update: jest.fn().mockResolvedValue(account),
      },
      $queryRaw: jest.fn().mockResolvedValue([{ id: 'customer' }]),
    };
    db.$transaction = jest.fn((callback) => callback(db));
    gateway = { signIn: jest.fn().mockResolvedValue('signed-id-token') };
    verifier = {
      verify: jest
        .fn()
        .mockResolvedValue({
          uid: 'google-uid',
          email_verified: true,
          auth_time: 1234,
        }),
    };
    sessions = {
      issueVerifiedUserSession: jest
        .fn()
        .mockResolvedValue({ accessToken: 'test-only' }),
      findUserById: jest.fn().mockResolvedValue(account),
    };
    service = new PhonePasswordService(db, gateway, verifier, sessions);
  });
  it('uses a private server-side email lookup and verifies UID before issuing a session', async () => {
    await service.signIn({
      phone: '01023456789',
      password: 'a-long-test-password',
    });
    expect(gateway.signIn).toHaveBeenCalledWith(
      'owner@example.test',
      'a-long-test-password',
    );
    expect(verifier.verify).toHaveBeenCalledWith('signed-id-token');
    expect(sessions.issueVerifiedUserSession).toHaveBeenCalledWith(
      'customer',
      1234,
    );
  });
  it('never accepts a Firebase token belonging to a different account', async () => {
    verifier.verify.mockResolvedValue({
      uid: 'other-uid',
      email_verified: true,
    });
    await expect(
      service.signIn({ phone: '01023456789', password: 'wrong' }),
    ).rejects.toThrow(UnauthorizedException);
    expect(sessions.issueVerifiedUserSession).not.toHaveBeenCalled();
  });
  it('unknown aliases fail generically without disclosing an email or issuing tokens', async () => {
    db.user.findUnique.mockResolvedValue(null);
    await expect(
      service.signIn({ phone: '01023456789', password: 'wrong' }),
    ).rejects.toThrow('Invalid phone or password.');
    expect(sessions.issueVerifiedUserSession).not.toHaveBeenCalled();
  });
  it('requires a verified Firebase email', async () => {
    verifier.verify.mockResolvedValue({
      uid: 'google-uid',
      email_verified: false,
    });
    await expect(
      service.signIn({ phone: '01023456789', password: 'wrong' }),
    ).rejects.toThrow(UnauthorizedException);
  });
  it('saves first-use profile under the authenticated Google-linked account', async () => {
    db.user.findUnique.mockResolvedValue({
      ...account,
      fullName: null,
      phone: null,
    });
    await service.completeProfile('customer', {
      fullName: '  Test Customer  ',
      phone: '01023456789',
    });
    expect(db.user.update).toHaveBeenCalledWith({
      where: { id: 'customer' },
      data: { fullName: 'Test Customer', phone: '+201023456789' },
    });
  });
  it('does not overwrite an established name or phone during repeated setup', async () => {
    await expect(
      service.completeProfile('customer', {
        fullName: 'Another Person',
        phone: '01023456789',
      }),
    ).rejects.toThrow(ConflictException);
    expect(db.user.update).not.toHaveBeenCalled();
  });
});

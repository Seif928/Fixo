import { Logger, UnauthorizedException } from '@nestjs/common';
import { FirebaseTokenVerifier } from './firebase-identity.service';

const verifyIdToken = jest.fn();
const providerSessions = {
  assertValid: jest.fn().mockResolvedValue(undefined),
  readVerifiedAccount: jest.fn(),
};
jest.mock('firebase-admin/auth', () => ({
  getAuth: () => ({ verifyIdToken }),
}));
jest.mock('firebase-admin/app', () => ({
  getApps: () => [],
  initializeApp: () => ({ name: 'test' }),
}));

describe('Firebase token verification diagnostics', () => {
  const savedProject = process.env.FIREBASE_PROJECT_ID;
  afterEach(() => {
    if (savedProject === undefined) delete process.env.FIREBASE_PROJECT_ID;
    else process.env.FIREBASE_PROJECT_ID = savedProject;
    jest.restoreAllMocks();
  });
  it('rejects verification errors and logs only a safe provider code, never credentials', async () => {
    process.env.FIREBASE_PROJECT_ID = 'fixo-home-services-6507';
    const log = jest.spyOn(Logger.prototype, 'warn').mockImplementation();
    verifyIdToken.mockRejectedValue({
      code: 'auth/argument-error',
      message: 'PRIVATE_TOKEN owner@example.test',
    });
    await expect(
      new FirebaseTokenVerifier(providerSessions).verify('PRIVATE_TOKEN'),
    ).rejects.toThrow(UnauthorizedException);
    expect(log).toHaveBeenCalledWith(
      expect.objectContaining({
        event: 'firebase_identity_rejected',
        code: 'auth/argument-error',
      }),
    );
    expect(JSON.stringify(log.mock.calls)).not.toMatch(
      /PRIVATE_TOKEN|owner@example/,
    );
  });
  it('still verifies the signature and returns only the SDK verified identity', async () => {
    process.env.FIREBASE_PROJECT_ID = 'fixo-home-services-6507';
    verifyIdToken.mockResolvedValue({
      uid: 'verified-fixture',
      email_verified: true,
    });
    expect(
      await new FirebaseTokenVerifier(providerSessions).verify(
        'signed-fixture',
      ),
    ).toEqual({ uid: 'verified-fixture', email_verified: true });
    expect(verifyIdToken).toHaveBeenCalledWith('signed-fixture');
  });
});

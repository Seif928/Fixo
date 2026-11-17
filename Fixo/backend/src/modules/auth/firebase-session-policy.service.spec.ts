import {
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { FirebaseSessionPolicy } from './firebase-session-policy.service';
const getUser = jest.fn();
jest.mock('firebase-admin/auth', () => ({ getAuth: () => ({ getUser }) }));
jest.mock('firebase-admin/app', () => ({
  getApps: () => [],
  cert: () => ({}),
  initializeApp: () => ({}),
}));

describe('Provider session revocation policy', () => {
  const saved = { ...process.env };
  const time = Math.floor(Date.now() / 1000) - 3600;
  const policy = new FirebaseSessionPolicy();
  beforeEach(() => {
    process.env.FIREBASE_PROJECT_ID = 'fixture-project';
    process.env.FIREBASE_SERVICE_ACCOUNT_JSON = JSON.stringify({
      project_id: 'fixture-project',
      client_email: 'fixture@example.test',
      private_key: 'synthetic',
    });
    getUser
      .mockReset()
      .mockResolvedValue({
        disabled: false,
        emailVerified: true,
        tokensValidAfterTime: new Date((time - 1) * 1000).toUTCString(),
      });
  });
  afterEach(() => {
    process.env = { ...saved };
  });
  it('checks the provider account and rejects a password-reset/revoked session', async () => {
    await expect(policy.assertValid('fixture', time)).resolves.toBeUndefined();
    getUser.mockResolvedValue({
      disabled: false,
      emailVerified: true,
      tokensValidAfterTime: new Date((time + 1) * 1000).toUTCString(),
    });
    await expect(policy.assertValid('fixture', time)).rejects.toThrow(
      UnauthorizedException,
    );
  });
  it('rejects disabled, deleted and no-longer-verified accounts', async () => {
    for (const record of [
      { disabled: true, emailVerified: true },
      { disabled: false, emailVerified: false },
    ]) {
      getUser.mockResolvedValue(record);
      await expect(policy.assertValid('fixture', time)).rejects.toThrow(
        UnauthorizedException,
      );
    }
    getUser.mockRejectedValue({ code: 'auth/user-not-found' });
    await expect(policy.assertValid('fixture', time)).rejects.toThrow(
      UnauthorizedException,
    );
  });
  it('follows SDK semantics when no revocation timestamp has ever been set', async () => {
    getUser.mockResolvedValue({ disabled: false, emailVerified: true });
    await expect(policy.assertValid('fixture', time)).resolves.toBeUndefined();
  });
  it('fails closed on missing configuration and provider outages', async () => {
    getUser.mockRejectedValue({ code: 'auth/network-request-failed' });
    await expect(policy.assertValid('fixture', time)).rejects.toThrow(
      ServiceUnavailableException,
    );
    delete process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
    await expect(policy.assertValid('fixture', time)).rejects.toThrow(
      ServiceUnavailableException,
    );
  });
  it('rejects missing or future authentication evidence before calling the provider', async () => {
    for (const value of [
      undefined,
      0,
      -1,
      Number.NaN,
      Math.floor(Date.now() / 1000) + 1000,
    ]) {
      await expect(policy.assertValid('fixture', value)).rejects.toThrow(
        UnauthorizedException,
      );
    }
    expect(getUser).not.toHaveBeenCalled();
  });
});

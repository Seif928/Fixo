import {
  Injectable,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { cert, getApps, initializeApp } from 'firebase-admin/app';

/** Provider revocation is checked at sign-in and each custom refresh, never inferred from local iat. */
@Injectable()
export class FirebaseSessionPolicy {
  async assertValid(
    uid: string,
    authenticationTime: number | undefined,
  ): Promise<void> {
    await this.readVerifiedAccount(uid, authenticationTime);
  }

  async readVerifiedAccount(
    uid: string,
    authenticationTime: number | undefined,
  ): Promise<{ uid: string; email: string | null }> {
    if (
      !uid ||
      !Number.isSafeInteger(authenticationTime) ||
      !authenticationTime ||
      authenticationTime < 0 ||
      authenticationTime > Math.floor(Date.now() / 1000) + 60
    ) {
      throw new UnauthorizedException(
        'Sign in again to renew your account session.',
      );
    }
    const projectId = process.env.FIREBASE_PROJECT_ID;
    let credentials: {
      project_id?: string;
      client_email?: string;
      private_key?: string;
    };
    try {
      credentials = JSON.parse(
        process.env.FIREBASE_SERVICE_ACCOUNT_JSON ?? '{}',
      );
    } catch {
      throw new ServiceUnavailableException(
        'Account session validation is not configured.',
      );
    }
    if (
      !projectId ||
      credentials.project_id !== projectId ||
      !credentials.client_email ||
      !credentials.private_key
    ) {
      throw new ServiceUnavailableException(
        'Account session validation is not configured.',
      );
    }
    const name = `fixo-session-policy-${projectId}`;
    let timer: ReturnType<typeof setTimeout> | undefined;
    try {
      const app =
        getApps().find((app) => app.name === name) ??
        initializeApp(
          {
            projectId,
            credential: cert({
              projectId,
              clientEmail: credentials.client_email,
              privateKey: credentials.private_key,
            }),
          },
          name,
        );
      const { getAuth } = await import('firebase-admin/auth');
      const record = await Promise.race([
        getAuth(app).getUser(uid),
        new Promise<never>((_, reject) => {
          timer = setTimeout(
            () =>
              reject(
                new ServiceUnavailableException(
                  'Account session validation is temporarily unavailable.',
                ),
              ),
            5000,
          );
        }),
      ]);
      // Firebase's SDK defines an absent valid-since value as never revoked.
      const validAfter = record.tokensValidAfterTime
        ? new Date(record.tokensValidAfterTime).getTime() / 1000
        : 0;
      if (
        record.disabled ||
        !record.emailVerified ||
        !Number.isFinite(validAfter) ||
        authenticationTime < validAfter
      ) {
        throw new UnauthorizedException(
          'This account session has ended. Sign in again.',
        );
      }
      return { uid, email: record.email ?? null };
    } catch (error) {
      if (
        error instanceof UnauthorizedException ||
        error instanceof ServiceUnavailableException
      )
        throw error;
      const code =
        error && typeof error === 'object' && 'code' in error ? error.code : '';
      if (code === 'auth/user-not-found' || code === 'auth/user-disabled') {
        throw new UnauthorizedException(
          'This account session has ended. Sign in again.',
        );
      }
      throw new ServiceUnavailableException(
        'Account session validation is temporarily unavailable.',
      );
    } finally {
      if (timer) clearTimeout(timer);
    }
  }
}

import { execFileSync } from 'node:child_process';

describe('Firebase in the production CommonJS loader', () => {
  it('loads the real SDK and rejects a malformed token without requiring ESM interop', () => {
    const script = `
      const { initializeApp } = require('firebase-admin/app');
      const { getAuth } = require('firebase-admin/auth');
      const app = initializeApp({ projectId: 'fixo-runtime-fixture' });
      getAuth(app).verifyIdToken('invalid-test-token').then(() => process.exit(2)).catch(error => {
        if (error.code !== 'auth/argument-error') process.exit(3);
        console.log('FIREBASE_COMMONJS_OK');
      });
    `;
    const result = execFileSync(process.execPath,
      ['--no-experimental-require-module', '-e', script],
      { timeout: 15000, encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'] });
    expect(result.trim()).toBe('FIREBASE_COMMONJS_OK');
  });
});

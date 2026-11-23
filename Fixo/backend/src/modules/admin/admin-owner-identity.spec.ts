import { AdminAccessService } from './admin-access.service';

describe('Owner identity is restricted to the configured verified account', () => {
  const previous = process.env.FIXO_OWNER_EMAIL;
  afterEach(() => {
    if (previous === undefined) delete process.env.FIXO_OWNER_EMAIL;
    else process.env.FIXO_OWNER_EMAIL = previous;
  });
  it('rejects an OWNER membership for a different email before authority is granted', async () => {
    process.env.FIXO_OWNER_EMAIL = 'actual-owner@example.test';
    const db = {
      isDatabaseConnected: () => true,
      user: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'other',
          firebaseUid: 'firebase-other',
          email: 'other@example.test',
        }),
      },
      adminMembership: {
        findUnique: jest.fn().mockResolvedValue({
          email: 'other@example.test',
          userId: 'other',
          role: 'OWNER',
          isActive: true,
        }),
      },
      $transaction: jest.fn().mockResolvedValue({ role: 'OWNER' }),
    };
    const provider = {
      readVerifiedAccount: jest.fn().mockResolvedValue({
        uid: 'firebase-other',
        email: 'other@example.test',
      }),
    };
    const service = new AdminAccessService(db as any, provider as any);
    await expect(
      service.resolve({
        sub: 'other',
        firebaseAuthTime: Math.floor(Date.now() / 1000),
      } as any),
    ).rejects.toThrow();
    expect(db.$transaction).not.toHaveBeenCalled();
  });
  it('rechecks the owner email inside mutations, even with a previously valid actor', async () => {
    process.env.FIXO_OWNER_EMAIL = 'actual-owner@example.test';
    const tx = {
      $executeRaw: jest.fn(),
      adminMembership: {
        findUnique: jest.fn().mockResolvedValue({
          email: 'other@example.test',
          role: 'OWNER',
          isActive: true,
        }),
      },
      adminAuditLog: { create: jest.fn() },
    };
    const db = { $transaction: (operation: any) => operation(tx) };
    const service = new AdminAccessService(db as any, {} as any);
    const operation = jest.fn().mockResolvedValue({ value: true, details: {} });
    await expect(
      service.mutate(
        { userId: 'other', role: 'OWNER', authTime: Date.now() / 1000 },
        true,
        'TEST',
        '1',
        operation,
      ),
    ).rejects.toThrow();
    expect(operation).not.toHaveBeenCalled();
  });
});

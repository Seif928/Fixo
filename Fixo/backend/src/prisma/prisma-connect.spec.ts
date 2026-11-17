import { PrismaService } from './prisma.service';

describe('Cloud database connection deadline', () => {
  let prisma: PrismaService;
  let original: NodeJS.ProcessEnv;
  beforeEach(() => {
    original = { ...process.env };
    process.env.NODE_ENV = 'production';
    process.env.ALLOW_IN_MEMORY_FALLBACK = 'false';
    delete process.env.DATABASE_CONNECT_TIMEOUT_MS;
    jest.useFakeTimers();
    prisma = new PrismaService();
    jest.spyOn(prisma, '$queryRaw').mockResolvedValue([]);
  });
  afterEach(() => { process.env = original; jest.useRealTimers(); });
  it('allows a legitimate cloud connection slower than 1500 ms', async () => {
    let finish!: () => void;
    jest.spyOn(prisma, '$connect').mockImplementation(() => new Promise<void>(resolve => { finish = resolve; }));
    const connect = prisma.onModuleInit();
    await jest.advanceTimersByTimeAsync(3000);
    finish();
    await connect;
    expect(prisma.isDatabaseConnected()).toBe(true);
    expect(jest.getTimerCount()).toBe(0);
  });
  it('still fails closed at the bounded connection deadline', async () => {
    process.env.DATABASE_CONNECT_TIMEOUT_MS = '5000';
    jest.spyOn(prisma, '$connect').mockImplementation(() => new Promise<void>(() => {}));
    const result = expect(prisma.onModuleInit()).rejects.toThrow(/timeout \(5000ms\)/);
    await jest.advanceTimersByTimeAsync(5000);
    await result;
    expect(prisma.isDatabaseConnected()).toBe(false);
  });
});

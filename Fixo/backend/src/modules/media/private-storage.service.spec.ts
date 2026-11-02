import { ServiceUnavailableException } from '@nestjs/common';
import { PrivateStorageService } from './private-storage.service';

describe('PrivateStorageService', () => {
  const original = { ...process.env };
  afterEach(() => { process.env = { ...original }; jest.restoreAllMocks(); });

  it('fails closed without server credentials instead of fabricating an upload', async () => {
    delete process.env.SUPABASE_SERVICE_ROLE_KEY;
    delete process.env.SUPABASE_URL;
    const fetchSpy = jest.spyOn(global, 'fetch');
    await expect(new PrivateStorageService().put('avatars/user-test/image.webp', Buffer.from('test'), 'image/webp'))
      .rejects.toThrow(ServiceUnavailableException);
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it('uploads bytes privately and returns no public or signed bearer URL', async () => {
    process.env.SUPABASE_URL = 'https://bvahuhtlrxnbbllkukhd.supabase.co';
    process.env.SUPABASE_SERVICE_ROLE_KEY = 'sb_secret_TEST_ONLY';
    const fetchSpy = jest.spyOn(global, 'fetch').mockResolvedValue(
      new Response(JSON.stringify({ Key: 'fixo-private/avatars/user-test/image.webp' }), { status: 200 }),
    );
    const key = 'avatars/user-test/image.webp';
    expect(await new PrivateStorageService().put(key, Buffer.from('test'), 'image/webp')).toBe(key);
    expect(fetchSpy).toHaveBeenCalledTimes(1);
    const options = fetchSpy.mock.calls[0][1]!;
    expect(new Headers(options.headers).get('x-upsert')).toBe('false');
    expect(options.body).toBeDefined();
  });

  it('rejects path traversal and oversized media before contacting Storage', async () => {
    const storage = new PrivateStorageService();
    const fetchSpy = jest.spyOn(global, 'fetch');
    await expect(storage.put('../outside', Buffer.from('x'), 'image/webp')).rejects.toThrow();
    await expect(storage.put('avatars/user/image.webp', Buffer.alloc(2 * 1024 * 1024 + 1), 'image/webp')).rejects.toThrow();
    expect(fetchSpy).not.toHaveBeenCalled();
  });
});

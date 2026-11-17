import { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AvatarController } from './avatar.controller';
import { AvatarService } from './avatar.service';

describe('Avatar HTTP boundary', () => {
  let app: INestApplication;
  let base: string;
  const service = { save: jest.fn().mockResolvedValue({ hasAvatar: true, avatarVersion: 'fixture' }), read: jest.fn().mockResolvedValue(Buffer.from('PRIVATE_TEST_BYTES')) };
  beforeAll(async () => {
    const module = await Test.createTestingModule({ controllers: [AvatarController], providers: [{ provide: AvatarService, useValue: service }] })
      .overrideGuard(JwtAuthGuard).useValue({ canActivate: (ctx: any) => {
        const request = ctx.switchToHttp().getRequest();
        if (request.headers.authorization !== 'Bearer LOCAL_TEST') return false;
        request.user = { sub: 'user-test' }; return true;
      } }).compile();
    app = module.createNestApplication();
    await app.listen(0, '127.0.0.1');
    base = await app.getUrl();
  });
  beforeEach(() => jest.clearAllMocks());
  afterAll(async () => { app.getHttpServer().closeAllConnections?.(); await app.close(); });

  const photo = (size: number) => {
    const form = new FormData();
    form.set('photo', new Blob([Buffer.alloc(size)], { type: 'image/png' }), 'photo.png');
    return form;
  };

  it('requires authentication before accepting any upload', async () => {
    const response = await fetch(`${base}/users/me/avatar`, { method: 'POST', body: photo(50) });
    await response.arrayBuffer();
    expect(response.status).toBe(403);
    expect(service.save).not.toHaveBeenCalled();
  });
  it('bounds multipart files to 2 MB and derives ownership from the guard', async () => {
    let response = await fetch(`${base}/users/me/avatar`, { method: 'POST', headers: { Authorization: 'Bearer LOCAL_TEST' }, body: photo(2 * 1024 * 1024 + 1) });
    await response.arrayBuffer();
    expect(response.status).toBe(413);
    expect(service.save).not.toHaveBeenCalled();
    response = await fetch(`${base}/users/me/avatar`, { method: 'POST', headers: { Authorization: 'Bearer LOCAL_TEST' }, body: photo(50) });
    await response.arrayBuffer();
    expect(response.status).toBe(200);
    expect(service.save).toHaveBeenCalledWith('user-test', expect.objectContaining({ size: 50 }));
  });
  it('serves authenticated bytes without allowing shared caching', async () => {
    const response = await fetch(`${base}/users/me/avatar`, { headers: { Authorization: 'Bearer LOCAL_TEST' } });
    expect(await response.text()).toBe('PRIVATE_TEST_BYTES');
    expect(response.headers.get('cache-control')).toBe('private, no-store');
    expect(response.headers.get('x-content-type-options')).toBe('nosniff');
    expect(service.read).toHaveBeenCalledWith('user-test');
  });
});

import {
  BadRequestException,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
const sharp: typeof import('sharp').default = require('sharp');
import { AvatarService } from './avatar.service';

describe('AvatarService', () => {
  let prisma: any;
  let storage: any;
  let service: AvatarService;
  beforeEach(() => {
    prisma = {
      isDatabaseConnected: () => false,
      user: {
        findUnique: jest
          .fn()
          .mockResolvedValue({
            id: 'user-test',
            avatarUrl: 'avatars/user-test/old.webp',
          }),
        update: jest.fn(),
      },
      $transaction: jest.fn(async (callback) => callback(prisma)),
    };
    storage = {
      put: jest.fn(async (key) => key),
      remove: jest.fn(),
      get: jest.fn(),
    };
    service = new AvatarService(prisma, storage);
  });
  const image = async () =>
    sharp({
      create: { width: 40, height: 20, channels: 3, background: '#173f35' },
    })
      .png()
      .toBuffer();

  it('rejects a photo whose declared type differs from its decoded format', async () => {
    const bytes = await image();
    await expect(
      service.save('user-test', {
        buffer: bytes,
        mimetype: 'image/jpeg',
        size: bytes.length,
      }),
    ).rejects.toThrow(BadRequestException);
    expect(storage.put).not.toHaveBeenCalled();
  });

  it('decodes a real image, strips metadata and saves an opaque private reference', async () => {
    const bytes = await image();
    const result = await service.save('user-test', {
      buffer: bytes,
      mimetype: 'image/png',
      size: bytes.length,
    });
    const [key, uploaded, mime] = storage.put.mock.calls[0];
    expect(key).toMatch(/^avatars\/user-test\/[a-f0-9-]+\.webp$/);
    expect(mime).toBe('image/webp');
    const metadata = await sharp(uploaded).metadata();
    expect(metadata.format).toBe('webp');
    expect(metadata.width).toBe(256);
    expect(metadata.height).toBe(256);
    expect(metadata.exif).toBeUndefined();
    expect(prisma.user.update).toHaveBeenCalledWith({
      where: { id: 'user-test' },
      data: { avatarUrl: key },
    });
    expect(storage.remove).toHaveBeenCalledWith('avatars/user-test/old.webp');
    expect(result.hasAvatar).toBe(true);
    expect(JSON.stringify(result)).not.toContain('avatars/');
  });

  it('preserves the old avatar when upload fails', async () => {
    storage.put.mockRejectedValue(
      new ServiceUnavailableException('Storage unavailable'),
    );
    const bytes = await image();
    await expect(
      service.save('user-test', {
        buffer: bytes,
        mimetype: 'image/png',
        size: bytes.length,
      }),
    ).rejects.toThrow(ServiceUnavailableException);
    expect(prisma.user.update).not.toHaveBeenCalled();
    expect(storage.remove).not.toHaveBeenCalled();
  });

  it('cleans the newly uploaded object if the database write fails', async () => {
    prisma.user.update.mockRejectedValue(new Error('DB unavailable'));
    const bytes = await image();
    await expect(
      service.save('user-test', {
        buffer: bytes,
        mimetype: 'image/png',
        size: bytes.length,
      }),
    ).rejects.toThrow();
    expect(storage.remove).toHaveBeenCalledWith(storage.put.mock.calls[0][0]);
    expect(storage.remove).not.toHaveBeenCalledWith(
      'avatars/user-test/old.webp',
    );
  });

  it('rejects disguised, corrupt and oversized files without upload', async () => {
    await expect(
      service.save('user-test', {
        buffer: Buffer.from('<svg/>'),
        mimetype: 'image/png',
        size: 6,
      }),
    ).rejects.toThrow(BadRequestException);
    await expect(
      service.save('user-test', {
        buffer: Buffer.alloc(2 * 1024 * 1024 + 1),
        mimetype: 'image/jpeg',
        size: 2 * 1024 * 1024 + 1,
      }),
    ).rejects.toThrow(BadRequestException);
    expect(storage.put).not.toHaveBeenCalled();
  });

  it('reads only the authenticated account current avatar', async () => {
    storage.get.mockResolvedValue(Buffer.from('WEBP_TEST'));
    expect(await service.read('user-test')).toEqual(Buffer.from('WEBP_TEST'));
    expect(storage.get).toHaveBeenCalledWith('avatars/user-test/old.webp');
    prisma.user.findUnique.mockResolvedValue({
      id: 'user-test',
      avatarUrl: 'avatars/another-user/private.webp',
    });
    await expect(service.read('user-test')).rejects.toThrow(NotFoundException);
  });
});

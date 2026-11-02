import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { normalizePrivatePhoto } from './normalize-private-photo';
import { PrismaService } from '../../prisma/prisma.service';
import { PrivateStorageService } from './private-storage.service';

export interface AvatarUpload {
  buffer: Buffer;
  mimetype: string;
  size: number;
}

@Injectable()
export class AvatarService {
  private readonly logger = new Logger(AvatarService.name);
  constructor(
    private readonly prisma: PrismaService,
    private readonly storage: PrivateStorageService,
  ) {}

  async save(userId: string, file: AvatarUpload) {
    const bytes = await normalizePrivatePhoto(
      file?.buffer,
      file?.mimetype,
      'avatar',
    );
    const key = `avatars/${userId}/${randomUUID()}.webp`;
    await this.storage.put(key, bytes, 'image/webp');
    let oldKey: string | null;
    try {
      oldKey = await this.prisma.$transaction(async (tx) => {
        if (this.prisma.isDatabaseConnected()) {
          await tx.$queryRaw`SELECT id FROM "User" WHERE id = ${userId} FOR UPDATE`;
        }
        const user = await tx.user.findUnique({ where: { id: userId } });
        if (!user) throw new NotFoundException('Account was not found.');
        await tx.user.update({
          where: { id: userId },
          data: { avatarUrl: key },
        });
        return user.avatarUrl;
      });
    } catch (error) {
      await this.removeOrphan(key);
      throw error;
    }
    if (oldKey?.startsWith(`avatars/${userId}/`))
      await this.removeOrphan(oldKey);
    return {
      hasAvatar: true,
      avatarVersion: key.split('/').pop()!.replace('.webp', ''),
    };
  }

  async read(userId: string): Promise<Buffer> {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user?.avatarUrl?.startsWith(`avatars/${userId}/`)) {
      throw new NotFoundException('No profile photo has been added.');
    }
    return this.storage.get(user.avatarUrl);
  }

  private async removeOrphan(key: string) {
    try {
      await this.storage.remove(key);
    } catch {
      this.logger.warn('Private avatar cleanup needs retry.');
    }
  }
}

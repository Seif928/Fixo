import { BadRequestException, ConflictException, Injectable, NotFoundException, ServiceUnavailableException } from '@nestjs/common';
import { createHash } from 'crypto';
import { cert, getApps, initializeApp } from 'firebase-admin/app';
import { PrismaService } from '../../prisma/prisma.service';

const hash = (token: string) => createHash('sha256').update(token).digest('hex');

/** FCM HTTP v1, with bounded requests. Credentials are server-only. */
@Injectable()
export class PushSender {
  configured(): boolean {
    try {
      const value = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON ?? '{}');
      return value.project_id === process.env.FIREBASE_PROJECT_ID &&
        typeof value.client_email === 'string' && typeof value.private_key === 'string';
    } catch { return false; }
  }

  async send(tokens: string[], payload: { notification: { title: string; body: string }; data: { bookingId: string } }) {
    if (!this.configured()) throw new ServiceUnavailableException('Device push is not configured.');
    const credentials = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON!);
    const name = 'fixo-device-push';
    const app = getApps().find(app => app.name === name) ?? initializeApp({ credential: cert(credentials), projectId: credentials.project_id }, name);
    let timer: ReturnType<typeof setTimeout> | undefined;
    const access = await Promise.race([
      app.options.credential!.getAccessToken(),
      new Promise<never>((_, reject) => { timer = setTimeout(() => reject(new Error('Push authentication timeout.')), 8000); }),
    ]).finally(() => clearTimeout(timer));
    const results = await Promise.all(tokens.map(async token => {
      const response = await fetch(`https://fcm.googleapis.com/v1/projects/${credentials.project_id}/messages:send`, {
        method: 'POST', headers: { Authorization: `Bearer ${access.access_token}`, 'Content-Type': 'application/json' },
        // FIDs are canonical 22-character identifiers; older registration tokens stay supported.
        // Firebase's own VALID_FID_PATTERN is /^[cdef][\w-]{21}$/.
        body: JSON.stringify({ message: { ...(/^[cdef][\w-]{21}$/.test(token) ? { fid: token } : { token }), ...payload } }), signal: AbortSignal.timeout(8000),
      });
      if (response.ok) return { accepted: true, invalid: null };
      const error = await response.json() as { error?: { details?: { errorCode?: string }[] } };
      if (error.error?.details?.some(detail => detail.errorCode === 'UNREGISTERED')) return { accepted: false, invalid: token };
      throw new Error('Push provider did not accept the request.');
    }));
    return { acceptedCount: results.filter(result => result.accepted).length, invalidTokens: results.flatMap(result => result.invalid ? [result.invalid] : []) };
  }
}

@Injectable()
export class PushService {
  constructor(private readonly prisma: PrismaService, private readonly sender: PushSender) {}

  status() {
    return { configured: this.sender.configured(), webVapidKey: process.env.FIREBASE_WEB_VAPID_KEY ?? null,
      iosConfigured: process.env.FIXO_APNS_CONFIGURED === 'true' };
  }

  async register(actor: string, dto: { token: string; platform: string }) {
    if (!this.prisma.isDatabaseConnected() || !this.sender.configured()) throw new ServiceUnavailableException('Device push is not configured.');
    if (!['ANDROID', 'WEB', 'IOS'].includes(dto.platform) || typeof dto.token !== 'string' || dto.token.length < 20 || dto.token.length > 4096) throw new BadRequestException('Invalid device registration.');
    if (dto.platform === 'IOS' && process.env.FIXO_APNS_CONFIGURED !== 'true') throw new ServiceUnavailableException('Apple push is not configured.');
    const tokenHash = hash(dto.token);
    return this.prisma.$transaction(async tx => {
    // Serialize a user's registrations so concurrent requests cannot evade the cap.
    const owner = await tx.$queryRaw<{ id: string }[]>`SELECT "id" FROM "User" WHERE "id" = ${actor} FOR UPDATE`;
    if (!owner.length) throw new NotFoundException('Account not found.');
    // A token can be presented concurrently by different accounts; bind it once.
    await tx.$queryRaw`SELECT pg_advisory_xact_lock(hashtextextended(${tokenHash}, 0))::text`;
    const existing = await tx.pushDevice.findUnique({ where: { tokenHash } });
    if (existing && existing.userId !== actor) throw new ConflictException('Sign out of the previous account on this device first.');
    if (!existing && await tx.pushDevice.count({ where: { userId: actor } }) >= 10) throw new BadRequestException('Device limit reached. Remove an old device first.');
    return tx.pushDevice.upsert({ where: { tokenHash },
      create: { userId: actor, tokenHash, token: dto.token, platform: dto.platform },
      update: { platform: dto.platform }, select: { id: true, platform: true } });
    });
  }

  async unregister(actor: string, id: string) {
    if (!this.prisma.isDatabaseConnected()) throw new ServiceUnavailableException('Database unavailable.');
    return this.prisma.pushDevice.deleteMany({ where: { id, userId: actor } });
  }

  /** Provider acceptance is not proof that an OS displayed an alert. */
  async notify(actor: string, bookingId: string) {
    try {
      if (!this.prisma.isDatabaseConnected() || !this.sender.configured()) return { accepted: false };
      const user = await this.prisma.user.findUnique({ where: { id: actor }, select: { arrivalAlertsEnabled: true, preferredLocale: true } });
      if (!user?.arrivalAlertsEnabled) return { accepted: false };
      const devices = await this.prisma.pushDevice.findMany({ where: { userId: actor }, take: 10, select: { token: true } });
      if (!devices.length) return { accepted: false };
      const result = await this.sender.send(devices.map(device => device.token), {
        notification: { title: 'FIXO', body: user.preferredLocale === 'ar' ? 'لديك تحديث جديد على طلبك.' : 'You have a new booking update.' }, data: { bookingId },
      });
      if (result.invalidTokens.length) await this.prisma.pushDevice.deleteMany({ where: { userId: actor, tokenHash: { in: result.invalidTokens.map(hash) } } });
      return { accepted: result.acceptedCount > 0 };
    } catch { return { accepted: false }; }
  }
}

import { BadRequestException, ForbiddenException, Injectable, NotFoundException, Optional, ServiceUnavailableException } from '@nestjs/common';
import { BookingStatus, Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { PushService } from './push.service';

const MESSAGE_FIELDS = { id: true, bookingId: true, senderUserId: true, body: true, readAt: true, createdAt: true } as const;
const WRITABLE_STATUSES: BookingStatus[] = ['CONFIRMED', 'PRO_EN_ROUTE', 'ARRIVED', 'IN_PROGRESS'];

@Injectable()
export class CommunicationsService {
  constructor(private readonly prisma: PrismaService, @Optional() private readonly push?: PushService) {}

  private requireDatabase(): void {
    if (!this.prisma.isDatabaseConnected()) {
      throw new ServiceUnavailableException('Communications require a database connection.');
    }
  }

  private async participant(db: Pick<Prisma.TransactionClient, 'booking'>, actor: string, bookingId: string) {
    const booking = await db.booking.findUnique({
      where: { id: bookingId },
      select: { id: true, customerId: true, status: true, proProfile: { select: { userId: true } } },
    });
    if (!booking) throw new NotFoundException('Booking not found.');
    if (booking.customerId !== actor && booking.proProfile?.userId !== actor) {
      throw new ForbiddenException('Only booking participants can access this conversation.');
    }
    return booking;
  }

  async listMessages(actor: string, bookingId: string, query: { limit?: number; before?: string }) {
    this.requireDatabase();
    await this.participant(this.prisma, actor, bookingId);
    const limit = query.limit ?? 30;
    if (!Number.isInteger(limit) || limit < 1 || limit > 50) throw new BadRequestException('limit must be between 1 and 50.');
    let boundary: Prisma.ChatMessageWhereInput = {};
    if (query.before) {
      const cursor = await this.prisma.chatMessage.findFirst({ where: { id: query.before, bookingId }, select: { id: true, createdAt: true } });
      if (!cursor) throw new NotFoundException('Message cursor not found in this booking.');
      boundary = { OR: [{ createdAt: { lt: cursor.createdAt } }, { createdAt: cursor.createdAt, id: { lt: cursor.id } }] };
    }
    const rows = await this.prisma.chatMessage.findMany({
      where: { bookingId, ...boundary }, orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: limit + 1, select: MESSAGE_FIELDS,
    });
    const hasMore = rows.length > limit;
    const items = rows.slice(0, limit);
    return { items, nextCursor: hasMore ? items[items.length - 1].id : null };
  }

  async sendMessage(actor: string, bookingId: string, dto: { body: string }) {
    this.requireDatabase();
    const body = typeof dto.body === 'string' ? dto.body.trim() : '';
    if (!body || body.length > 2000) throw new BadRequestException('Message must contain 1 to 2000 characters.');
    let recipient: string | undefined;
    const message = await this.prisma.$transaction(async tx => {
      // Lock the parent row so assignment/lifecycle changes cannot race authorization.
      await tx.$queryRaw`SELECT "id" FROM "Booking" WHERE "id" = ${bookingId} FOR UPDATE`;
      const booking = await this.participant(tx, actor, bookingId);
      if (!booking.proProfile || !WRITABLE_STATUSES.includes(booking.status)) {
        throw new BadRequestException('Messaging requires an assigned professional and an active confirmed booking.');
      }
      recipient = actor === booking.customerId ? booking.proProfile.userId : booking.customerId;
      return tx.chatMessage.create({ data: { bookingId, senderUserId: actor, body }, select: MESSAGE_FIELDS });
    });
    if (recipient && this.push) await this.push.notify(recipient, bookingId);
    return message;
  }

  async markMessageRead(actor: string, bookingId: string, messageId: string) {
    this.requireDatabase();
    return this.prisma.$transaction(async tx => {
      await tx.$queryRaw`SELECT "id" FROM "Booking" WHERE "id" = ${bookingId} FOR UPDATE`;
      await this.participant(tx, actor, bookingId);
      const message = await tx.chatMessage.findFirst({ where: { id: messageId, bookingId }, select: { id: true } });
      if (!message) throw new NotFoundException('Message not found in this booking.');
      const result = await tx.chatMessage.updateMany({
        where: { id: messageId, bookingId, senderUserId: { not: actor }, readAt: null }, data: { readAt: new Date() },
      });
      return { updatedCount: result.count };
    });
  }

  async notificationFeed(actor: string) {
    this.requireDatabase();
    const participantWhere = { OR: [{ customerId: actor }, { proProfile: { userId: actor } }] };
    const user = await this.prisma.user.findUnique({ where: { id: actor }, select: { arrivalAlertsEnabled: true } });
    if (!user) throw new NotFoundException('Account not found.');
    const [events, messages] = await Promise.all([
      user.arrivalAlertsEnabled ? this.prisma.bookingStatusEvent.findMany({
        where: { booking: participantWhere, toStatus: { not: 'DRAFT' } }, take: 25,
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        select: { id: true, bookingId: true, toStatus: true, createdAt: true, booking: { select: { orderCode: true } } },
      }) : Promise.resolve([]),
      this.prisma.chatMessage.findMany({
        where: { booking: participantWhere, senderUserId: { not: actor }, readAt: null }, take: 25,
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        select: { id: true, bookingId: true, createdAt: true, booking: { select: { orderCode: true } } },
      }),
    ]);
    const items = [
      ...events.map(event => ({ id: `event:${event.id}`, kind: 'BOOKING_STATUS' as const, bookingId: event.bookingId, orderCode: event.booking.orderCode, status: event.toStatus, createdAt: event.createdAt })),
      ...messages.map(message => ({ id: `message:${message.id}`, kind: 'UNREAD_MESSAGE' as const, bookingId: message.bookingId, orderCode: message.booking.orderCode, status: null, createdAt: message.createdAt })),
    ].sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime() || b.id.localeCompare(a.id));
    // This is persisted in-app activity, not a claim of external push delivery.
    return { items, deliveryChannel: 'IN_APP' as const };
  }

  async updateNotificationPreference(actor: string, enabled: boolean) {
    this.requireDatabase();
    if (typeof enabled !== 'boolean') throw new BadRequestException('arrivalAlertsEnabled must be a boolean.');
    const user = await this.prisma.user.update({ where: { id: actor }, data: { arrivalAlertsEnabled: enabled }, select: { arrivalAlertsEnabled: true } });
    return { ...user, deliveryChannel: 'IN_APP' as const };
  }
}

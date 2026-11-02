import { BadRequestException, ForbiddenException, NotFoundException, ServiceUnavailableException } from '@nestjs/common';
import { CommunicationsService } from './communications.service';

describe('Booking communications authorization', () => {
  let db: any;
  let service: CommunicationsService;
  const booking = { id: 'b1', customerId: 'customer', orderCode: 'FX-1234', status: 'CONFIRMED', proProfile: { userId: 'pro' } };

  beforeEach(() => {
    db = {
      isDatabaseConnected: jest.fn().mockReturnValue(true),
      booking: { findUnique: jest.fn().mockResolvedValue(booking) },
      chatMessage: {
        findFirst: jest.fn().mockResolvedValue(null), findMany: jest.fn().mockResolvedValue([]),
        create: jest.fn().mockImplementation(async ({ data }: any) => ({ id: 'm1', ...data })),
        updateMany: jest.fn().mockResolvedValue({ count: 1 }),
      },
      bookingStatusEvent: { findMany: jest.fn().mockResolvedValue([]) },
      user: { findUnique: jest.fn().mockResolvedValue({ arrivalAlertsEnabled: true }), update: jest.fn().mockResolvedValue({ arrivalAlertsEnabled: false }) },
      $queryRaw: jest.fn().mockResolvedValue([{ id: 'b1' }]),
    };
    db.$transaction = jest.fn(async (fn: any) => fn(db));
    service = new CommunicationsService(db);
  });

  it('rejects strangers before reading messages', async () => {
    await expect(service.listMessages('stranger', 'b1', {})).rejects.toThrow(ForbiddenException);
    expect(db.chatMessage.findMany).not.toHaveBeenCalled();
  });

  it.each(['customer', 'pro'])('allows participant %s to read a bounded history', async actor => {
    await service.listMessages(actor, 'b1', { limit: 20 });
    expect(db.chatMessage.findMany).toHaveBeenCalledWith(expect.objectContaining({ where: { bookingId: 'b1' }, take: 21 }));
  });

  it('returns 404 for missing bookings', async () => {
    db.booking.findUnique.mockResolvedValue(null);
    await expect(service.listMessages('customer', 'missing', {})).rejects.toThrow(NotFoundException);
  });

  it('does not synthesize a conversation when no professional is assigned', async () => {
    db.booking.findUnique.mockResolvedValue({ ...booking, proProfile: null, status: 'PENDING_DISPATCH' });
    await expect(service.sendMessage('customer', 'b1', { body: 'Hello' })).rejects.toThrow(BadRequestException);
    expect(db.chatMessage.create).not.toHaveBeenCalled();
  });

  it('rechecks participants inside the locked send transaction', async () => {
    db.booking.findUnique.mockResolvedValue({ ...booking, proProfile: { userId: 'new-pro' } });
    await expect(service.sendMessage('pro', 'b1', { body: 'Hello' })).rejects.toThrow(ForbiddenException);
    expect(db.chatMessage.create).not.toHaveBeenCalled();
  });

  it('persists trimmed messages with sender derived from the session', async () => {
    const result = await service.sendMessage('customer', 'b1', { body: '  Hello  ' });
    expect(result).toMatchObject({ body: 'Hello', senderUserId: 'customer', bookingId: 'b1' });
    expect(db.$queryRaw).toHaveBeenCalled();
  });

  it.each(['', '   ', 'x'.repeat(2001)])('rejects invalid message content', async body => {
    await expect(service.sendMessage('customer', 'b1', { body })).rejects.toThrow(BadRequestException);
    expect(db.chatMessage.create).not.toHaveBeenCalled();
  });

  it.each(['COMPLETED', 'CANCELLED', 'DRAFT'])('keeps %s bookings read-only', async status => {
    db.booking.findUnique.mockResolvedValue({ ...booking, status });
    await expect(service.sendMessage('customer', 'b1', { body: 'Hello' })).rejects.toThrow(BadRequestException);
  });

  it('rejects a pagination cursor from another booking', async () => {
    await expect(service.listMessages('customer', 'b1', { before: 'other-message' })).rejects.toThrow(NotFoundException);
    expect(db.chatMessage.findMany).not.toHaveBeenCalled();
  });

  it('marks only incoming unread messages as read', async () => {
    db.chatMessage.findFirst.mockResolvedValue({ id: 'm1' });
    await service.markMessageRead('customer', 'b1', 'm1');
    expect(db.chatMessage.updateMany).toHaveBeenCalledWith(expect.objectContaining({
      where: { id: 'm1', bookingId: 'b1', senderUserId: { not: 'customer' }, readAt: null },
    }));
  });

  it('enforces user ownership on both sources in the notification feed', async () => {
    await service.notificationFeed('customer');
    const participantWhere = { OR: [{ customerId: 'customer' }, { proProfile: { userId: 'customer' } }] };
    expect(db.bookingStatusEvent.findMany).toHaveBeenCalledWith(expect.objectContaining({
      where: { booking: participantWhere, toStatus: { not: 'DRAFT' } }, take: 25,
    }));
    expect(db.chatMessage.findMany).toHaveBeenCalledWith(expect.objectContaining({
      where: { booking: participantWhere, senderUserId: { not: 'customer' }, readAt: null }, take: 25,
    }));
  });

  it('respects disabled booking alerts without suppressing incoming chat', async () => {
    db.user.findUnique.mockResolvedValue({ arrivalAlertsEnabled: false });
    await service.notificationFeed('customer');
    expect(db.bookingStatusEvent.findMany).not.toHaveBeenCalled();
    expect(db.chatMessage.findMany).toHaveBeenCalled();
  });

  it('never falls back to demo communications', async () => {
    db.isDatabaseConnected.mockReturnValue(false);
    await expect(service.notificationFeed('customer')).rejects.toThrow(ServiceUnavailableException);
  });

  it('saves only the authenticated user notification preference and does not claim push activation', async () => {
    const result = await service.updateNotificationPreference('customer', false);
    expect(db.user.update).toHaveBeenCalledWith({ where: { id: 'customer' }, data: { arrivalAlertsEnabled: false }, select: { arrivalAlertsEnabled: true } });
    expect(result).toEqual({ arrivalAlertsEnabled: false, deliveryChannel: 'IN_APP' });
  });
});

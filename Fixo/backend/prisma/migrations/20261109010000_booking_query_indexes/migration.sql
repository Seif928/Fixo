-- Additive query indexes, matching the Prisma schema. No customer data changes.
CREATE INDEX IF NOT EXISTS "Booking_customerId_status_createdAt_idx" ON "Booking"("customerId", "status", "createdAt");
CREATE INDEX IF NOT EXISTS "Booking_proProfileId_status_idx" ON "Booking"("proProfileId", "status");
CREATE INDEX IF NOT EXISTS "Booking_offeringId_idx" ON "Booking"("offeringId");
CREATE INDEX IF NOT EXISTS "Booking_addressId_idx" ON "Booking"("addressId");
CREATE INDEX IF NOT EXISTS "Booking_status_scheduledDate_idx" ON "Booking"("status", "scheduledDate");
CREATE INDEX IF NOT EXISTS "BookingStatusEvent_bookingId_createdAt_idx" ON "BookingStatusEvent"("bookingId", "createdAt");
CREATE INDEX IF NOT EXISTS "ChatMessage_bookingId_createdAt_idx" ON "ChatMessage"("bookingId", "createdAt");
CREATE INDEX IF NOT EXISTS "ChatMessage_senderUserId_idx" ON "ChatMessage"("senderUserId");

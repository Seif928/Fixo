-- Preserve historical decisions; expire only surplus pending invitations.
WITH ranked AS (
  SELECT id, row_number() OVER (
    PARTITION BY "bookingId", "proProfileId" ORDER BY "createdAt", id
  ) AS position FROM "JobOffer" WHERE status = 'PENDING'
)
UPDATE "JobOffer" SET status = 'EXPIRED', "respondedAt" = CURRENT_TIMESTAMP
WHERE id IN (SELECT id FROM ranked WHERE position > 1);

CREATE UNIQUE INDEX "JobOffer_one_pending_per_booking_pro"
  ON "JobOffer" ("bookingId", "proProfileId") WHERE status = 'PENDING';
CREATE INDEX "JobOffer_proProfileId_status_expiresAt_idx"
  ON "JobOffer" ("proProfileId", status, "expiresAt");
CREATE INDEX "JobOffer_bookingId_proProfileId_createdAt_idx"
  ON "JobOffer" ("bookingId", "proProfileId", "createdAt");

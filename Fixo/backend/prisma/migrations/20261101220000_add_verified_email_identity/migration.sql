-- Existing phone-auth identities remain unchanged. Email-only users have no
-- fabricated phone number; linking existing accounts requires proof of both.
ALTER TABLE "User" ALTER COLUMN "phone" DROP NOT NULL;
ALTER TABLE "User" ADD COLUMN "firebaseUid" TEXT;
CREATE UNIQUE INDEX "User_firebaseUid_key" ON "User"("firebaseUid");

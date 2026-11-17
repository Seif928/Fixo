-- Personal details require only legal name and National ID. Preserve existing
-- transport choices; new applicants have no invented vehicle or transport mode.
ALTER TABLE "ProProfile" ALTER COLUMN "transportMode" DROP NOT NULL;
ALTER TABLE "ProProfile" ALTER COLUMN "transportMode" DROP DEFAULT;
-- Keep the reviewed legal identity separate from an editable display name.
ALTER TABLE "ProProfile" ADD COLUMN "legalName" TEXT;
UPDATE "ProProfile" AS p SET "legalName" = u."fullName"
FROM "User" AS u WHERE u.id = p."userId" AND u."fullName" IS NOT NULL;

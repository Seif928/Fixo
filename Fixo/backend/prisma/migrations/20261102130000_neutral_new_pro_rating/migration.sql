-- Existing reviewed ratings remain untouched; unreviewed public profiles show no rating.
ALTER TABLE "ProProfile" ALTER COLUMN "ratingAvg" SET DEFAULT 0;

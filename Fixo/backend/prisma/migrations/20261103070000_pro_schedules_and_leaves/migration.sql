-- CreateEnum
CREATE TYPE "DayOfWeek" AS ENUM ('SUNDAY', 'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY');

-- CreateEnum
CREATE TYPE "LeaveReason" AS ENUM ('VACATION', 'SICK', 'EMERGENCY', 'PERSONAL');

-- CreateEnum
CREATE TYPE "LeaveStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'CANCELLED');

-- CreateTable
CREATE TABLE "ProWeeklySchedule" (
    "id" TEXT NOT NULL,
    "proProfileId" TEXT NOT NULL,
    "dayOfWeek" "DayOfWeek" NOT NULL,
    "startMinute" INTEGER NOT NULL DEFAULT 540,
    "endMinute" INTEGER NOT NULL DEFAULT 1080,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ProWeeklySchedule_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ProLeave" (
    "id" TEXT NOT NULL,
    "proProfileId" TEXT NOT NULL,
    "startDate" TIMESTAMP(3) NOT NULL,
    "endDate" TIMESTAMP(3) NOT NULL,
    "reason" "LeaveReason" NOT NULL DEFAULT 'PERSONAL',
    "notes" TEXT,
    "status" "LeaveStatus" NOT NULL DEFAULT 'APPROVED',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ProLeave_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "ProWeeklySchedule_proProfileId_dayOfWeek_key" ON "ProWeeklySchedule"("proProfileId", "dayOfWeek");

-- CreateIndex
CREATE INDEX "ProWeeklySchedule_proProfileId_idx" ON "ProWeeklySchedule"("proProfileId");

-- CreateIndex
CREATE INDEX "ProLeave_proProfileId_startDate_endDate_idx" ON "ProLeave"("proProfileId", "startDate", "endDate");

-- CreateIndex
CREATE INDEX "ProLeave_proProfileId_status_idx" ON "ProLeave"("proProfileId", "status");

-- AddForeignKey
ALTER TABLE "ProWeeklySchedule" ADD CONSTRAINT "ProWeeklySchedule_proProfileId_fkey" FOREIGN KEY ("proProfileId") REFERENCES "ProProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ProLeave" ADD CONSTRAINT "ProLeave_proProfileId_fkey" FOREIGN KEY ("proProfileId") REFERENCES "ProProfile"("id") ON DELETE CASCADE ON UPDATE CASCADE;


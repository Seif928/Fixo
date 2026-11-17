import { ServiceUnavailableException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

const cairoDayFormat = new Intl.DateTimeFormat('en-CA', {
  timeZone: 'Africa/Cairo',
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
});

export function cairoDateKey(date: Date): string {
  const parts = cairoDayFormat.formatToParts(date);
  return ['year', 'month', 'day']
    .map((type) => parts.find((p) => p.type === type)!.value)
    .join('-');
}

export function cairoWeekKeys(now: Date): string[] {
  const today = new Date(`${cairoDateKey(now)}T12:00:00Z`);
  return Array.from({ length: 7 }, (_, i) => {
    const day = new Date(today);
    day.setUTCDate(day.getUTCDate() - 6 + i);
    return day.toISOString().slice(0, 10);
  });
}

function exactNumber(value: bigint | number): number {
  const number = Number(value);
  if (!Number.isSafeInteger(number) || number < 0) {
    throw new ServiceUnavailableException(
      'Earnings data cannot be represented safely.',
    );
  }
  return number;
}

/** Aggregate the complete period in SQL; the recent-jobs list never limits earnings. */
export async function readCairoEarnings(
  prisma: PrismaService,
  proId: string,
  now: Date,
) {
  const keys = cairoWeekKeys(now);
  const rows = await prisma.$queryRaw<
    Array<{ day: string; earnings: bigint; jobs: bigint }>
  >`
    SELECT local_day::text AS day, SUM(net)::bigint AS earnings, COUNT(*)::bigint AS jobs
    FROM (
      SELECT ((COALESCE(b."completedAt", b."updatedAt") AT TIME ZONE 'UTC')
        AT TIME ZONE 'Africa/Cairo')::date AS local_day,
        b."netArtisanEgp"::bigint + COALESCE(p."tipEgp", r."tipAmountEgp", 0)::bigint AS net
      FROM "Booking" b
      LEFT JOIN "PaymentRecord" p ON p."bookingId" = b.id
      LEFT JOIN "Review" r ON r."bookingId" = b.id
      WHERE b."proProfileId" = ${proId} AND b.status = 'COMPLETED'
        AND COALESCE(b."completedAt", b."updatedAt") >= ${new Date(now.getTime() - 8 * 86400000)}
    ) completed
    WHERE local_day BETWEEN ${keys[0]}::date AND ${keys[6]}::date
    GROUP BY local_day ORDER BY local_day
  `;
  const byDay = new Map(rows.map((row) => [row.day, row]));
  const enDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  const arDays = [
    'الأحد',
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
  ];
  const weeklyTrajectory = keys.map((date) => {
    const row = byDay.get(date);
    const weekday = new Date(`${date}T12:00:00Z`).getUTCDay();
    return {
      date,
      dayLabelEn: enDays[weekday],
      dayLabelAr: arDays[weekday],
      netEarningsEgp: exactNumber(row?.earnings ?? 0),
      jobsCount: exactNumber(row?.jobs ?? 0),
    };
  });
  const today = weeklyTrajectory[6];
  return {
    todayNetEarningsEgp: today.netEarningsEgp,
    todayCompletedCount: today.jobsCount,
    weeklyNetEarningsEgp: exactNumber(
      weeklyTrajectory.reduce((sum, day) => sum + day.netEarningsEgp, 0),
    ),
    weeklyCompletedCount: exactNumber(
      weeklyTrajectory.reduce((sum, day) => sum + day.jobsCount, 0),
    ),
    weeklyTrajectory,
  };
}

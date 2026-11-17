import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { BookingStatus, DayOfWeek, LeaveReason, LeaveStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateLeaveDto, DayScheduleItemDto, UpdateWeeklyScheduleDto } from './dto/pro-schedule.dto';

const ALL_DAYS: DayOfWeek[] = [
  DayOfWeek.SUNDAY,
  DayOfWeek.MONDAY,
  DayOfWeek.TUESDAY,
  DayOfWeek.WEDNESDAY,
  DayOfWeek.THURSDAY,
  DayOfWeek.FRIDAY,
  DayOfWeek.SATURDAY,
];

const ACTIVE_BOOKING_STATUSES: BookingStatus[] = [
  BookingStatus.CONFIRMED,
  BookingStatus.PRO_EN_ROUTE,
  BookingStatus.ARRIVED,
  BookingStatus.IN_PROGRESS,
];

@Injectable()
export class ProScheduleService {
  constructor(private readonly prisma: PrismaService) {}

  private async getProProfileOrThrow(userId: string) {
    const pro = await this.prisma.proProfile.findUnique({
      where: { userId },
      select: { id: true, userId: true },
    });
    if (!pro) {
      throw new ForbiddenException({
        code: 'PRO_PROFILE_REQUIRED',
        message: 'Only registered professionals have a schedule and leave system',
      });
    }
    return pro;
  }

  async getSchedule(userId: string) {
    const pro = await this.getProProfileOrThrow(userId);

    const savedSchedules = await this.prisma.proWeeklySchedule.findMany({
      where: { proProfileId: pro.id },
    });

    const scheduleMap = new Map(savedSchedules.map((s) => [s.dayOfWeek, s]));

    // Construct full 7-day schedule with defaults if not previously saved
    const weeklySchedule = ALL_DAYS.map((day) => {
      const saved = scheduleMap.get(day);
      if (saved) {
        return {
          dayOfWeek: saved.dayOfWeek,
          startMinute: saved.startMinute,
          endMinute: saved.endMinute,
          isActive: saved.isActive,
        };
      }
      return {
        dayOfWeek: day,
        startMinute: 540,  // 09:00
        endMinute: 1080,   // 18:00
        isActive: day !== DayOfWeek.FRIDAY, // Default Friday off in Egypt
      };
    });

    const leaves = await this.prisma.proLeave.findMany({
      where: {
        proProfileId: pro.id,
        status: { not: LeaveStatus.CANCELLED },
      },
      orderBy: { startDate: 'desc' },
    });

    return {
      weeklySchedule,
      leaves: leaves.map((l) => ({
        id: l.id,
        startDate: l.startDate.toISOString(),
        endDate: l.endDate.toISOString(),
        reason: l.reason,
        notes: l.notes,
        status: l.status,
        createdAt: l.createdAt.toISOString(),
      })),
    };
  }

  async updateSchedule(userId: string, dto: UpdateWeeklyScheduleDto) {
    const pro = await this.getProProfileOrThrow(userId);

    for (const item of dto.days) {
      if (item.isActive && item.startMinute >= item.endMinute) {
        throw new BadRequestException({
          code: 'INVALID_SHIFT_HOURS',
          message: `Shift start must be earlier than shift end for ${item.dayOfWeek}`,
        });
      }
    }

    await this.prisma.$transaction(
      dto.days.map((item) =>
        this.prisma.proWeeklySchedule.upsert({
          where: {
            proProfileId_dayOfWeek: {
              proProfileId: pro.id,
              dayOfWeek: item.dayOfWeek,
            },
          },
          update: {
            startMinute: item.startMinute,
            endMinute: item.endMinute,
            isActive: item.isActive,
          },
          create: {
            proProfileId: pro.id,
            dayOfWeek: item.dayOfWeek,
            startMinute: item.startMinute,
            endMinute: item.endMinute,
            isActive: item.isActive,
          },
        }),
      ),
    );

    return this.getSchedule(userId);
  }

  async createLeave(userId: string, dto: CreateLeaveDto) {
    const pro = await this.getProProfileOrThrow(userId);

    const start = new Date(dto.startDate);
    const end = new Date(dto.endDate);

    if (isNaN(start.getTime()) || isNaN(end.getTime())) {
      throw new BadRequestException({
        code: 'INVALID_DATE_FORMAT',
        message: 'startDate and endDate must be valid ISO date strings',
      });
    }

    if (end < start) {
      throw new BadRequestException({
        code: 'INVALID_DATE_RANGE',
        message: 'Leave endDate cannot be earlier than startDate',
      });
    }

    // Check for active bookings assigned to this pro during the leave period
    const conflictingBookings = await this.prisma.booking.findMany({
      where: {
        proProfileId: pro.id,
        status: { in: ACTIVE_BOOKING_STATUSES },
        scheduledDate: {
          gte: start,
          lte: end,
        },
      },
      select: {
        id: true,
        orderCode: true,
        scheduledDate: true,
        status: true,
      },
    });

    if (conflictingBookings.length > 0) {
      throw new ConflictException({
        code: 'BOOKING_CONFLICT',
        message: 'Cannot schedule leave with active bookings during this period',
        conflictingBookingsCount: conflictingBookings.length,
        conflictingBookings: conflictingBookings.map((b) => ({
          id: b.id,
          orderCode: b.orderCode,
          scheduledDate: b.scheduledDate.toISOString(),
          status: b.status,
        })),
      });
    }

    const leave = await this.prisma.proLeave.create({
      data: {
        proProfileId: pro.id,
        startDate: start,
        endDate: end,
        reason: dto.reason ?? LeaveReason.PERSONAL,
        notes: dto.notes?.trim() || null,
        status: LeaveStatus.APPROVED,
      },
    });

    return {
      id: leave.id,
      startDate: leave.startDate.toISOString(),
      endDate: leave.endDate.toISOString(),
      reason: leave.reason,
      notes: leave.notes,
      status: leave.status,
      createdAt: leave.createdAt.toISOString(),
    };
  }

  async cancelLeave(userId: string, leaveId: string) {
    const pro = await this.getProProfileOrThrow(userId);

    const leave = await this.prisma.proLeave.findUnique({
      where: { id: leaveId },
    });

    if (!leave || leave.proProfileId !== pro.id) {
      throw new NotFoundException({
        code: 'LEAVE_NOT_FOUND',
        message: 'Leave request not found or does not belong to you',
      });
    }

    await this.prisma.proLeave.update({
      where: { id: leaveId },
      data: { status: LeaveStatus.CANCELLED },
    });

    return { success: true };
  }
}


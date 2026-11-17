import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { BookingStatus, ComplaintStatus } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import {
  ComplaintsQueryDto,
  CreateComplaintDto,
  UpdateComplaintStatusDto,
} from './complaints.dto';

@Injectable()
export class ComplaintsService {
  constructor(private readonly db: PrismaService) {}

  async createComplaint(userId: string, dto: CreateComplaintDto) {
    const booking = await this.db.booking.findUnique({
      where: { id: dto.bookingId },
      include: { offering: true },
    });

    if (!booking) {
      throw new NotFoundException(`Booking '${dto.bookingId}' not found.`);
    }

    if (booking.customerId !== userId) {
      throw new ForbiddenException('You do not own this booking.');
    }

    if (booking.status === BookingStatus.DRAFT) {
      throw new BadRequestException(
        'Cannot file a complaint on an unconfirmed draft booking.',
      );
    }

    const existingOpen = await this.db.complaint.findFirst({
      where: {
        bookingId: dto.bookingId,
        status: { in: [ComplaintStatus.OPEN, ComplaintStatus.IN_REVIEW] },
      },
    });

    if (existingOpen) {
      throw new BadRequestException(
        'An active complaint already exists for this booking.',
      );
    }

    const complaint = await this.db.complaint.create({
      data: {
        bookingId: dto.bookingId,
        customerId: userId,
        category: dto.category,
        description: dto.description.trim(),
        photoUrls: dto.photoUrls ?? [],
        status: ComplaintStatus.OPEN,
      },
      include: {
        booking: {
          select: {
            id: true,
            orderCode: true,
            scheduledDate: true,
            status: true,
            offering: {
              select: {
                id: true,
                titleEn: true,
                titleAr: true,
              },
            },
          },
        },
      },
    });

    return complaint;
  }

  async listMyComplaints(userId: string, query: ComplaintsQueryDto) {
    const page = Math.max(1, query.page || 1);
    const limit = Math.min(50, Math.max(1, query.limit || 20));
    const skip = (page - 1) * limit;

    const where: { customerId: string; status?: ComplaintStatus } = {
      customerId: userId,
    };
    if (query.status) {
      where.status = query.status;
    }

    const [items, total] = await this.db.$transaction([
      this.db.complaint.findMany({
        where,
        include: {
          booking: {
            select: {
              id: true,
              orderCode: true,
              scheduledDate: true,
              status: true,
              offering: {
                select: {
                  id: true,
                  titleEn: true,
                  titleAr: true,
                },
              },
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.db.complaint.count({ where }),
    ]);

    return {
      items,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.max(1, Math.ceil(total / limit)),
      },
    };
  }

  async getComplaintDetails(
    userId: string,
    complaintId: string,
    isAdmin = false,
  ) {
    const complaint = await this.db.complaint.findUnique({
      where: { id: complaintId },
      include: {
        booking: {
          select: {
            id: true,
            orderCode: true,
            scheduledDate: true,
            status: true,
            proProfile: {
              select: {
                id: true,
                user: {
                  select: {
                    fullName: true,
                    phone: true,
                  },
                },
              },
            },
            offering: {
              select: {
                id: true,
                titleEn: true,
                titleAr: true,
              },
            },
          },
        },
        customer: {
          select: {
            id: true,
            fullName: true,
            phone: true,
          },
        },
        resolvedBy: {
          select: {
            id: true,
            fullName: true,
          },
        },
      },
    });

    if (!complaint) {
      throw new NotFoundException(`Complaint '${complaintId}' not found.`);
    }

    if (!isAdmin && complaint.customerId !== userId) {
      throw new ForbiddenException('You do not own this complaint.');
    }

    return complaint;
  }

  async adminListComplaints(query: ComplaintsQueryDto) {
    const page = Math.max(1, query.page || 1);
    const limit = Math.min(50, Math.max(1, query.limit || 20));
    const skip = (page - 1) * limit;

    const where: { status?: ComplaintStatus } = {};
    if (query.status) {
      where.status = query.status;
    }

    const [items, total] = await this.db.$transaction([
      this.db.complaint.findMany({
        where,
        include: {
          customer: {
            select: {
              id: true,
              fullName: true,
              phone: true,
            },
          },
          booking: {
            select: {
              id: true,
              orderCode: true,
              scheduledDate: true,
              status: true,
              offering: {
                select: {
                  id: true,
                  titleEn: true,
                  titleAr: true,
                },
              },
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.db.complaint.count({ where }),
    ]);

    return {
      items,
      meta: {
        page,
        limit,
        total,
        totalPages: Math.max(1, Math.ceil(total / limit)),
      },
    };
  }

  async adminUpdateStatus(
    adminUserId: string,
    complaintId: string,
    dto: UpdateComplaintStatusDto,
  ) {
    const complaint = await this.db.complaint.findUnique({
      where: { id: complaintId },
    });

    if (!complaint) {
      throw new NotFoundException(`Complaint '${complaintId}' not found.`);
    }

    const isFinished =
      dto.status === ComplaintStatus.RESOLVED ||
      dto.status === ComplaintStatus.REJECTED;

    const [updated] = await this.db.$transaction([
      this.db.complaint.update({
        where: { id: complaintId },
        data: {
          status: dto.status,
          adminNotes: dto.adminNotes ?? complaint.adminNotes,
          resolvedById: isFinished ? adminUserId : null,
          resolvedAt: isFinished ? new Date() : null,
        },
        include: {
          booking: {
            select: {
              id: true,
              orderCode: true,
            },
          },
          resolvedBy: {
            select: {
              id: true,
              fullName: true,
            },
          },
        },
      }),
      this.db.adminAuditLog.create({
        data: {
          actorUserId: adminUserId,
          action: 'COMPLAINT_STATUS_UPDATE',
          entityId: complaintId,
          details: {
            previousStatus: complaint.status,
            newStatus: dto.status,
            adminNotes: dto.adminNotes ?? null,
          },
        },
      }),
    ]);

    return updated;
  }
}


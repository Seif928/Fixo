import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import {
  BookingStatus,
  DocumentStatus,
  DocumentType,
  ExperienceTier,
  JobOfferStatus,
  PaymentMethodType,
  PaymentStatus,
  ProVerificationStatus,
  TransportMode,
  UserRole,
} from '@prisma/client';
import {
  EGYPT_COVERAGE_ZONES,
  EGYPT_SERVICE_CATEGORIES,
  EGYPT_SERVICE_SUB_SKILLS,
} from '../../prisma/egypt-demo-seed.data';
import { PrismaService } from '../../prisma/prisma.service';
import { INTERNAL_FAILED_PIN_EVENT_NOTE } from '../bookings/bookings.service';
import {
  signPrivateUploadAccessToken,
  validatePrivateUploadPayload,
} from '../bookings/private-upload.util';
import { PushService } from '../communications/push.service';
import {
  ProAdvanceJobStatusDto,
  ProAdminReviewDto,
  ProAvailabilityDto,
  ProDeclineOfferDto,
  ProDocumentUploadDto,
  ProPersonalDetailsDto,
  ProSkillsUpdateDto,
} from './dto/pro.dto';

const REQUIRED_PRO_DOC_TYPES: DocumentType[] = [
  DocumentType.NATIONAL_ID_FRONT,
  DocumentType.NATIONAL_ID_BACK,
  DocumentType.CRIMINAL_RECORD_CERT,
];

const MAX_ARRIVAL_PIN_ATTEMPTS = 5;

@Injectable()
export class ProService {
  constructor(
    private readonly prisma: PrismaService,
    @Optional() private readonly pushService?: PushService,
  ) {}

  private readonly proProfileInclude = {
    user: {
      select: {
        id: true,
        phone: true,
        fullName: true,
        email: true,
        role: true,
        avatarUrl: true,
      },
    },
    primaryCategory: true,
    primaryZone: true,
    coverageZones: true,
    subSkills: true,
    documents: {
      orderBy: { uploadedAt: 'asc' as const },
    },
  };

  /**
   * Returns catalog options for Screens 11 & 12 (active categories, sub-skills,
   * coverage zones, transport modes, and experience tiers).
   */
  async getCatalogOptions() {
    if (!this.prisma.isDatabaseConnected()) {
      return {
        categories: EGYPT_SERVICE_CATEGORIES.map((cat) => ({
          ...cat,
          subSkills: EGYPT_SERVICE_SUB_SKILLS.filter(
            (s) => s.categoryId === cat.id || s.categorySlug === cat.slug,
          ),
        })),
        zones: EGYPT_COVERAGE_ZONES,
        transportModes: Object.values(TransportMode),
        experienceTiers: Object.values(ExperienceTier),
        requiredDocumentTypes: REQUIRED_PRO_DOC_TYPES,
      };
    }

    await this.ensureSubSkillsSeeded();

    const [categories, zones] = await Promise.all([
      this.prisma.serviceCategory.findMany({
        where: { isActive: true },
        include: {
          subSkills: {
            orderBy: { nameEn: 'asc' },
          },
        },
        orderBy: { sortOrder: 'asc' },
      }),
      this.prisma.coverageZone.findMany({
        where: { isActive: true },
        orderBy: { nameEn: 'asc' },
      }),
    ]);

    return {
      categories,
      zones,
      transportModes: Object.values(TransportMode),
      experienceTiers: Object.values(ExperienceTier),
      requiredDocumentTypes: REQUIRED_PRO_DOC_TYPES,
    };
  }

  /**
   * Retrieves the authenticated user's ProProfile (or null if onboarding has not started).
   */
  async getMyProProfile(userId: string) {
    const profile = await this.prisma.proProfile.findUnique({
      where: { userId },
      include: this.proProfileInclude,
    });

    if (!profile) {
      return null;
    }

    return this.mapProProfile(profile);
  }

  /**
   * Screen 11 (Step 1 of 4): Personal Details, Synthetic 14-digit National ID,
   * Primary Coverage Zone, and Transport Mode (`POST /pro/onboarding/personal`).
   */
  async upsertPersonalDetails(userId: string, dto: ProPersonalDetailsDto) {
    if (!/^\d{14}$/.test(dto.nationalIdSynthetic.trim())) {
      throw new BadRequestException(
        'nationalIdSynthetic must be an exact 14-digit number.',
      );
    }

    const zone = await this.prisma.coverageZone.findUnique({
      where: { id: dto.primaryZoneId },
    });

    if (!zone || !zone.isActive) {
      throw new NotFoundException(
        `Active coverage zone "${dto.primaryZoneId}" was not found.`,
      );
    }

    if (dto.fullName?.trim()) {
      await this.prisma.user.update({
        where: { id: userId },
        data: { fullName: dto.fullName.trim() },
      });
    }

    const existing = await this.prisma.proProfile.findUnique({
      where: { userId },
    });

    const dossierCode =
      existing?.dossierCode ?? (await this.generateUniqueDossierCode());

    const profile = await this.prisma.proProfile.upsert({
      where: { userId },
      update: {
        nationalIdSynthetic: dto.nationalIdSynthetic.trim(),
        primaryZoneId: zone.id,
        transportMode: dto.transportMode,
        vehicleDescription: dto.vehicleDescription?.trim() || null,
        vehiclePlateAr: dto.vehiclePlateAr?.trim() || null,
        zonesLabelEn: existing?.zonesLabelEn || zone.nameEn,
        zonesLabelAr: existing?.zonesLabelAr || zone.nameAr,
      },
      create: {
        userId,
        dossierCode,
        nationalIdSynthetic: dto.nationalIdSynthetic.trim(),
        primaryZoneId: zone.id,
        transportMode: dto.transportMode,
        vehicleDescription: dto.vehicleDescription?.trim() || null,
        vehiclePlateAr: dto.vehiclePlateAr?.trim() || null,
        zonesLabelEn: zone.nameEn,
        zonesLabelAr: zone.nameAr,
        verificationStatus: ProVerificationStatus.DRAFT,
        coverageZones: {
          connect: [{ id: zone.id }],
        },
      },
      include: this.proProfileInclude,
    });

    return this.mapProProfile(profile);
  }

  /**
   * Screen 12 (Step 2 of 4): Primary Trade, Sub-Skills, Experience Tier,
   * Coverage Zones, Rate Card & Toolkit Commitment (`PUT /pro/onboarding/skills`).
   */
  async updateSkillsAndCoverage(userId: string, dto: ProSkillsUpdateDto) {
    const existing = await this.prisma.proProfile.findUnique({
      where: { userId },
    });

    if (!existing) {
      throw new BadRequestException(
        'Please complete Step 1 (Personal & Transport Details) before configuring skills.',
      );
    }

    if (!dto.toolkitCommitmentConfirmed) {
      throw new BadRequestException(
        'You must confirm ownership of a professional toolkit and safety gear.',
      );
    }

    const category = await this.prisma.serviceCategory.findUnique({
      where: { id: dto.primaryCategoryId },
    });

    if (!category || !category.isActive) {
      throw new NotFoundException(
        `Active service category "${dto.primaryCategoryId}" was not found.`,
      );
    }

    const uniqueZoneIds = Array.from(new Set(dto.coverageZoneIds));
    const zones = await this.prisma.coverageZone.findMany({
      where: { id: { in: uniqueZoneIds }, isActive: true },
    });

    if (zones.length !== uniqueZoneIds.length) {
      throw new BadRequestException(
        'One or more selected coverage zones are invalid or inactive.',
      );
    }

    await this.ensureSubSkillsSeeded();

    const uniqueSubSkillIds = Array.from(new Set(dto.subSkillIds ?? []));
    if (uniqueSubSkillIds.length > 0) {
      const validSubSkills = await this.prisma.serviceSubSkill.findMany({
        where: {
          id: { in: uniqueSubSkillIds },
          categoryId: category.id,
        },
      });

      if (validSubSkills.length !== uniqueSubSkillIds.length) {
        throw new BadRequestException(
          'One or more selected sub-skills do not belong to the chosen primary category.',
        );
      }
    }

    const zonesLabelEn = zones.map((z) => z.nameEn).join(' • ');
    const zonesLabelAr = zones.map((z) => z.nameAr).join(' • ');

    const updated = await this.prisma.proProfile.update({
      where: { userId },
      data: {
        primaryCategoryId: category.id,
        experienceTier: dto.experienceTier,
        acceptsStandardRateCard: dto.acceptsStandardRateCard,
        toolkitCommitmentConfirmed: dto.toolkitCommitmentConfirmed,
        specialtyEn:
          dto.specialtyEn?.trim() || `${category.nameEn} Specialist`,
        specialtyAr:
          dto.specialtyAr?.trim() || `أخصائي ${category.nameAr}`,
        estimatedPriceEgp:
          dto.estimatedPriceEgp ?? category.startingPriceEgp ?? 250,
        zonesLabelEn,
        zonesLabelAr,
        coverageZones: {
          set: uniqueZoneIds.map((id) => ({ id })),
        },
        subSkills: {
          set: uniqueSubSkillIds.map((id) => ({ id })),
        },
      },
      include: this.proProfileInclude,
    });

    return this.mapProProfile(updated);
  }

  /**
   * Screen 13 (Step 3 of 4): Private Verification Document Upload (`POST /pro/onboarding/documents`).
   * Validates file MIME type, size <= 2 MB, and binary magic bytes.
   * Stores document privately in `storageKey` so it is never publicly enumerable.
   */
  async uploadVerificationDocument(userId: string, dto: ProDocumentUploadDto) {
    const profile = await this.prisma.proProfile.findUnique({
      where: { userId },
    });

    if (!profile) {
      throw new BadRequestException(
        'Please complete Step 1 (Personal Details) before uploading verification documents.',
      );
    }

    const validated = validatePrivateUploadPayload({
      purpose: 'PRO_DOCUMENT',
      fileName: dto.fileName,
      mimeType: dto.mimeType,
      contentBase64: dto.contentBase64,
    });

    const privateStoragePayload = `prvdoc::${validated.sha256}::${validated.mimeType}::${validated.normalizedBase64}`;

    const existingDoc = await this.prisma.proVerificationDocument.findFirst({
      where: {
        proProfileId: profile.id,
        docType: dto.docType,
      },
    });

    const savedDoc = existingDoc
      ? await this.prisma.proVerificationDocument.update({
          where: { id: existingDoc.id },
          data: {
            storageKey: privateStoragePayload,
            fileName: validated.fileName,
            fileSizeBytes: validated.fileSizeBytes,
            status: DocumentStatus.PENDING,
            reviewerComment: null,
            uploadedAt: new Date(),
          },
        })
      : await this.prisma.proVerificationDocument.create({
          data: {
            proProfileId: profile.id,
            docType: dto.docType,
            storageKey: privateStoragePayload,
            fileName: validated.fileName,
            fileSizeBytes: validated.fileSizeBytes,
            status: DocumentStatus.PENDING,
          },
        });

    return this.mapDocumentSummary(savedDoc);
  }

  /**
   * Generates a short-lived authenticated access payload for a private verification document.
   * Strictly restricted to the owning user or an ADMIN reviewer.
   */
  async getVerificationDocumentAccess(
    userId: string,
    docId: string,
    isAdmin = false,
  ) {
    const doc = await this.prisma.proVerificationDocument.findUnique({
      where: { id: docId },
      include: {
        proProfile: {
          select: { userId: true },
        },
      },
    });

    if (!doc) {
      throw new NotFoundException(
        `Verification document "${docId}" was not found.`,
      );
    }

    if (!isAdmin && doc.proProfile.userId !== userId) {
      throw new ForbiddenException(
        'You do not have permission to access this private verification document.',
      );
    }

    let sha256 = 'unknown';
    let mimeType = 'image/png';
    let base64Content = '';
    if (doc.storageKey && doc.storageKey.startsWith('prvdoc::')) {
      const parts = doc.storageKey.split('::');
      sha256 = parts[1] || 'unknown';
      mimeType = parts[2] || 'image/png';
      base64Content = parts[3] || '';
    }

    const signed = signPrivateUploadAccessToken({
      ownerUserId: doc.proProfile.userId,
      purpose: 'PRO_DOCUMENT',
      sha256,
      mimeType: mimeType as any,
      fileName: doc.fileName,
    });

    return {
      ...this.mapDocumentSummary(doc),
      accessToken: signed.token,
      expiresAt: signed.expiresAt,
      privateDataUri: base64Content
        ? `data:${mimeType};base64,${base64Content}`
        : null,
    };
  }

  /**
   * Screen 13 -> Screen 14: Submits completed dossier for manual verification review (`POST /pro/onboarding/submit`).
   * Validates that Step 1, Step 2, and all 3 required documents are present, then transitions
   * `verificationStatus` from `DRAFT` / `ACTION_REQUIRED` to `PENDING_REVIEW`.
   */
  async submitForVerification(userId: string) {
    const profile = await this.prisma.proProfile.findUnique({
      where: { userId },
      include: this.proProfileInclude,
    });

    if (!profile) {
      throw new BadRequestException(
        'Professional profile has not been started yet.',
      );
    }

    if (!profile.nationalIdSynthetic || !profile.primaryZoneId) {
      throw new BadRequestException(
        'Step 1 (Personal & Transport Details) is incomplete.',
      );
    }

    if (
      !profile.primaryCategoryId ||
      profile.coverageZones.length === 0 ||
      !profile.toolkitCommitmentConfirmed
    ) {
      throw new BadRequestException(
        'Step 2 (Services, Skills & Coverage Zones) is incomplete.',
      );
    }

    const uploadedDocTypes = new Set(profile.documents.map((d) => d.docType));
    const missingDocs = REQUIRED_PRO_DOC_TYPES.filter(
      (reqType) => !uploadedDocTypes.has(reqType),
    );

    if (missingDocs.length > 0) {
      throw new BadRequestException(
        `Missing required verification documents: ${missingDocs.join(', ')}.`,
      );
    }

    if (profile.verificationStatus === ProVerificationStatus.APPROVED) {
      return this.getVerificationStatus(userId);
    }

    if (profile.verificationStatus === ProVerificationStatus.SUSPENDED) {
      throw new ForbiddenException(
        'Suspended professional profiles cannot be resubmitted without administrator intervention.',
      );
    }

    await this.prisma.proProfile.update({
      where: { id: profile.id },
      data: {
        verificationStatus: ProVerificationStatus.PENDING_REVIEW,
      },
    });

    return this.getVerificationStatus(userId);
  }

  /**
   * Screen 14: Verification Status (`GET /pro/onboarding/status`).
   * Returns real verification status, dossier summary, uploaded document statuses,
   * reviewer note, and 4 vetting milestone steps.
   */
  async getVerificationStatus(userId: string) {
    const profile = await this.prisma.proProfile.findUnique({
      where: { userId },
      include: this.proProfileInclude,
    });

    if (!profile) {
      throw new NotFoundException(
        'No professional profile found for this account.',
      );
    }

    const mapped = this.mapProProfile(profile);
    const status = profile.verificationStatus;

    const milestones = [
      {
        key: 'ACCOUNT_AND_SKILLS',
        titleEn: 'Account & Trade Skills Configured',
        titleAr: 'إعداد الحساب والمهارات الفنية',
        subtitleEn:
          mapped.step1Complete && mapped.step2Complete
            ? `${profile.primaryCategory?.nameEn ?? 'Trade'} • ${profile.coverageZones.length} coverage zone(s)`
            : 'Complete personal details and trade skills',
        subtitleAr:
          mapped.step1Complete && mapped.step2Complete
            ? `${profile.primaryCategory?.nameAr ?? 'التخصص'} • ${profile.coverageZones.length} مناطق تغطية`
            : 'أكمل البيانات الشخصية والمهارات الفنية',
        state:
          mapped.step1Complete && mapped.step2Complete
            ? 'COMPLETED'
            : 'CURRENT',
      },
      {
        key: 'DOCUMENT_UPLOAD',
        titleEn: 'Synthetic Identity & Record Specimens',
        titleAr: 'رفع نماذج الهوية والفيش الجنائي',
        subtitleEn: mapped.step3Complete
          ? `${profile.documents.length} private document(s) uploaded`
          : 'Upload required National ID (Front/Back) and Criminal Record',
        subtitleAr: mapped.step3Complete
          ? `تم رفع ${profile.documents.length} مستندات خاصة`
          : 'يرجى رفع البطاقة (وجه/ظهر) والفيش الجنائي',
        state: mapped.step3Complete
          ? 'COMPLETED'
          : mapped.step1Complete && mapped.step2Complete
            ? 'CURRENT'
            : 'UPCOMING',
      },
      {
        key: 'BACKGROUND_AND_LICENSE_VETTING',
        titleEn: 'Manual Compliance & Dossier Review',
        titleAr: 'المراجعة اليدوية للمستندات والاعتماد',
        subtitleEn:
          status === ProVerificationStatus.APPROVED
            ? 'Approved by FIXO Operations Reviewer'
            : status === ProVerificationStatus.ACTION_REQUIRED
              ? profile.reviewerNote ||
                'Action required: please re-upload clear documents'
              : status === ProVerificationStatus.PENDING_REVIEW
                ? 'Under manual review by FIXO Vetting Team (1–2 business days)'
                : 'Submit your dossier to begin manual vetting',
        subtitleAr:
          status === ProVerificationStatus.APPROVED
            ? 'تم الاعتماد بواسطة فريق مراجعة فيكسو'
            : status === ProVerificationStatus.ACTION_REQUIRED
              ? profile.reviewerNote ||
                'مطلوب إجراء: يرجى إعادة رفع المستندات بوضوح'
              : status === ProVerificationStatus.PENDING_REVIEW
                ? 'قيد المراجعة اليدوية من فريق فيكسو (١–٢ يوم عمل)'
                : 'أرسل الملف لبدء المراجعة اليدوية',
        state:
          status === ProVerificationStatus.APPROVED
            ? 'COMPLETED'
            : status === ProVerificationStatus.ACTION_REQUIRED
              ? 'ACTION_REQUIRED'
              : status === ProVerificationStatus.PENDING_REVIEW
                ? 'CURRENT'
                : 'UPCOMING',
      },
      {
        key: 'PRO_ACCOUNT_ACTIVATION',
        titleEn: 'Pro Dispatch Activation',
        titleAr: 'تفعيل حساب الفني واستقبال الطلبات',
        subtitleEn:
          status === ProVerificationStatus.APPROVED
            ? 'Your Pro account is active — you can go online on the Pro Dashboard'
            : 'Unlocks automatically once an authorized reviewer approves your dossier',
        subtitleAr:
          status === ProVerificationStatus.APPROVED
            ? 'حسابك مفعل الآن — يمكنك الاتصال واستقبال الطلبات من لوحة التحكم'
            : 'يتم التفعيل تلقائياً فور اعتماد ملفك من المراجع المختص',
        state:
          status === ProVerificationStatus.APPROVED ? 'COMPLETED' : 'UPCOMING',
      },
    ];

    return {
      profile: mapped,
      verificationStatus: status,
      dossierCode: profile.dossierCode,
      reviewerNote: profile.reviewerNote ?? null,
      updatedAt:
        profile.updatedAt instanceof Date
          ? profile.updatedAt.toISOString()
          : String(profile.updatedAt),
      milestones,
    };
  }

  /**
   * Authorized Reviewer Endpoint (`PATCH /pro/admin/profiles/:proProfileId/review`).
   * Strictly requires `UserRole.ADMIN`. Never callable by a customer or pro to self-approve.
   */
  async adminReviewProProfile(
    adminUserId: string,
    adminRole: UserRole,
    proProfileId: string,
    dto: ProAdminReviewDto,
  ) {
    if (adminRole !== UserRole.ADMIN) {
      throw new ForbiddenException(
        'Only an authorized ADMIN reviewer can approve or update professional verification status.',
      );
    }

    const profile = await this.prisma.proProfile.findUnique({
      where: { id: proProfileId },
      include: { documents: true },
    });

    if (!profile) {
      throw new NotFoundException(
        `Professional profile "${proProfileId}" was not found.`,
      );
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      if (dto.documentDecisions && dto.documentDecisions.length > 0) {
        for (const decision of dto.documentDecisions) {
          await tx.proVerificationDocument.updateMany({
            where: {
              proProfileId: profile.id,
              docType: decision.docType,
            },
            data: {
              status: decision.status as DocumentStatus,
              reviewerComment:
                decision.status === 'REJECTED'
                  ? decision.rejectionReason?.trim() ||
                    'Document rejected by reviewer'
                  : null,
            },
          });
        }
      } else if (dto.status === 'APPROVED') {
        await tx.proVerificationDocument.updateMany({
          where: { proProfileId: profile.id },
          data: {
            status: DocumentStatus.VERIFIED,
            reviewerComment: null,
          },
        });
      }

      const nextProfile = await tx.proProfile.update({
        where: { id: profile.id },
        data: {
          verificationStatus: dto.status as ProVerificationStatus,
          reviewerNote:
            dto.reviewerNote?.trim() ||
            `Reviewed by admin ${adminUserId}`,
          ...(dto.status !== 'APPROVED' ? { isOnline: false } : {}),
        },
        include: this.proProfileInclude,
      });

      if (dto.status === 'APPROVED') {
        await tx.user.update({
          where: { id: profile.userId },
          data: { role: UserRole.PRO },
        });
      }

      return nextProfile;
    });

    return this.mapProProfile(updated);
  }

  /**
   * Screen 15: Toggles online/offline availability (`PATCH /pro/availability`).
   * Strictly restricted to `APPROVED` professionals.
   */
  async updateAvailability(userId: string, dto: ProAvailabilityDto) {
    const profile = await this.prisma.proProfile.findUnique({
      where: { userId },
      include: this.proProfileInclude,
    });

    if (!profile) {
      throw new NotFoundException('Professional profile was not found.');
    }

    if (profile.verificationStatus !== ProVerificationStatus.APPROVED) {
      throw new ForbiddenException(
        `Only APPROVED professionals can go online for dispatch (current status: "${profile.verificationStatus}").`,
      );
    }

    const updated = await this.prisma.proProfile.update({
      where: { id: profile.id },
      data: { isOnline: dto.isOnline },
      include: this.proProfileInclude,
    });

    if (dto.isOnline) {
      await this.syncPendingOffersForPro(updated);
    }

    return this.mapProProfile(updated);
  }

  /**
   * Screen 15: Pro Dashboard (`GET /pro/dashboard`).
   * Computes actual net earnings, 7-day weekly trajectory, active job offers,
   * and today's confirmed/active schedule from real database records.
   */
  async getDashboard(userId: string) {
    const profile = await this.prisma.proProfile.findUnique({
      where: { userId },
      include: this.proProfileInclude,
    });

    if (!profile) {
      throw new NotFoundException('Professional profile was not found.');
    }

    const now = new Date();

    // 1. Expire any stale PENDING offers past their expiresAt timestamp
    if (this.prisma.jobOffer) {
      await this.prisma.jobOffer.updateMany({
        where: {
          proProfileId: profile.id,
          status: JobOfferStatus.PENDING,
          expiresAt: { lte: now },
        },
        data: {
          status: JobOfferStatus.EXPIRED,
          respondedAt: now,
        },
      });
    }

    // 2. If APPROVED and online, ensure offers exist for eligible unassigned bookings
    if (
      profile.verificationStatus === ProVerificationStatus.APPROVED &&
      profile.isOnline
    ) {
      await this.syncPendingOffersForPro(profile);
    }

    // 3. Query active PENDING offers, active assigned jobs, and completed bookings
    const [activeOffersRaw, activeJobsRaw, completedJobsRaw] =
      await Promise.all([
        this.prisma.jobOffer.findMany({
          where: {
            proProfileId: profile.id,
            status: JobOfferStatus.PENDING,
            expiresAt: { gt: now },
          },
          include: {
            booking: {
              include: {
                offering: { include: { category: true } },
                address: { include: { zone: true } },
                customer: {
                  select: { id: true, fullName: true, rewardPoints: true },
                },
              },
            },
          },
          orderBy: { createdAt: 'desc' },
        }),
        this.prisma.booking.findMany({
          where: {
            proProfileId: profile.id,
            status: {
              in: [
                BookingStatus.CONFIRMED,
                BookingStatus.PRO_EN_ROUTE,
                BookingStatus.ARRIVED,
                BookingStatus.IN_PROGRESS,
              ],
            },
          },
          include: {
            offering: { include: { category: true } },
            address: { include: { zone: true } },
            customer: {
              select: { id: true, fullName: true, phone: true },
            },
            payment: true,
          },
          orderBy: { scheduledDate: 'asc' },
        }),
        this.prisma.booking.findMany({
          where: {
            proProfileId: profile.id,
            status: BookingStatus.COMPLETED,
          },
          include: {
            offering: { include: { category: true } },
            address: { include: { zone: true } },
            customer: { select: { id: true, fullName: true } },
            payment: true,
            review: true,
          },
          orderBy: { completedAt: 'desc' },
          take: 50,
        }),
      ]);

    // 4. Compute actual Today & 7-Day Net Earnings from COMPLETED bookings
    const todayStart = new Date(now);
    todayStart.setUTCHours(0, 0, 0, 0);

    const sevenDaysAgo = new Date(todayStart);
    sevenDaysAgo.setUTCDate(sevenDaysAgo.getUTCDate() - 6);

    let todayNetEarningsEgp = 0;
    let todayCompletedCount = 0;
    let weeklyNetEarningsEgp = 0;
    let weeklyCompletedCount = 0;

    const dayBuckets = new Map<
      string,
      {
        date: string;
        dayLabelEn: string;
        dayLabelAr: string;
        netEarningsEgp: number;
        jobsCount: number;
      }
    >();

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

    for (let i = 0; i < 7; i++) {
      const d = new Date(sevenDaysAgo);
      d.setUTCDate(d.getUTCDate() + i);
      const dateKey = d.toISOString().split('T')[0];
      const dayOfWeek = d.getUTCDay();
      dayBuckets.set(dateKey, {
        date: dateKey,
        dayLabelEn: enDays[dayOfWeek],
        dayLabelAr: arDays[dayOfWeek],
        netEarningsEgp: 0,
        jobsCount: 0,
      });
    }

    for (const job of completedJobsRaw) {
      const completedDate = job.completedAt ?? job.updatedAt;
      const tipEgp = job.payment?.tipEgp ?? job.review?.tipAmountEgp ?? 0;
      const netEgp = job.netArtisanEgp + tipEgp;

      if (completedDate >= todayStart) {
        todayNetEarningsEgp += netEgp;
        todayCompletedCount += 1;
      }

      if (completedDate >= sevenDaysAgo) {
        weeklyNetEarningsEgp += netEgp;
        weeklyCompletedCount += 1;
        const dateKey = completedDate.toISOString().split('T')[0];
        const bucket = dayBuckets.get(dateKey);
        if (bucket) {
          bucket.netEarningsEgp += netEgp;
          bucket.jobsCount += 1;
        }
      }
    }

    return {
      profile: this.mapProProfile(profile),
      earningsSummary: {
        todayNetEarningsEgp,
        todayCompletedCount,
        weeklyNetEarningsEgp,
        weeklyCompletedCount,
        totalCompletedJobsCount: profile.completedJobsCount,
        acceptanceRatePct: profile.acceptanceRatePct,
        ratingAvg: profile.ratingAvg,
        reviewsCount: profile.reviewsCount,
        currency: 'EGP',
      },
      weeklyTrajectory: Array.from(dayBuckets.values()),
      activeOffers: activeOffersRaw.map((offer) =>
        this.mapJobOfferDetail(offer),
      ),
      activeJobs: activeJobsRaw.map((job) => this.mapProJobSummary(job)),
      recentCompletedJobs: completedJobsRaw
        .slice(0, 10)
        .map((job) => this.mapProJobSummary(job)),
    };
  }

  /**
   * Screen 16: Incoming Job Request Detail (`GET /pro/job-offers/:offerId`).
   */
  async getJobOfferById(userId: string, offerId: string) {
    const profile = await this.prisma.proProfile.findUnique({
      where: { userId },
    });

    if (!profile) {
      throw new NotFoundException('Professional profile was not found.');
    }

    const offer = await this.prisma.jobOffer.findUnique({
      where: { id: offerId },
      include: {
        booking: {
          include: {
            offering: { include: { category: true } },
            address: { include: { zone: true } },
            customer: {
              select: { id: true, fullName: true, rewardPoints: true },
            },
          },
        },
      },
    });

    if (!offer) {
      throw new NotFoundException(`Job offer "${offerId}" was not found.`);
    }

    if (offer.proProfileId !== profile.id) {
      throw new ForbiddenException('You do not have access to this job offer.');
    }

    if (
      offer.status === JobOfferStatus.PENDING &&
      offer.expiresAt <= new Date()
    ) {
      const expired = await this.prisma.jobOffer.update({
        where: { id: offer.id },
        data: {
          status: JobOfferStatus.EXPIRED,
          respondedAt: new Date(),
        },
        include: {
          booking: {
            include: {
              offering: { include: { category: true } },
              address: { include: { zone: true } },
              customer: {
                select: { id: true, fullName: true, rewardPoints: true },
              },
            },
          },
        },
      });
      return this.mapJobOfferDetail(expired);
    }

    return this.mapJobOfferDetail(offer);
  }

  /**
   * Screen 16: Atomic Job Offer Acceptance (`POST /pro/job-offers/:offerId/accept`).
   */
  async acceptJobOffer(userId: string, offerId: string) {
    const profile = await this.prisma.proProfile.findUnique({
      where: { userId },
    });

    if (!profile) {
      throw new NotFoundException('Professional profile was not found.');
    }

    if (profile.verificationStatus !== ProVerificationStatus.APPROVED) {
      throw new ForbiddenException(
        'Only APPROVED professionals can accept job offers.',
      );
    }

    const result = await this.prisma.$transaction(async (tx) => {
      if (this.prisma.isDatabaseConnected()) {
        await tx.$queryRaw`
          SELECT id, status::text
          FROM "JobOffer"
          WHERE id = ${offerId}
          FOR UPDATE;
        `;
      }

      const offer = await tx.jobOffer.findUnique({
        where: { id: offerId },
      });

      if (!offer) {
        throw new NotFoundException(`Job offer "${offerId}" was not found.`);
      }

      if (offer.proProfileId !== profile.id) {
        throw new ForbiddenException('You do not own this job offer.');
      }

      const now = new Date();
      if (offer.expiresAt <= now) {
        if (offer.status === JobOfferStatus.PENDING) {
          await tx.jobOffer.update({
            where: { id: offer.id },
            data: { status: JobOfferStatus.EXPIRED, respondedAt: now },
          });
        }
        throw new BadRequestException('This job offer has expired.');
      }

      if (offer.status !== JobOfferStatus.PENDING) {
        throw new ConflictException(
          `Job offer is no longer pending (current status: "${offer.status}").`,
        );
      }

      if (this.prisma.isDatabaseConnected()) {
        await tx.$queryRaw`
          SELECT id, status::text, "proProfileId"
          FROM "Booking"
          WHERE id = ${offer.bookingId}
          FOR UPDATE;
        `;
      }

      const booking = await tx.booking.findUnique({
        where: { id: offer.bookingId },
      });

      if (!booking) {
        throw new NotFoundException('Associated booking was not found.');
      }

      if (
        booking.status !== BookingStatus.PENDING_DISPATCH &&
        booking.status !== BookingStatus.OFFERED_TO_PRO
      ) {
        throw new ConflictException(
          'This booking has already been accepted or is no longer available.',
        );
      }

      if (booking.proProfileId && booking.proProfileId !== profile.id) {
        throw new ConflictException(
          'Another professional has already been assigned to this booking.',
        );
      }

      // 1. Mark this offer ACCEPTED
      await tx.jobOffer.update({
        where: { id: offer.id },
        data: {
          status: JobOfferStatus.ACCEPTED,
          respondedAt: now,
        },
      });

      // 2. Expire all other pending offers for the same booking
      await tx.jobOffer.updateMany({
        where: {
          bookingId: booking.id,
          id: { not: offer.id },
          status: JobOfferStatus.PENDING,
        },
        data: {
          status: JobOfferStatus.EXPIRED,
          respondedAt: now,
        },
      });

      // 3. Assign pro and transition booking to CONFIRMED
      const updatedBooking = await tx.booking.update({
        where: { id: booking.id },
        data: {
          proProfileId: profile.id,
          status: BookingStatus.CONFIRMED,
        },
        include: {
          offering: { include: { category: true } },
          address: { include: { zone: true } },
          customer: { select: { id: true, fullName: true, phone: true } },
          payment: true,
        },
      });

      // 4. Record BookingStatusEvent
      await tx.bookingStatusEvent.create({
        data: {
          bookingId: booking.id,
          fromStatus: booking.status,
          toStatus: BookingStatus.CONFIRMED,
          actorUserId: userId,
          note: `Accepted by verified professional (${profile.dossierCode})`,
        },
      });

      // 5. Recalculate acceptanceRatePct
      await this.recalculateAcceptanceRate(tx, profile.id);

      return updatedBooking;
    });

    if (this.pushService) {
      await this.pushService.notify(result.customerId, result.id);
    }

    return this.mapProJobSummary(result);
  }

  /**
   * Screen 16: Decline Job Offer (`POST /pro/job-offers/:offerId/decline`).
   */
  async declineJobOffer(
    userId: string,
    offerId: string,
    dto: ProDeclineOfferDto,
  ) {
    const profile = await this.prisma.proProfile.findUnique({
      where: { userId },
    });

    if (!profile) {
      throw new NotFoundException('Professional profile was not found.');
    }

    const updatedOffer = await this.prisma.$transaction(async (tx) => {
      const offer = await tx.jobOffer.findUnique({
        where: { id: offerId },
      });

      if (!offer) {
        throw new NotFoundException(`Job offer "${offerId}" was not found.`);
      }

      if (offer.proProfileId !== profile.id) {
        throw new ForbiddenException('You do not own this job offer.');
      }

      if (offer.status !== JobOfferStatus.PENDING) {
        throw new BadRequestException(
          `Cannot decline job offer in status "${offer.status}".`,
        );
      }

      const declined = await tx.jobOffer.update({
        where: { id: offer.id },
        data: {
          status: JobOfferStatus.DECLINED,
          declineReason: dto.reason?.trim() || 'Declined by professional',
          respondedAt: new Date(),
        },
        include: {
          booking: {
            include: {
              offering: { include: { category: true } },
              address: { include: { zone: true } },
              customer: {
                select: { id: true, fullName: true, rewardPoints: true },
              },
            },
          },
        },
      });

      await this.recalculateAcceptanceRate(tx, profile.id);

      return declined;
    });

    return this.mapJobOfferDetail(updatedOffer);
  }

  /**
   * Screen 15: Advances an assigned booking through the professional execution workflow:
   * - `CONFIRMED` -> `PRO_EN_ROUTE`
   * - `PRO_EN_ROUTE` -> `ARRIVED`
   * - `ARRIVED` -> `IN_PROGRESS` (requires valid 4-digit customer `arrivalPinCode` with max 5 attempts)
   * - `IN_PROGRESS` -> `COMPLETED` (marks `CASH_ON_SERVICE` payment `PAID` and increments `completedJobsCount`)
   */
  async advanceBookingStatus(
    userId: string,
    bookingId: string,
    dto: ProAdvanceJobStatusDto,
  ) {
    const profile = await this.prisma.proProfile.findUnique({
      where: { userId },
    });

    if (!profile) {
      throw new NotFoundException('Professional profile was not found.');
    }

    if (profile.verificationStatus !== ProVerificationStatus.APPROVED) {
      throw new ForbiddenException(
        'Only APPROVED professionals can update assigned job status.',
      );
    }

    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: { payment: true },
    });

    if (!booking) {
      throw new NotFoundException(`Booking "${bookingId}" was not found.`);
    }

    if (booking.proProfileId !== profile.id) {
      throw new ForbiddenException(
        'You are not the assigned professional for this booking.',
      );
    }

    const expectedFromStatus: Record<
      ProAdvanceJobStatusDto['toStatus'],
      BookingStatus
    > = {
      PRO_EN_ROUTE: BookingStatus.CONFIRMED,
      ARRIVED: BookingStatus.PRO_EN_ROUTE,
      IN_PROGRESS: BookingStatus.ARRIVED,
      COMPLETED: BookingStatus.IN_PROGRESS,
    };

    const requiredCurrent = expectedFromStatus[dto.toStatus];
    if (booking.status !== requiredCurrent) {
      throw new BadRequestException(
        `Invalid status transition from "${booking.status}" to "${dto.toStatus}". Expected current status "${requiredCurrent}".`,
      );
    }

    // Arrival PIN verification with bounded attempts (max 5) when transitioning ARRIVED -> IN_PROGRESS
    if (dto.toStatus === BookingStatus.IN_PROGRESS) {
      const failedAttempts = await this.prisma.bookingStatusEvent.count({
        where: {
          bookingId: booking.id,
          note: INTERNAL_FAILED_PIN_EVENT_NOTE,
        },
      });

      if (failedAttempts >= MAX_ARRIVAL_PIN_ATTEMPTS) {
        throw new ForbiddenException(
          `Maximum arrival PIN verification attempts (${MAX_ARRIVAL_PIN_ATTEMPTS}) exceeded for this booking.`,
        );
      }

      if (
        !dto.arrivalPinCode ||
        dto.arrivalPinCode.trim() !== booking.arrivalPinCode
      ) {
        await this.prisma.bookingStatusEvent.create({
          data: {
            bookingId: booking.id,
            fromStatus: BookingStatus.ARRIVED,
            toStatus: BookingStatus.ARRIVED,
            actorUserId: userId,
            note: INTERNAL_FAILED_PIN_EVENT_NOTE,
          },
        });

        const remainingAttempts = Math.max(
          0,
          MAX_ARRIVAL_PIN_ATTEMPTS - (failedAttempts + 1),
        );
        throw new BadRequestException(
          `Invalid 4-digit Arrival PIN code. ${remainingAttempts} attempt(s) remaining.`,
        );
      }
    }

    const now = new Date();
    const defaultNotes: Record<ProAdvanceJobStatusDto['toStatus'], string> = {
      PRO_EN_ROUTE: 'Professional departed toward customer location',
      ARRIVED: 'Professional arrived at customer address',
      IN_PROGRESS: 'Customer 4-digit Arrival PIN verified — service started',
      COMPLETED: 'Service completed and cash settlement confirmed',
    };

    const updated = await this.prisma.$transaction(async (tx) => {
      const nextBooking = await tx.booking.update({
        where: { id: booking.id },
        data: {
          status: dto.toStatus as BookingStatus,
          ...(dto.toStatus === BookingStatus.COMPLETED
            ? { completedAt: now }
            : {}),
        },
        include: {
          offering: { include: { category: true } },
          address: { include: { zone: true } },
          customer: { select: { id: true, fullName: true, phone: true } },
          payment: true,
        },
      });

      if (dto.toStatus === BookingStatus.COMPLETED) {
        if (
          booking.payment &&
          booking.payment.method === PaymentMethodType.CASH_ON_SERVICE &&
          booking.payment.status !== PaymentStatus.PAID
        ) {
          await tx.paymentRecord.update({
            where: { id: booking.payment.id },
            data: {
              status: PaymentStatus.PAID,
              paidAt: now,
            },
          });
        }

        await tx.proProfile.update({
          where: { id: profile.id },
          data: {
            completedJobsCount: { increment: 1 },
          },
        });
      }

      await tx.bookingStatusEvent.create({
        data: {
          bookingId: booking.id,
          fromStatus: booking.status,
          toStatus: dto.toStatus as BookingStatus,
          actorUserId: userId,
          note: dto.note?.trim() || defaultNotes[dto.toStatus],
        },
      });

      return nextBooking;
    });

    if (this.pushService) {
      await this.pushService.notify(updated.customerId, updated.id);
    }

    return this.mapProJobSummary(updated);
  }

  private async syncPendingOffersForPro(profile: any): Promise<void> {
    if (!this.prisma.isDatabaseConnected() || !profile.primaryCategoryId) {
      return;
    }

    const coveredZoneIds = new Set<string>();
    if (profile.primaryZoneId) {
      coveredZoneIds.add(profile.primaryZoneId);
    }
    if (Array.isArray(profile.coverageZones)) {
      for (const z of profile.coverageZones) {
        if (z?.id) coveredZoneIds.add(z.id);
      }
    }

    if (coveredZoneIds.size === 0) {
      return;
    }

    const waitingBookings = await this.prisma.booking.findMany({
      where: {
        status: {
          in: [BookingStatus.PENDING_DISPATCH, BookingStatus.OFFERED_TO_PRO],
        },
        proProfileId: null,
        customerId: { not: profile.userId },
        offering: {
          categoryId: profile.primaryCategoryId,
        },
        address: {
          zoneId: { in: Array.from(coveredZoneIds) },
        },
      },
      take: 10,
    });

    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);
    for (const bk of waitingBookings) {
      const existingOffer = await this.prisma.jobOffer.findFirst({
        where: {
          bookingId: bk.id,
          proProfileId: profile.id,
        },
      });

      if (!existingOffer) {
        await this.prisma.jobOffer.create({
          data: {
            bookingId: bk.id,
            proProfileId: profile.id,
            status: JobOfferStatus.PENDING,
            expiresAt,
          },
        });
      } else if (
        existingOffer.status === JobOfferStatus.EXPIRED &&
        bk.status === BookingStatus.PENDING_DISPATCH
      ) {
        await this.prisma.jobOffer.update({
          where: { id: existingOffer.id },
          data: {
            status: JobOfferStatus.PENDING,
            expiresAt,
            respondedAt: null,
          },
        });
      }
    }
  }

  private async recalculateAcceptanceRate(
    tx: any,
    proProfileId: string,
  ): Promise<void> {
    if (!tx.jobOffer?.count || !tx.proProfile?.update) {
      return;
    }

    const [acceptedCount, declinedCount] = await Promise.all([
      tx.jobOffer.count({
        where: { proProfileId, status: JobOfferStatus.ACCEPTED },
      }),
      tx.jobOffer.count({
        where: { proProfileId, status: JobOfferStatus.DECLINED },
      }),
    ]);

    const totalDecided = acceptedCount + declinedCount;
    const acceptanceRatePct =
      totalDecided > 0 ? Math.round((acceptedCount / totalDecided) * 100) : 100;

    await tx.proProfile.update({
      where: { id: proProfileId },
      data: { acceptanceRatePct },
    });
  }

  private async ensureSubSkillsSeeded(): Promise<void> {
    if (!this.prisma.isDatabaseConnected() || !this.prisma.serviceSubSkill) {
      return;
    }

    const count = await this.prisma.serviceSubSkill.count();
    if (count >= EGYPT_SERVICE_SUB_SKILLS.length) {
      return;
    }

    for (const sub of EGYPT_SERVICE_SUB_SKILLS) {
      const category = await this.prisma.serviceCategory.findUnique({
        where: { slug: sub.categorySlug },
        select: { id: true },
      });
      if (category) {
        await this.prisma.serviceSubSkill.upsert({
          where: { slug: sub.slug },
          update: {
            categoryId: category.id,
            nameEn: sub.nameEn,
            nameAr: sub.nameAr,
          },
          create: {
            id: sub.id,
            categoryId: category.id,
            slug: sub.slug,
            nameEn: sub.nameEn,
            nameAr: sub.nameAr,
          },
        });
      }
    }
  }

  private async generateUniqueDossierCode(): Promise<string> {
    for (let i = 0; i < 5; i++) {
      const num = Math.floor(1000 + Math.random() * 9000);
      const code = `FX-PRO-${num}`;
      const existing = await this.prisma.proProfile.findUnique({
        where: { dossierCode: code },
        select: { id: true },
      });
      if (!existing) {
        return code;
      }
    }
    return `FX-PRO-${Date.now().toString().slice(-4)}`;
  }

  private mapDocumentSummary(doc: any) {
    let mimeType = 'image/png';
    const hasPrivateContent = Boolean(
      doc.storageKey && doc.storageKey.startsWith('prvdoc::'),
    );
    if (hasPrivateContent) {
      const parts = doc.storageKey.split('::');
      mimeType = parts[2] || 'image/png';
    }

    return {
      id: doc.id,
      proProfileId: doc.proProfileId,
      docType: doc.docType,
      fileName: doc.fileName,
      fileSizeBytes: doc.fileSizeBytes,
      mimeType,
      status: doc.status,
      rejectionReason: doc.reviewerComment ?? null,
      hasPrivateContent,
      uploadedAt:
        doc.uploadedAt instanceof Date
          ? doc.uploadedAt.toISOString()
          : String(doc.uploadedAt),
    };
  }

  private mapProProfile(profile: any) {
    const docs = Array.isArray(profile.documents)
      ? profile.documents.map((d: any) => this.mapDocumentSummary(d))
      : [];

    const uploadedDocTypes = new Set(docs.map((d: any) => d.docType));
    const step1Complete = Boolean(
      profile.nationalIdSynthetic && profile.primaryZoneId,
    );
    const step2Complete = Boolean(
      profile.primaryCategoryId &&
        Array.isArray(profile.coverageZones) &&
        profile.coverageZones.length > 0 &&
        profile.toolkitCommitmentConfirmed,
    );
    const step3Complete = REQUIRED_PRO_DOC_TYPES.every((req) =>
      uploadedDocTypes.has(req),
    );

    return {
      id: profile.id,
      userId: profile.userId,
      dossierCode: profile.dossierCode,
      nationalIdSynthetic: profile.nationalIdSynthetic,
      primaryCategoryId: profile.primaryCategoryId ?? null,
      primaryZoneId: profile.primaryZoneId ?? null,
      specialtyEn: profile.specialtyEn ?? null,
      specialtyAr: profile.specialtyAr ?? null,
      zonesLabelEn: profile.zonesLabelEn ?? null,
      zonesLabelAr: profile.zonesLabelAr ?? null,
      estimatedPriceEgp: profile.estimatedPriceEgp ?? 250,
      transportMode: profile.transportMode,
      vehicleDescription: profile.vehicleDescription ?? null,
      vehiclePlateAr: profile.vehiclePlateAr ?? null,
      experienceTier: profile.experienceTier,
      acceptsStandardRateCard: profile.acceptsStandardRateCard,
      toolkitCommitmentConfirmed: profile.toolkitCommitmentConfirmed,
      verificationStatus: profile.verificationStatus,
      isOnline: profile.isOnline,
      ratingAvg: profile.ratingAvg,
      reviewsCount: profile.reviewsCount,
      completedJobsCount: profile.completedJobsCount,
      acceptanceRatePct: profile.acceptanceRatePct,
      reviewerNote: profile.reviewerNote ?? null,
      updatedAt:
        profile.updatedAt instanceof Date
          ? profile.updatedAt.toISOString()
          : String(profile.updatedAt),
      user: profile.user ?? null,
      primaryCategory: profile.primaryCategory ?? null,
      primaryZone: profile.primaryZone ?? null,
      coverageZones: profile.coverageZones ?? [],
      subSkills: profile.subSkills ?? [],
      documents: docs,
      step1Complete,
      step2Complete,
      step3Complete,
      canSubmit: step1Complete && step2Complete && step3Complete,
    };
  }

  private mapJobOfferDetail(offer: any) {
    const nowMs = Date.now();
    const expiresMs =
      offer.expiresAt instanceof Date
        ? offer.expiresAt.getTime()
        : new Date(offer.expiresAt).getTime();
    const remainingSeconds = Math.max(0, Math.floor((expiresMs - nowMs) / 1000));
    const bk = offer.booking;

    return {
      id: offer.id,
      bookingId: offer.bookingId,
      proProfileId: offer.proProfileId,
      status: offer.status,
      declineReason: offer.declineReason ?? null,
      offeredAt:
        offer.createdAt instanceof Date
          ? offer.createdAt.toISOString()
          : String(offer.createdAt),
      expiresAt:
        offer.expiresAt instanceof Date
          ? offer.expiresAt.toISOString()
          : String(offer.expiresAt),
      remainingSeconds,
      booking: bk
        ? {
            id: bk.id,
            orderCode: bk.orderCode,
            status: bk.status,
            scheduledDate:
              bk.scheduledDate instanceof Date
                ? bk.scheduledDate.toISOString()
                : String(bk.scheduledDate),
            timeWindow: bk.timeWindow,
            issueDescription: bk.issueDescription ?? null,
            issuePhotoUrls: bk.issuePhotoUrls ?? [],
            pricing: {
              baseInspectionEgp: bk.baseInspectionEgp,
              serviceFeeEgp: bk.serviceFeeEgp,
              transportFeeEgp: bk.transportFeeEgp,
              totalEgp: bk.totalEgp,
              platformFeeEgp: bk.platformFeeEgp,
              netArtisanEgp: bk.netArtisanEgp,
              currency: 'EGP',
            },
            offering: bk.offering
              ? {
                  id: bk.offering.id,
                  slug: bk.offering.slug,
                  titleEn: bk.offering.titleEn,
                  titleAr: bk.offering.titleAr,
                  estimatedDurationMins: bk.offering.estimatedDurationMins,
                  category: bk.offering.category
                    ? {
                        id: bk.offering.category.id,
                        slug: bk.offering.category.slug,
                        nameEn: bk.offering.category.nameEn,
                        nameAr: bk.offering.category.nameAr,
                      }
                    : null,
                }
              : null,
            address: bk.address
              ? {
                  id: bk.address.id,
                  label: bk.address.label,
                  buildingLine: bk.address.buildingLine,
                  districtLine: bk.address.districtLine,
                  gateNotes: bk.address.gateNotes ?? null,
                  latitude: bk.address.latitude ?? null,
                  longitude: bk.address.longitude ?? null,
                  zone: bk.address.zone ?? null,
                }
              : null,
            customer: bk.customer
              ? {
                  id: bk.customer.id,
                  fullName: bk.customer.fullName ?? 'FIXO Customer',
                  rewardPoints: bk.customer.rewardPoints ?? 0,
                }
              : null,
          }
        : null,
    };
  }

  private mapProJobSummary(booking: any) {
    const tipEgp =
      booking.payment?.tipEgp ?? booking.review?.tipAmountEgp ?? 0;

    return {
      id: booking.id,
      orderCode: booking.orderCode,
      customerId: booking.customerId,
      proProfileId: booking.proProfileId,
      status: booking.status,
      scheduledDate:
        booking.scheduledDate instanceof Date
          ? booking.scheduledDate.toISOString()
          : String(booking.scheduledDate),
      timeWindow: booking.timeWindow,
      issueDescription: booking.issueDescription ?? null,
      issuePhotoUrls: booking.issuePhotoUrls ?? [],
      // Security: Never expose customer's 4-digit arrivalPinCode to the professional
      arrivalPinCode: '****',
      pricing: {
        baseInspectionEgp: booking.baseInspectionEgp,
        serviceFeeEgp: booking.serviceFeeEgp,
        transportFeeEgp: booking.transportFeeEgp,
        totalEgp: booking.totalEgp,
        platformFeeEgp: booking.platformFeeEgp,
        netArtisanEgp: booking.netArtisanEgp,
        tipEgp,
        netPayoutWithTipEgp: booking.netArtisanEgp + tipEgp,
        currency: 'EGP',
      },
      offering: booking.offering
        ? {
            id: booking.offering.id,
            slug: booking.offering.slug,
            titleEn: booking.offering.titleEn,
            titleAr: booking.offering.titleAr,
            estimatedDurationMins: booking.offering.estimatedDurationMins,
            category: booking.offering.category
              ? {
                  id: booking.offering.category.id,
                  slug: booking.offering.category.slug,
                  nameEn: booking.offering.category.nameEn,
                  nameAr: booking.offering.category.nameAr,
                }
              : null,
          }
        : null,
      address: booking.address
        ? {
            id: booking.address.id,
            label: booking.address.label,
            buildingLine: booking.address.buildingLine,
            districtLine: booking.address.districtLine,
            gateNotes: booking.address.gateNotes ?? null,
            latitude: booking.address.latitude ?? null,
            longitude: booking.address.longitude ?? null,
            zone: booking.address.zone ?? null,
          }
        : null,
      customer: booking.customer
        ? {
            id: booking.customer.id,
            fullName: booking.customer.fullName ?? 'FIXO Customer',
          }
        : null,
      payment: booking.payment
        ? {
            id: booking.payment.id,
            method: booking.payment.method,
            status: booking.payment.status,
            amountEgp: booking.payment.amountEgp,
            tipEgp: booking.payment.tipEgp,
            paidAt: booking.payment.paidAt
              ? booking.payment.paidAt instanceof Date
                ? booking.payment.paidAt.toISOString()
                : String(booking.payment.paidAt)
              : null,
          }
        : null,
      review: booking.review
        ? {
            id: booking.review.id,
            rating: booking.review.rating,
            tags: booking.review.tags ?? [],
            comment: booking.review.comment ?? null,
            tipAmountEgp: booking.review.tipAmountEgp ?? 0,
          }
        : null,
      completedAt: booking.completedAt
        ? booking.completedAt instanceof Date
          ? booking.completedAt.toISOString()
          : String(booking.completedAt)
        : null,
    };
  }
}

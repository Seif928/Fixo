import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
  Optional,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import {
  BookingStatus,
  DocumentStatus,
  DocumentType,
  ExperienceTier,
  JobOfferStatus,
  PaymentMethodType,
  PaymentStatus,
  Prisma,
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
import { validatePrivateUploadPayload } from '../bookings/private-upload.util';
import { createHash, randomUUID } from 'crypto';
import { PrivateStorageService } from '../media/private-storage.service';
import { normalizePrivatePhoto } from '../media/normalize-private-photo';
import { PushService } from '../communications/push.service';
import { addressCoverageWhere } from '../services/coverage-policy';
import { ensureDispatchOffer, jobOfferDetailsInclude } from './dispatch-offers';
import { readCairoEarnings } from './cairo-earnings';
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
    @Optional() private readonly privateStorage?: PrivateStorageService,
  ) {}

  private readonly logger = new Logger(ProService.name);

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
   * Screen 11 (Step 1 of 4): legal name and 14-digit National ID.
   * Legacy clients may still send optional transport and primary zone fields.
   */
  async upsertPersonalDetails(userId: string, dto: ProPersonalDetailsDto) {
    if (
      !dto.fullName?.trim() ||
      dto.fullName.trim().length < 3 ||
      dto.fullName.trim().length > 120 ||
      /[\x00-\x1f\x7f]/.test(dto.fullName)
    ) {
      throw new BadRequestException('Enter your full legal name.');
    }
    if (!/^\d{14}$/.test(dto.nationalIdSynthetic.trim())) {
      throw new BadRequestException(
        'nationalIdSynthetic must be an exact 14-digit number.',
      );
    }

    return this.prisma.$transaction(async (tx) => {
      if (this.prisma.isDatabaseConnected()) {
        await tx.$queryRaw`SELECT id FROM "ProProfile" WHERE "userId" = ${userId} FOR UPDATE`;
      }
      const existing = await tx.proProfile.findUnique({
        where: { userId },
      });
      if (existing) this.assertDossierEditable(existing.verificationStatus);
      const zone = dto.primaryZoneId
        ? await tx.coverageZone.findUnique({
            where: { id: dto.primaryZoneId },
          })
        : null;

      if (dto.primaryZoneId && (!zone || !zone.isActive)) {
        throw new NotFoundException(
          `Active coverage zone "${dto.primaryZoneId}" was not found.`,
        );
      }

      if (dto.fullName?.trim()) {
        await tx.user.update({
          where: { id: userId },
          data: { fullName: dto.fullName.trim() },
        });
      }

      const dossierCode =
        existing?.dossierCode ?? (await this.generateUniqueDossierCode());

      const profile = existing
        ? await tx.proProfile.update({
            where: { userId },
            data: {
              nationalIdSynthetic: dto.nationalIdSynthetic.trim(),
              ...(dto.fullName?.trim()
                ? { legalName: dto.fullName.trim() }
                : {}),
              ...(zone ? { primaryZoneId: zone.id } : {}),
              transportMode: dto.transportMode,
              ...(dto.vehicleDescription !== undefined
                ? { vehicleDescription: dto.vehicleDescription.trim() || null }
                : {}),
              ...(dto.vehiclePlateAr !== undefined
                ? { vehiclePlateAr: dto.vehiclePlateAr.trim() || null }
                : {}),
              zonesLabelEn: existing?.zonesLabelEn || zone?.nameEn || null,
              zonesLabelAr: existing?.zonesLabelAr || zone?.nameAr || null,
            },
            include: this.proProfileInclude,
          })
        : await tx.proProfile.create({
            data: {
              userId,
              dossierCode,
              nationalIdSynthetic: dto.nationalIdSynthetic.trim(),
              legalName: dto.fullName?.trim() || null,
              primaryZoneId: zone?.id ?? null,
              transportMode: dto.transportMode ?? null,
              vehicleDescription: dto.vehicleDescription?.trim() || null,
              vehiclePlateAr: dto.vehiclePlateAr?.trim() || null,
              zonesLabelEn: zone?.nameEn ?? null,
              zonesLabelAr: zone?.nameAr ?? null,
              verificationStatus: ProVerificationStatus.DRAFT,
              ...(zone
                ? { coverageZones: { connect: [{ id: zone.id }] } }
                : {}),
            },
            include: this.proProfileInclude,
          });

      return this.mapProProfile(profile);
    });
  }

  /**
   * Screen 12 (Step 2 of 4): Primary Trade, Sub-Skills, Experience Tier,
   * Coverage Zones, Rate Card & Toolkit Commitment (`PUT /pro/onboarding/skills`).
   */
  async updateSkillsAndCoverage(userId: string, dto: ProSkillsUpdateDto) {
    return this.prisma.$transaction(async (tx) => {
      if (this.prisma.isDatabaseConnected()) {
        await tx.$queryRaw`SELECT id FROM "ProProfile" WHERE "userId" = ${userId} FOR UPDATE`;
      }
      const existing = await tx.proProfile.findUnique({
        where: { userId },
      });

      if (!existing) {
        throw new BadRequestException(
          'Please complete Step 1 (Personal Details) before configuring skills.',
        );
      }

      this.assertDossierEditable(existing.verificationStatus);

      if (!dto.toolkitCommitmentConfirmed) {
        throw new BadRequestException(
          'You must confirm ownership of a professional toolkit and safety gear.',
        );
      }

      const category = await tx.serviceCategory.findUnique({
        where: { id: dto.primaryCategoryId },
      });

      if (!category || !category.isActive) {
        throw new NotFoundException(
          `Active service category "${dto.primaryCategoryId}" was not found.`,
        );
      }

      const uniqueZoneIds = Array.from(new Set(dto.coverageZoneIds));
      const zones = await tx.coverageZone.findMany({
        where: { id: { in: uniqueZoneIds }, isActive: true },
      });

      if (zones.length !== uniqueZoneIds.length) {
        throw new BadRequestException(
          'One or more selected coverage zones are invalid or inactive.',
        );
      }

      const uniqueSubSkillIds = Array.from(new Set(dto.subSkillIds ?? []));
      if (uniqueSubSkillIds.length > 0) {
        const validSubSkills = await tx.serviceSubSkill.findMany({
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

      const updated = await tx.proProfile.update({
        where: { userId },
        data: {
          primaryCategoryId: category.id,
          primaryZoneId:
            existing.primaryZoneId &&
            uniqueZoneIds.includes(existing.primaryZoneId)
              ? existing.primaryZoneId
              : uniqueZoneIds[0],
          experienceTier: dto.experienceTier,
          acceptsStandardRateCard: dto.acceptsStandardRateCard,
          toolkitCommitmentConfirmed: dto.toolkitCommitmentConfirmed,
          specialtyEn:
            dto.specialtyEn?.trim() || `${category.nameEn} Specialist`,
          specialtyAr: dto.specialtyAr?.trim() || `أخصائي ${category.nameAr}`,
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
    });
  }

  /**
   * Screen 13 (Step 3 of 4): Private Verification Document Upload (`POST /pro/onboarding/documents`).
   * Validates file MIME type, size <= 2 MB, and binary magic bytes.
   * Stores document privately in `storageKey` so it is never publicly enumerable.
   */
  async uploadVerificationDocument(userId: string, dto: ProDocumentUploadDto) {
    if (!this.privateStorage)
      throw new ServiceUnavailableException(
        'Private document storage is unavailable.',
      );
    const profile = await this.prisma.proProfile.findUnique({
      where: { userId },
    });
    if (!profile)
      throw new BadRequestException(
        'Complete personal details before uploading documents.',
      );
    this.assertDossierEditable(profile.verificationStatus);
    const validated = validatePrivateUploadPayload({
      purpose: 'PRO_DOCUMENT',
      fileName: dto.fileName,
      mimeType: dto.mimeType,
      contentBase64: dto.contentBase64,
    });
    const bytes = await normalizePrivatePhoto(
      Buffer.from(validated.normalizedBase64, 'base64'),
      dto.mimeType,
      'document',
    );
    const key = `documents/${profile.id}/${randomUUID()}.webp`;
    const hash = createHash('sha256').update(bytes).digest('hex');
    await this.privateStorage.put(key, bytes, 'image/webp');
    let result: { doc: any; oldKey: string | null };
    try {
      result = await this.prisma.$transaction(async (tx) => {
        if (this.prisma.isDatabaseConnected()) {
          await tx.$queryRaw`SELECT id FROM "ProProfile" WHERE id = ${profile.id} FOR UPDATE`;
        }
        const current = await tx.proProfile.findUnique({
          where: { id: profile.id },
        });
        if (!current)
          throw new NotFoundException('Professional profile was not found.');
        this.assertDossierEditable(current.verificationStatus);
        const existing = await tx.proVerificationDocument.findFirst({
          where: { proProfileId: profile.id, docType: dto.docType },
        });
        const data = {
          storageKey: `obj::${hash}::image/webp::${key}`,
          fileName: `${dto.docType.toLowerCase()}.webp`,
          fileSizeBytes: bytes.length,
          status: DocumentStatus.PENDING,
          reviewerComment: null,
          uploadedAt: new Date(),
        };
        const doc = existing
          ? await tx.proVerificationDocument.update({
              where: { id: existing.id },
              data,
            })
          : await tx.proVerificationDocument.create({
              data: { ...data, proProfileId: profile.id, docType: dto.docType },
            });
        return {
          doc,
          oldKey: existing?.storageKey?.startsWith('obj::')
            ? existing.storageKey.split('::')[3]
            : null,
        };
      });
    } catch (error) {
      await this.cleanupDocumentObject(key);
      throw error;
    }
    if (result.oldKey) await this.cleanupDocumentObject(result.oldKey);
    return this.mapDocumentSummary(result.doc);
  }

  private assertDossierEditable(status: ProVerificationStatus) {
    if (
      status !== ProVerificationStatus.DRAFT &&
      status !== ProVerificationStatus.ACTION_REQUIRED
    ) {
      throw new ForbiddenException(
        'Documents can be changed while drafting or when a reviewer requests corrections.',
      );
    }
  }

  private async cleanupDocumentObject(key: string) {
    try {
      await this.privateStorage!.remove(key);
    } catch {
      this.logger.warn('Private document cleanup needs retry.');
    }
  }

  /**
   * Generates a short-lived authenticated access payload for a private verification document.
   * Strictly restricted to the owning user or an ADMIN reviewer.
   */
  private async authorizedDocument(
    userId: string,
    docId: string,
    isAdmin: boolean,
  ) {
    const doc = await this.prisma.proVerificationDocument.findUnique({
      where: { id: docId },
      include: { proProfile: { select: { id: true, userId: true } } },
    });
    if (!doc)
      throw new NotFoundException('Verification document was not found.');
    if (!isAdmin && doc.proProfile.userId !== userId)
      throw new ForbiddenException(
        'This private document belongs to another account.',
      );
    return doc;
  }

  async getVerificationDocumentAccess(
    userId: string,
    docId: string,
    isAdmin = false,
  ) {
    const doc = await this.authorizedDocument(userId, docId, isAdmin);
    return {
      ...this.mapDocumentSummary(doc),
      downloadPath: `/api/v1/pro/onboarding/documents/${encodeURIComponent(doc.id)}/content`,
    };
  }

  async getVerificationDocumentContent(
    userId: string,
    docId: string,
    isAdmin = false,
  ) {
    const doc = await this.authorizedDocument(userId, docId, isAdmin);
    const parts = doc.storageKey.split('::');
    if (
      parts[0] === 'obj' &&
      parts[3]?.startsWith(`documents/${doc.proProfileId}/`)
    ) {
      if (!this.privateStorage)
        throw new ServiceUnavailableException(
          'Private document storage is unavailable.',
        );
      return {
        bytes: await this.privateStorage.get(parts[3]),
        mimeType: parts[2],
      };
    }
    // Existing private development records remain available only through ownership checks.
    if (
      parts[0] === 'prvdoc' &&
      ['image/jpeg', 'image/png', 'image/webp', 'application/pdf'].includes(
        parts[2],
      )
    ) {
      return {
        bytes: Buffer.from(parts[3] ?? '', 'base64'),
        mimeType: parts[2],
      };
    }
    throw new NotFoundException('Private document content was not found.');
  }

  /**
   * Screen 13 -> Screen 14: Submits completed dossier for manual verification review (`POST /pro/onboarding/submit`).
   * Validates that Step 1, Step 2, and all 3 required documents are present, then transitions
   * `verificationStatus` from `DRAFT` / `ACTION_REQUIRED` to `PENDING_REVIEW`.
   */
  async submitForVerification(userId: string) {
    await this.prisma.$transaction(async (tx) => {
      if (this.prisma.isDatabaseConnected()) {
        await tx.$queryRaw`SELECT id FROM "ProProfile" WHERE "userId" = ${userId} FOR UPDATE`;
      }
      const profile = await tx.proProfile.findUnique({
        where: { userId },
        include: this.proProfileInclude,
      });

      if (!profile) {
        throw new BadRequestException(
          'Professional profile has not been started yet.',
        );
      }

      if (!profile.nationalIdSynthetic) {
        throw new BadRequestException(
          'Step 1 (Personal Details) is incomplete.',
        );
      }

      if (
        !profile.primaryCategoryId ||
        !profile.primaryZoneId ||
        profile.coverageZones.length === 0 ||
        !profile.toolkitCommitmentConfirmed
      ) {
        throw new BadRequestException(
          'Step 2 (Services, Skills & Coverage Zones) is incomplete.',
        );
      }

      const uploadedDocTypes = new Set(
        profile.documents
          .filter(
            (d) =>
              d.status !== DocumentStatus.REJECTED &&
              (d.storageKey.startsWith('obj::') ||
                d.storageKey.startsWith('prvdoc::')),
          )
          .map((d) => d.docType),
      );
      const missingDocs = REQUIRED_PRO_DOC_TYPES.filter(
        (reqType) => !uploadedDocTypes.has(reqType),
      );

      if (missingDocs.length > 0) {
        throw new BadRequestException(
          `Missing required verification documents: ${missingDocs.join(', ')}.`,
        );
      }

      if (profile.verificationStatus === ProVerificationStatus.APPROVED) {
        return;
      }

      if (profile.verificationStatus === ProVerificationStatus.SUSPENDED) {
        throw new ForbiddenException(
          'Suspended professional profiles cannot be resubmitted without administrator intervention.',
        );
      }

      await tx.proProfile.update({
        where: { id: profile.id },
        data: {
          verificationStatus: ProVerificationStatus.PENDING_REVIEW,
        },
      });
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
        titleEn: 'Identity & Criminal Record Documents',
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

    const updated = await this.prisma.$transaction(async (tx) => {
      if (this.prisma.isDatabaseConnected()) {
        await tx.$queryRaw`SELECT id FROM "ProProfile" WHERE id = ${proProfileId} FOR UPDATE`;
      }
      const profile = await tx.proProfile.findUnique({
        where: { id: proProfileId },
        include: { documents: true },
      });
      if (!profile)
        throw new NotFoundException('Professional profile was not found.');
      if (dto.status === 'APPROVED') {
        if (
          profile.verificationStatus !== ProVerificationStatus.PENDING_REVIEW &&
          profile.verificationStatus !== ProVerificationStatus.APPROVED
        ) {
          throw new BadRequestException(
            'Only a submitted dossier can be approved.',
          );
        }
        const missing = REQUIRED_PRO_DOC_TYPES.filter(
          (type) =>
            !profile.documents.some(
              (doc) =>
                doc.docType === type &&
                Boolean(doc.storageKey) &&
                doc.status !== DocumentStatus.REJECTED,
            ),
        );
        if (missing.length)
          throw new BadRequestException(
            'All three required private documents must be uploaded before approval.',
          );
        if (
          dto.documentDecisions?.some(
            (decision) =>
              REQUIRED_PRO_DOC_TYPES.includes(decision.docType) &&
              decision.status === 'REJECTED',
          )
        ) {
          throw new BadRequestException(
            'A dossier with rejected required documents cannot be approved.',
          );
        }
      }

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
            dto.reviewerNote?.trim() || `Reviewed by admin ${adminUserId}`,
          ...(dto.status !== 'APPROVED' ? { isOnline: false } : {}),
        },
        include: this.proProfileInclude,
      });

      if (dto.status !== 'APPROVED') {
        await tx.jobOffer.updateMany({
          where: { proProfileId: profile.id, status: JobOfferStatus.PENDING },
          data: { status: JobOfferStatus.EXPIRED, respondedAt: new Date() },
        });
      }

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

    const updated = await this.prisma.$transaction(async (tx) => {
      await this.lockApprovedProfile(tx, userId);
      return tx.proProfile.update({
        where: { id: profile.id },
        data: { isOnline: dto.isOnline },
        include: this.proProfileInclude,
      });
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
    const [activeOffersRaw, activeJobsRaw, completedJobsRaw, earnings] =
      await Promise.all([
        this.prisma.jobOffer.findMany({
          where: {
            proProfileId: profile.id,
            status: JobOfferStatus.PENDING,
            expiresAt: { gt: now },
            proProfile: { verificationStatus: ProVerificationStatus.APPROVED },
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
          take: 10,
        }),
        readCairoEarnings(this.prisma, profile.id, now),
      ]);

    // 4. Compute actual Today & 7-Day Net Earnings from COMPLETED bookings
    return {
      profile: this.mapProProfile(profile),
      earningsSummary: {
        todayNetEarningsEgp: earnings.todayNetEarningsEgp,
        todayCompletedCount: earnings.todayCompletedCount,
        weeklyNetEarningsEgp: earnings.weeklyNetEarningsEgp,
        weeklyCompletedCount: earnings.weeklyCompletedCount,
        totalCompletedJobsCount: profile.completedJobsCount,
        acceptanceRatePct: profile.acceptanceRatePct,
        ratingAvg: profile.reviewsCount > 0 ? profile.ratingAvg : 0,
        reviewsCount: profile.reviewsCount,
        currency: 'EGP',
      },
      weeklyTrajectory: earnings.weeklyTrajectory,
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
    if (profile.verificationStatus !== ProVerificationStatus.APPROVED) {
      throw new ForbiddenException(
        'Only currently approved professionals can view incoming offers.',
      );
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
      await this.prisma.jobOffer.updateMany({
        where: {
          id: offer.id,
          status: JobOfferStatus.PENDING,
          expiresAt: { lte: new Date() },
        },
        data: {
          status: JobOfferStatus.EXPIRED,
          respondedAt: new Date(),
        },
      });
      const expired = await this.prisma.jobOffer.findUnique({
        where: { id: offer.id },
        include: jobOfferDetailsInclude,
      });
      if (!expired) throw new NotFoundException('Job offer was not found.');
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

    const hint = await this.prisma.jobOffer.findUnique({
      where: { id: offerId },
      select: { bookingId: true, proProfileId: true },
    });
    if (!hint) throw new NotFoundException('Job offer was not found.');
    if (hint.proProfileId !== profile.id)
      throw new ForbiddenException('You do not own this job offer.');
    const result = await this.prisma.$transaction(async (tx) => {
      if (this.prisma.isDatabaseConnected()) {
        await tx.$queryRaw`SELECT id FROM "Booking" WHERE id = ${hint.bookingId} FOR UPDATE`;
      }
      const profile = await this.lockApprovedProfile(tx, userId);
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
      if (offer.bookingId !== hint.bookingId)
        throw new ConflictException('The job offer changed. Reload it.');

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

    const hint = await this.prisma.jobOffer.findUnique({
      where: { id: offerId },
      select: { bookingId: true, proProfileId: true },
    });
    if (!hint) throw new NotFoundException('Job offer was not found.');
    if (hint.proProfileId !== profile.id)
      throw new ForbiddenException('You do not own this job offer.');
    const updatedOffer = await this.prisma.$transaction(async (tx) => {
      // Same lock order as acceptance, dispatch and customer cancellation.
      if (this.prisma.isDatabaseConnected()) {
        await tx.$queryRaw`SELECT id FROM "Booking" WHERE id = ${hint.bookingId} FOR UPDATE`;
        await tx.$queryRaw`SELECT id FROM "ProProfile" WHERE id = ${profile.id} FOR UPDATE`;
        await tx.$queryRaw`SELECT id FROM "JobOffer" WHERE id = ${offerId} FOR UPDATE`;
      }
      const offer = await tx.jobOffer.findUnique({
        where: { id: offerId },
      });

      if (!offer) {
        throw new NotFoundException(`Job offer "${offerId}" was not found.`);
      }

      if (
        offer.proProfileId !== profile.id ||
        offer.bookingId !== hint.bookingId
      ) {
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
    const result = await this.prisma.$transaction(async (tx) => {
      // Serialize with other transitions and customer cancellation before reading state.
      if (this.prisma.isDatabaseConnected()) {
        await tx.$queryRaw`SELECT id FROM "Booking" WHERE id = ${bookingId} FOR UPDATE`;
      }
      const profile = await tx.proProfile.findUnique({
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

      const booking = await tx.booking.findUnique({
        where: { id: bookingId },
        include: {
          offering: { include: { category: true } },
          address: { include: { zone: true } },
          customer: { select: { id: true, fullName: true, phone: true } },
          payment: true,
        },
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

      if (booking.status === dto.toStatus) {
        return { updated: booking, changed: false, pinError: null };
      }

      const requiredCurrent = expectedFromStatus[dto.toStatus];
      if (booking.status !== requiredCurrent) {
        throw new BadRequestException(
          `Invalid status transition from "${booking.status}" to "${dto.toStatus}". Expected current status "${requiredCurrent}".`,
        );
      }

      // Arrival PIN verification with bounded attempts (max 5) when transitioning ARRIVED -> IN_PROGRESS
      if (dto.toStatus === BookingStatus.IN_PROGRESS) {
        const failedAttempts = await tx.bookingStatusEvent.count({
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
          await tx.bookingStatusEvent.create({
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
          // Commit the failed attempt; throwing inside the transaction would roll it back.
          return {
            updated: null,
            changed: false,
            pinError: new BadRequestException(
              `Invalid 4-digit Arrival PIN code. ${remainingAttempts} attempt(s) remaining.`,
            ),
          };
        }
      }

      const now = new Date();
      const defaultNotes: Record<ProAdvanceJobStatusDto['toStatus'], string> = {
        PRO_EN_ROUTE: 'Professional departed toward customer location',
        ARRIVED: 'Professional arrived at customer address',
        IN_PROGRESS: 'Customer 4-digit Arrival PIN verified — service started',
        COMPLETED: 'Service completed and cash settlement confirmed',
      };

      await tx.booking.update({
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

      const updated = await tx.booking.findUniqueOrThrow({
        where: { id: booking.id },
        include: {
          offering: { include: { category: true } },
          address: { include: { zone: true } },
          customer: { select: { id: true, fullName: true, phone: true } },
          payment: true,
        },
      });
      return { updated, changed: true, pinError: null };
    });

    if (result.pinError) throw result.pinError;
    const updated = result.updated!;
    if (result.changed && this.pushService) {
      await this.pushService.notify(updated.customerId, updated.id);
    }
    return this.mapProJobSummary(updated);
  }

  private async syncPendingOffersForPro(profile: any): Promise<void> {
    if (
      !this.prisma.isDatabaseConnected() ||
      !profile.primaryCategoryId ||
      profile.verificationStatus !== ProVerificationStatus.APPROVED ||
      !profile.isOnline
    ) {
      return;
    }

    const areas = [
      ...(profile.primaryZone ? [profile.primaryZone] : []),
      ...(profile.coverageZones ?? []),
    ];

    if (areas.length === 0) {
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
        address: addressCoverageWhere(areas),
      },
      take: 10,
    });

    for (const bk of waitingBookings) {
      await ensureDispatchOffer(this.prisma, bk.id, profile.id, true);
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

  private async lockApprovedProfile(
    tx: Prisma.TransactionClient,
    userId: string,
  ) {
    if (this.prisma.isDatabaseConnected()) {
      await tx.$queryRaw`SELECT id FROM "ProProfile" WHERE "userId" = ${userId} FOR UPDATE`;
    }
    const profile = await tx.proProfile.findUnique({
      where: { userId },
      include: this.proProfileInclude,
    });
    if (!profile)
      throw new NotFoundException('Professional profile was not found.');
    if (profile.verificationStatus !== ProVerificationStatus.APPROVED) {
      throw new ForbiddenException(
        'Only currently APPROVED professionals can take new jobs or change availability.',
      );
    }
    return profile;
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
      doc.storageKey &&
        (doc.storageKey.startsWith('obj::') ||
          doc.storageKey.startsWith('prvdoc::')),
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
    const step1Complete = Boolean(profile.nationalIdSynthetic);
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
      fullName: profile.legalName ?? profile.user?.fullName ?? null,
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
      ratingAvg: profile.reviewsCount > 0 ? profile.ratingAvg : 0,
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
    const remainingSeconds = Math.max(
      0,
      Math.floor((expiresMs - nowMs) / 1000),
    );
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
    const tipEgp = booking.payment?.tipEgp ?? booking.review?.tipAmountEgp ?? 0;

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

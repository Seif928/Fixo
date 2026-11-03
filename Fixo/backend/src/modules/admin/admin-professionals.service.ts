import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { dossierReviewVersion } from '../pro/dossier-review-version';
import { AdminAccessService, AdminActor } from './admin-access.service';
import type { ProfessionalQueryDto } from './admin-professionals.controller';

@Injectable()
export class AdminProfessionalsService {
  constructor(
    private readonly db: PrismaService,
    private readonly access: AdminAccessService,
  ) {}
  async list(query: ProfessionalQueryDto) {
    const where: Prisma.ProProfileWhereInput = {
      ...(query.status ? { verificationStatus: query.status } : {}),
      ...(query.search
        ? {
            OR: [
              { legalName: { contains: query.search, mode: 'insensitive' } },
              { dossierCode: { contains: query.search, mode: 'insensitive' } },
              {
                user: {
                  fullName: { contains: query.search, mode: 'insensitive' },
                },
              },
            ],
          }
        : {}),
    };
    const [rows, total] = await this.db.$transaction([
      this.db.proProfile.findMany({
        where,
        skip: (query.page - 1) * 20,
        take: 20,
        orderBy: [{ updatedAt: 'desc' }, { id: 'desc' }],
        select: {
          id: true,
          dossierCode: true,
          legalName: true,
          verificationStatus: true,
          updatedAt: true,
          user: { select: { fullName: true } },
          primaryCategory: { select: { nameEn: true, nameAr: true } },
          _count: { select: { documents: true } },
        },
      }),
      this.db.proProfile.count({ where }),
    ]);
    return {
      items: rows.map((p) => ({
        id: p.id,
        dossierCode: p.dossierCode,
        legalName: p.legalName,
        displayName: p.user.fullName,
        verificationStatus: p.verificationStatus,
        updatedAt: p.updatedAt,
        category: p.primaryCategory,
        documentCount: p._count.documents,
      })),
      meta: {
        page: query.page,
        total,
        totalPages: Math.max(1, Math.ceil(total / 20)),
      },
    };
  }
  detail(actor: AdminActor, id: string) {
    return this.access.mutate(
      actor,
      false,
      'PRO_DOSSIER_ACCESSED',
      id,
      async (tx) => {
        const p = await tx.proProfile.findUnique({
          where: { id },
          include: {
            user: { select: { fullName: true, phone: true, email: true } },
            primaryCategory: { select: { nameEn: true, nameAr: true } },
            coverageZones: { select: { id: true, nameEn: true, nameAr: true } },
            documents: { orderBy: { docType: 'asc' } },
          },
        });
        if (!p)
          throw new NotFoundException('Professional profile was not found.');
        const value = {
          id: p.id,
          dossierCode: p.dossierCode,
          legalName: p.legalName,
          nationalId: p.nationalIdSynthetic,
          displayName: p.user.fullName,
          phone: p.user.phone,
          email: p.user.email,
          verificationStatus: p.verificationStatus,
          reviewerNote: p.reviewerNote,
          category: p.primaryCategory,
          coverageZones: p.coverageZones,
          experienceTier: p.experienceTier,
          toolkitCommitmentConfirmed: p.toolkitCommitmentConfirmed,
          isOnline: p.isOnline,
          updatedAt: p.updatedAt,
          canReview: p.userId !== actor.userId,
          reviewVersion: dossierReviewVersion(p),
          documents: p.documents.map((d) => ({
            id: d.id,
            docType: d.docType,
            status: d.status,
            fileName: d.fileName,
            fileSizeBytes: d.fileSizeBytes,
            uploadedAt: d.uploadedAt,
            reviewerComment: d.reviewerComment,
            mimeType: [
              'image/jpeg',
              'image/png',
              'image/webp',
              'application/pdf',
            ].includes(d.storageKey.split('::')[2])
              ? d.storageKey.split('::')[2]
              : null,
          })),
        };
        return { value, details: { proProfileId: id } };
      },
    );
  }
}

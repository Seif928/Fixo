import {
  BadRequestException,
  Injectable,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CustomerAddressResponse } from './dto/address-response.dto';
import { CreateAddressDto } from './dto/create-address.dto';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async updateDisplayName(userId: string, fullName: string) {
    if (!this.prisma.isDatabaseConnected())
      throw new ServiceUnavailableException(
        'Profile changes require database persistence.',
      );
    const name = fullName.trim();
    if (name.length < 2 || name.length > 100 || /[\x00-\x1f\x7f]/.test(name))
      throw new BadRequestException('Enter a valid name.');
    // Only the public display name changes; ProProfile.legalName stays reviewed.
    await this.prisma.user.update({
      where: { id: userId },
      data: { fullName: name },
    });
  }

  /**
   * Formats a Prisma CustomerAddress record with its associated CoverageZone
   * into a standardized CustomerAddressResponse for Flutter consumption.
   */
  public formatAddressResponse(address: any): CustomerAddressResponse {
    return {
      id: address.id,
      userId: address.userId,
      zoneId: address.zoneId,
      label: address.label,
      buildingLine: address.buildingLine,
      districtLine: address.districtLine,
      gateNotes: address.gateNotes ?? null,
      latitude:
        address.latitude !== null && address.latitude !== undefined
          ? Number(address.latitude)
          : null,
      longitude:
        address.longitude !== null && address.longitude !== undefined
          ? Number(address.longitude)
          : null,
      isDefault: Boolean(address.isDefault),
      createdAt:
        address.createdAt instanceof Date
          ? address.createdAt.toISOString()
          : String(address.createdAt),
      zone: address.zone
        ? {
            id: address.zone.id,
            slug: address.zone.slug,
            nameEn: address.zone.nameEn,
            nameAr: address.zone.nameAr,
            governorate: address.zone.governorate,
            isActive: Boolean(address.zone.isActive),
          }
        : undefined,
    };
  }

  /**
   * Creates a new customer delivery address in Greater Cairo / Giza.
   *
   * Validations & Invariants:
   * 1. Customer exists in the database.
   * 2. Coverage zone exists and is active.
   * 3. userId is strictly derived from the authenticated JWT session (never client body).
   * 4. When setting isDefault: true, clears previous default addresses for this customer
   *    within an atomic PostgreSQL transaction.
   * 5. Non-default creations preserve all existing customer addresses and defaults.
   */
  async createAddress(
    userId: string,
    dto: CreateAddressDto,
  ): Promise<CustomerAddressResponse> {
    // 1. Validate Customer User Existence
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });
    if (!user) {
      throw new NotFoundException('Authenticated customer account not found.');
    }

    // 2. Validate Coverage Zone
    const zone = await this.prisma.coverageZone.findFirst({
      where: {
        OR: [{ id: dto.zoneId }, { slug: dto.zoneId }],
      },
    });
    if (!zone) {
      throw new NotFoundException(`Coverage zone "${dto.zoneId}" not found.`);
    }
    if (!zone.isActive) {
      throw new BadRequestException(
        `Coverage zone "${zone.nameEn}" is currently inactive.`,
      );
    }

    // 3. Validate Non-Empty Trimmed Fields
    const label = dto.label.trim();
    const buildingLine = dto.buildingLine.trim();
    const districtLine = dto.districtLine.trim();
    const gateNotes = dto.gateNotes?.trim() || null;

    if (label.length === 0) {
      throw new BadRequestException('Address label cannot be empty.');
    }
    if (buildingLine.length === 0) {
      throw new BadRequestException('Building line cannot be empty.');
    }
    if (districtLine.length === 0) {
      throw new BadRequestException('District line cannot be empty.');
    }

    const willBeDefault = dto.isDefault === true;

    // 4. Atomic PostgreSQL Transaction
    const createdAddress = await this.prisma.$transaction(async (tx) => {
      if (willBeDefault) {
        // Concurrency safety lock: Serialize default address mutations for this user.
        // Acquiring an exclusive row-level lock on the parent User row for the duration
        // of this transaction guarantees that concurrent address creation requests
        // for the same customer cannot race, ensuring strictly one default address.
        await tx.$queryRaw`
          SELECT "id" FROM "User" WHERE "id" = ${userId} FOR UPDATE;
        `;

        // Clear any previous default address specifically for THIS customer
        await tx.customerAddress.updateMany({
          where: {
            userId,
            isDefault: true,
          },
          data: {
            isDefault: false,
          },
        });
      }

      return tx.customerAddress.create({
        data: {
          userId,
          zoneId: zone.id,
          label,
          buildingLine,
          districtLine,
          gateNotes,
          latitude: dto.latitude ?? null,
          longitude: dto.longitude ?? null,
          isDefault: willBeDefault,
        },
        include: {
          zone: true,
        },
      });
    });

    return this.formatAddressResponse(createdAddress);
  }

  /**
   * Retrieves all saved delivery addresses for the authenticated customer.
   * Ordered by isDefault descending, then createdAt descending.
   */
  async findUserAddresses(userId: string): Promise<CustomerAddressResponse[]> {
    if (!this.prisma.isDatabaseConnected()) {
      return [];
    }

    const addresses = await this.prisma.customerAddress.findMany({
      where: { userId },
      include: { zone: true },
      orderBy: [{ isDefault: 'desc' }, { createdAt: 'desc' }],
    });

    return addresses.map((addr) => this.formatAddressResponse(addr));
  }
}

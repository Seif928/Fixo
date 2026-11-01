import { BookingStatus, TimeWindow } from '@prisma/client';

export interface BookingPricingBreakdown {
  baseInspectionEgp: number;
  serviceFeeEgp: number;
  transportFeeEgp: number;
  totalEgp: number;
  platformFeeEgp: number;
  netArtisanEgp: number;
  currency: 'EGP';
}

export interface BookingOfferingSummary {
  id: string;
  slug: string;
  titleEn: string;
  titleAr: string;
  descriptionEn: string;
  descriptionAr: string;
  category: {
    id: string;
    slug: string;
    nameEn: string;
    nameAr: string;
  };
}

export interface BookingAddressSummary {
  id: string;
  label: string;
  buildingLine: string;
  districtLine: string;
  gateNotes?: string | null;
  zone?: {
    id: string;
    slug: string;
    nameEn: string;
    nameAr: string;
    governorate: string;
  } | null;
}

export interface BookingProSummary {
  id: string;
  dossierCode: string;
  specialtyEn?: string | null;
  specialtyAr?: string | null;
  ratingAvg: number;
  user?: {
    fullName?: string | null;
    avatarUrl?: string | null;
  } | null;
}

export interface BookingDetailResponse {
  id: string;
  orderCode: string;
  customerId: string;
  proProfileId: string | null;
  offeringId: string;
  addressId: string;
  status: BookingStatus;
  scheduledDate: string;
  timeWindow: TimeWindow;
  issueDescription: string | null;
  issuePhotoUrls: string[];
  pricing: BookingPricingBreakdown;
  arrivalPinCode: string;
  offering: BookingOfferingSummary;
  address: BookingAddressSummary;
  proProfile?: BookingProSummary | null;
  statusEvents?: Array<{
    id: string;
    fromStatus: BookingStatus | null;
    toStatus: BookingStatus;
    note?: string | null;
    createdAt: string;
  }>;
  createdAt: string;
  updatedAt: string;
  completedAt?: string | null;
}

export interface BookingListResponse {
  bookings: BookingDetailResponse[];
  total: number;
  limit: number;
  offset: number;
}


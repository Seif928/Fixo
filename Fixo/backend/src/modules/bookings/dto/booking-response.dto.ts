import {
  BookingStatus,
  PaymentMethodType,
  PaymentStatus,
  TimeWindow,
} from '@prisma/client';

export interface BookingPaymentSummary {
  id: string;
  bookingId: string;
  method: PaymentMethodType;
  status: PaymentStatus;
  amountEgp: number;
  tipEgp: number;
  externalReference: string | null;
  paidAt: string | null;
  createdAt: string;
}

export interface BookingReviewSummary {
  id: string;
  bookingId: string;
  customerId: string;
  proProfileId: string;
  rating: number;
  tags: string[];
  comment: string | null;
  photoUrls: string[];
  tipAmountEgp: number;
  createdAt: string;
}

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
  estimatedDurationMins?: number;
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
  latitude?: number | null;
  longitude?: number | null;
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
  reviewsCount?: number;
  completedJobsCount?: number;
  transportMode?: string;
  vehicleDescription?: string | null;
  vehiclePlateAr?: string | null;
  isOnline?: boolean;
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
  cancellationReason?: string | null;
  scheduledDate: string;
  scheduledTime?: string | null;
  timeWindow: TimeWindow;
  issueDescription: string | null;
  issuePhotoUrls: string[];
  pricing: BookingPricingBreakdown;
  arrivalPinCode: string;
  offering: BookingOfferingSummary;
  address: BookingAddressSummary;
  proProfile?: BookingProSummary | null;
  payment?: BookingPaymentSummary | null;
  review?: BookingReviewSummary | null;
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

export interface BookingTrackingMilestone {
  key:
    | 'ORDER_PLACED'
    | 'PRO_ASSIGNED'
    | 'PRO_EN_ROUTE'
    | 'ARRIVED_AT_LOCATION'
    | 'IN_PROGRESS_AND_COMPLETION';
  titleEn: string;
  titleAr: string;
  subtitleEn: string;
  subtitleAr: string;
  state: 'COMPLETED' | 'CURRENT' | 'UPCOMING' | 'CANCELLED';
  timestamp: string | null;
}

export interface BookingTrackingResponse {
  booking: BookingDetailResponse;
  milestones: BookingTrackingMilestone[];
  canCancel: boolean;
  canChat: boolean;
  canReview: boolean;
  trackingAccuracyNoteEn: string;
  trackingAccuracyNoteAr: string;
}

export interface BookingReceiptLineItem {
  key: string;
  labelEn: string;
  labelAr: string;
  amountEgp: number;
}

export interface BookingReceiptResponse {
  receiptNumber: string;
  bookingId: string;
  orderCode: string;
  status: BookingStatus;
  issuedAt: string;
  scheduledDate: string;
  scheduledTime?: string | null;
  timeWindow: TimeWindow;
  completedAt: string | null;
  customerName: string;
  serviceTitleEn: string;
  serviceTitleAr: string;
  categoryNameEn: string;
  categoryNameAr: string;
  proName: string | null;
  proDossierCode: string | null;
  addressSummary: string;
  lineItems: BookingReceiptLineItem[];
  subtotalEgp: number;
  tipEgp: number;
  grandTotalEgp: number;
  platformFeeEgp: number;
  netArtisanEgp: number;
  currency: 'EGP';
  paymentMethod: PaymentMethodType;
  paymentStatus: PaymentStatus;
  paidAt: string | null;
}

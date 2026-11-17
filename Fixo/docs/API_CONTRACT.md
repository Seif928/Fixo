# FIXO — REST API Contract (`docs/API_CONTRACT.md`)

Base URL: `/api/v1`  
Content-Type: `application/json`  
Authentication: `Authorization: Bearer <accessToken>` (except public health, catalog, and OTP auth routes).

---

## 1. System & Health

### `GET /api/v1/health`
- **Auth**: Public
- **Response `200 OK`**:
```json
{
  "status": "ok",
  "service": "fixo-backend",
  "market": "EG",
  "currency": "EGP",
  "timestamp": "2026-10-31T03:25:00.000Z"
}
```

---

## 2. Authentication (Screen 01 & Screen 02)

### `POST /api/v1/auth/otp/request`
Initiates an SMS OTP challenge for an Egyptian mobile number (`02_phone_auth_otp` — Tab 1).
- **Auth**: Public
- **Request Body**:
```json
{
  "phone": "+201023456789"
}
```
- **Validation**: Must match Egyptian mobile pattern `^\+201[0125]\d{8}$`.
- **Response `200 OK`**:
```json
{
  "challengeId": "c72e71f2-1d6b-4a8e-9b1c-8477d0b3e111",
  "phone": "+201023456789",
  "resendAvailableInSec": 45,
  "demoHint": "Use 482910 in development/demo mode"
}
```

### `POST /api/v1/auth/otp/verify`
Verifies the 6-digit OTP code and returns JWT tokens (`02_phone_auth_otp` — Tab 2).
- **Auth**: Public
- **Request Body**:
```json
{
  "challengeId": "c72e71f2-1d6b-4a8e-9b1c-8477d0b3e111",
  "phone": "+201023456789",
  "code": "482910"
}
```
- **Response `200 OK`**:
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "refreshToken": "def50200a18c...",
  "user": {
    "id": "u-salma-01",
    "phone": "+201023456789",
    "fullName": "Salma El-Shazly",
    "role": "CUSTOMER",
    "preferredLocale": "en"
  }
}
```

### `POST /api/v1/auth/refresh`
Rotates refresh token and issues a new access token.

### `POST /api/v1/auth/logout`
Revokes the active refresh token (`10_profile_notifications`).

---

## 3. Catalog & Service Discovery (Screen 03)

### `GET /api/v1/catalog/home`
Fetches coverage zones, seasonal hero promotion, 6 service categories, bundle offers, and top-rated pros for `03_customer_home`.
- **Query Params**: `?zoneSlug=sheikh-zayed&q=`
- **Response `200 OK`**:
```json
{
  "activeZone": {
    "slug": "sheikh-zayed",
    "nameEn": "Sheikh Zayed, Dist. 9",
    "governorate": "Giza"
  },
  "seasonalPromo": {
    "offeringId": "off-ac-deep-clean",
    "badge": "SEASONAL PEAK",
    "title": "Summer AC Deep Clean & Gas Refill",
    "subtitle": "Complete coil flush, antibacterial sanitized mist, and pressure gauge test.",
    "flatPriceEgp": 350
  },
  "categories": [
    {
      "slug": "ac-maintenance",
      "nameEn": "AC Maintenance",
      "subtitleEn": "Inverter, split & duct",
      "startingPriceEgp": 450,
      "iconName": "mode_fan"
    }
  ],
  "topPros": [
    {
      "proProfileId": "pro-tarek-01",
      "fullName": "Eng. Tarek Mansour",
      "specialty": "Master Electrician",
      "zonesLabel": "New Cairo & Maadi",
      "ratingAvg": 4.9,
      "reviewsCount": 184,
      "estimatedPriceEgp": 250,
      "badge": "Verified Master Pro"
    }
  ]
}
```

---

## 4. Customer Bookings, Payment, Tracking, Chat & Reviews (Screens 04–09)

### `POST /api/v1/bookings` (Screen 04: `CreateBookingPage`)
Creates a booking in `DRAFT` status and calculates the EGP fare breakdown.
- **Auth**: `CUSTOMER`
- **Request Body**:
```json
{
  "offeringId": "off-ac-deep-clean",
  "preferredProId": "pro-hassan-01",
  "addressId": "addr-palm-hills-14",
  "scheduledDate": "2026-11-02",
  "timeWindow": "AFTERNOON_13_16",
  "issueDescription": "AC in living room is leaking water and not cooling efficiently.",
  "issuePhotoUrls": []
}
```
- **Response `201 Created`**: Returns booking `#FX-8842` with `baseInspectionEgp: 150`, `serviceFeeEgp: 250`, `transportFeeEgp: 0`, `totalEgp: 400`.

### `POST /api/v1/bookings/:bookingId/checkout` (Screen 05: `CheckoutPage`)
Confirms payment method and transitions booking from `DRAFT` to `PENDING_DISPATCH`.
- **Auth**: `CUSTOMER`
- **Request Body**:
```json
{
  "paymentMethod": "CASH_ON_SERVICE"
}
```
- **Note**: In MVP, `CASH_ON_SERVICE` is immediately accepted; sandbox methods return a clear sandbox status or validation notice until gateway keys are configured.

### `GET /api/v1/bookings` (Screen 08: `OrdersPage`)
Lists customer orders filtered by `?tab=active|completed|cancelled&q=`.

### `GET /api/v1/bookings/:bookingId/tracking` (Screen 06: `OrderTrackingPage`)
Returns current order status, assigned pro & vehicle info, `Service Milestone` timeline events, and the 4-digit `arrivalPinCode`.

### `GET /api/v1/bookings/:bookingId/messages` & `POST /api/v1/bookings/:bookingId/messages` (Screen 07: `ChatPage`)
Lists and sends order-scoped chat messages between the customer and assigned pro.

### `POST /api/v1/bookings/:bookingId/review` (Screen 09: `ReviewPage`)
Submits star rating (`1..5`), multi-select tags, optional comment, photos, and optional tip in EGP for a `COMPLETED` booking.

---

## 5. Customer Profile & Preferences (Screen 10)

### `GET /api/v1/users/me` & `PATCH /api/v1/users/me`
Reads and updates customer profile settings (`preferredLocale`, `arrivalAlertsEnabled`, saved addresses, recent alerts).

---

## 6. Professional Onboarding & Verification (Screens 11–14)

### `POST /api/v1/pro/onboarding/personal` (Screen 11: `ProSignUpPage`)
Saves Step 1 of 4: legal name, synthetic 14-digit National ID, email, primary coverage zone, and `transportMode`.

### `PUT /api/v1/pro/onboarding/skills` (Screen 12: `ProSkillsPage`)
Saves Step 2 of 4: `primaryCategoryId`, `subSkillIds[]`, `experienceTier`, `coverageZoneIds[]`, `acceptsStandardRateCard`, and `toolkitCommitmentConfirmed`.

### `POST /api/v1/pro/onboarding/documents` & `POST /api/v1/pro/onboarding/submit` (Screen 13: `ProVerificationDocsPage`)
Registers synthetic verification document metadata and transitions `ProProfile.verificationStatus` to `PENDING_REVIEW`.

### `GET /api/v1/pro/onboarding/status` (Screen 14: `ProVerificationStatusPage`)
Returns current verification status (`PENDING_REVIEW`, `APPROVED`, `ACTION_REQUIRED`), milestone checklist, dossier summary (`#FX-PRO-9921`), and reviewer notes.

---

## 7. Professional Dashboard & Job Dispatch (Screens 15–16)

### `GET /api/v1/pro/dashboard` (Screen 15: `ProDashboardPage`)
Returns online availability status, active incoming job offer (if any), today's net EGP earnings, weekly KPIs (`weeklyTotalEgp`, `completedJobs`, `acceptanceRatePct`), 7-day bar trajectory (`Sat`–`Fri`), and today's confirmed schedule.

### `PATCH /api/v1/pro/availability` (Screen 15 Toggle)
Updates `isOnline` (`true` / `false`).

### `GET /api/v1/pro/job-offers/:offerId` (Screen 16: `IncomingJobPage`)
Returns countdown expiry (`expiresAt`), gross EGP (`400`), platform fee (`-40`), net artisan pay (`360`), customer summary, diagnostic notes, and distance/route metadata.

### `POST /api/v1/pro/job-offers/:offerId/accept` (Screen 16 Accept)
Atomically locks the job offer for the pro and transitions the booking to `CONFIRMED`.

### `POST /api/v1/pro/job-offers/:offerId/decline` (Screen 16 Decline Modal)
Records decline reason (`ENGAGED_ON_REPAIR`, `DISTANCE_TOO_FAR`, `LACK_EQUIPMENT`) and re-queues the booking for dispatch.


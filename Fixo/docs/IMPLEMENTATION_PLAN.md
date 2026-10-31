# FIXO — Phased Implementation Plan (`docs/IMPLEMENTATION_PLAN.md`)

## Guiding Principles
- **Strict 16-Screen Scope (Live Stitch MCP Only)**: Only implement the 16 official screens from live Stitch project `projects/18114732464114306203` (`Fixo Home Services App`), documented in `docs/LIVE_STITCH_DESIGN.md` and `docs/SCREEN_MAP.md`. Follow the mandatory workflow: `Stitch MCP → Live Design Inspection → Native Flutter Implementation → Testing`.
- **Short, Verifiable Increments**: Every phase must compile cleanly and pass `flutter analyze`, `flutter test`, and backend lint/tests before advancing.
- **Native Flutter Only**: Zero WebViews or raw HTML wrappers; use central `FixoTheme` tokens and reusable widgets.
- **Honest MVP Capabilities**: Start with synthetic demo data and Cash-on-Service; never commit real personal IDs or claim live government/banking integrations prematurely.

---

## Phase 1: Foundation, Architecture Docs, Design System & Screen 01 (Current Phase)
**Goal**: Establish the monorepo foundation, architecture & API/DB specifications, Flutter design system tokens, NestJS starter, and a production-quality native implementation of **Screen 01 (`OnboardingPage`)**.

### Deliverables
- [x] Audit workspace and installed toolchains (Flutter, Dart, Node.js, npm, Git, PostgreSQL/Docker status).
- [x] Inspect all 16 official Stitch screens and design system metadata via Stitch MCP (`projects/18114732464114306203`).
- [x] Author `docs/SCREEN_MAP.md`, `docs/ARCHITECTURE.md`, `docs/IMPLEMENTATION_PLAN.md`, `docs/DATABASE_SCHEMA.md`, and `docs/API_CONTRACT.md`.
- [x] Scaffold Flutter app in `mobile/` with `flutter_riverpod`, `go_router`, `dio`, `intl`, and `flutter_localizations`.
- [x] Implement central Flutter design system (`FixoColors`, `FixoTypography`, `FixoSpacing`, `FixoTheme`, `FixoBrandMark`, `FixoPrimaryButton`, `FixoSecondaryButton`, `FixoTrustChip`).
- [x] Implement **Screen 01 (`01_onboarding` -> `OnboardingPage`)** natively in Flutter with compliant MVP copy, local architectural hero illustration, interactive 3-step preview indicator, and demo route navigation to `/auth/phone`.
- [x] Scaffold NestJS TypeScript backend in `backend/` with Prisma schema (`prisma/schema.prisma`), health controller, validation pipe, Swagger setup, and unit tests.
- [x] Run `flutter analyze`, `flutter test` (including responsive `360dp` / `390dp` / `412dp` and scaled-font widget tests), and backend build/tests.

---

## Phase 2: Authentication Flow (Screen 02) & App Shells
**Goal**: Build the Phone + OTP authentication experience and the reusable Customer/Pro navigation shells.

### Deliverables
- Implement **Screen 02 (`02_phone_auth_otp` -> `PhoneAuthPage`)** with both interactive states (`1. Phone Input` with `+20` Egyptian mobile validation and `2. OTP Code` with 6-digit boxes, countdown timer, and custom/native keypad options).
- Implement NestJS `AuthModule` (`/api/v1/auth/otp/request`, `/api/v1/auth/otp/verify`, `/api/v1/auth/refresh`, `/api/v1/auth/logout`) with development-safe mock OTP provider.
- Build the Customer 4-tab bottom navigation shell (`Home`, `Orders`, `Chat`, `Profile`) and Pro 4-tab navigation shell (`Dashboard`, `Jobs`, `Earnings`, `Profile`).
- Add unit and widget tests for phone validation, OTP state transitions, and auth guards.

---

## Phase 3: Service Discovery & Customer Home (Screen 03) + Profile (Screen 10)
**Goal**: Deliver the customer discovery experience and account settings/role-switching screen.

### Deliverables
- Implement **Screen 03 (`03_customer_home` -> `CustomerHomePage`)**:
  - Top bar with local `FixoBrandMark`, Cairo/Giza zone selector, notification bell, and avatar.
  - Search & filter bar (fixing the duplicated pro rows defect from the Stitch prototype).
  - Seasonal hero promo banner (`Summer AC Deep Clean & Gas Refill — Flat 350 EGP`).
  - 6 Service Category cards (`AC Maintenance`, `Plumbing & Leaks`, `Electrical & Lighting`, `Deep Home Cleaning`, `Carpentry & Repairs`, `Painting & Finishing`).
  - Bundle Save card (`Home Safety Inspection — 450 EGP`) and Top Rated Cairo Professionals list.
- Implement **Screen 10 (`10_profile_notifications` -> `CustomerProfilePage`)**:
  - Customer profile header & stats, `Earn With FIXO Pro` role-switch card (`Register as Pro`), Recent Alerts preview, saved addresses, language switcher (`EN / ع`), and logout action.
- Implement NestJS `CatalogModule` and `UsersModule` endpoints with seeded Cairo/Giza zones, categories, and mock professionals.

---

## Phase 4: Booking Creation (Screen 04) & Cash-First Checkout (Screen 05)
**Goal**: Complete the customer booking creation and checkout pipeline.

### Deliverables
- Implement **Screen 04 (`04_create_booking` -> `CreateBookingPage`)**:
  - Selected service & pro summary card, service location card with Cairo/Giza address selector, dynamic 4-day date picker (generated from current date, replacing hardcoded `Oct 2024`), time window selector (`Morning`, `Afternoon`, `Evening`), issue description + photo attachment slots, and transparent EGP fare breakdown (`400 EGP`).
- Implement **Screen 05 (`05_payment` -> `CheckoutPage`)**:
  - Order summary card, payment method radio stack defaulting to **Cash to Artisan** (`CASH_ON_SERVICE`) as the active MVP payment method, with InstaPay, Smart Wallets, Cards & Meeza, and Fawry clearly badged as sandbox/upcoming options.
- Implement NestJS `BookingsModule` and `PaymentsModule` (`POST /api/v1/bookings`, `POST /api/v1/bookings/:id/checkout`).

---

## Phase 5: Orders, Live Tracking, Chat & Reviews (Screens 06, 07, 08, 09)
**Goal**: Complete the post-booking customer lifecycle and fix all P0 header/artifact defects.

### Deliverables
- Implement **Screen 06 (`06_live_order_tracking` -> `OrderTrackingPage`)**:
  - Correct header title (`Live Tracking`), route map canvas, pro & vehicle card (`White Nissan Sunny`), 5-step `Service Milestone` timeline, order summary, and 4-digit `Artisan Arrival Code`.
- Implement **Screen 07 (`07_customer_chat` -> `ChatPage`)**:
  - Correct header title (`Chat`), pro status bar, order milestone strip, message bubbles (text + sanitized equipment photo card), quick-reply chips (`Gate code is #1402`, `Please ring bell`, `I am at home`),composer bar, and Job Summary bottom sheet.
- Implement **Screen 08 (`08_my_orders` -> `OrdersPage`)**:
  - Clean header (no `PIXEL_4_4XL...` artifact), expandable search bar, segmented tabs (`Active`, `Completed`, `Cancelled`), active job hero card, and completed order cards with current-year dates.
- Implement **Screen 09 (`09_rate_review` -> `ReviewPage`)**:
  - Correct header title (`Rate & Review`), interactive 1–5 star rating widget, multi-select standout tags, written review input, completed work photo slots, and optional bonus tip selector.

---

## Phase 6: Professional Onboarding & Verification Flow (Screens 11, 12, 13, 14)
**Goal**: Build the 4-step craftsman onboarding and verification status tracker.

### Deliverables
- Implement **Screen 11 (`11_pro_sign_up_details` -> `ProSignUpPage`)**: Step 1 of 4 personal details, synthetic demo National ID input (no fake `Gov Check OK` claim), coverage zone, and transport mode (`Motorcycle`, `Work Van`, `Metro / Bus`).
- Implement **Screen 12 (`12_services_skills` -> `ProSkillsPage`)**: Step 2 of 4 primary trade radio cards, specialized sub-skill chips, experience segmented control (`1-2y` to `8+y`), coverage zone pills, rate card toggle, and toolkit commitment checkbox.
- Implement **Screen 13 (`13_id_licenses_upload` -> `ProVerificationDocsPage`)**: Step 3 of 4 synthetic National ID front/back upload cards, criminal record certificate PDF slot (current date), and optional syndicate license dropzone.
- Implement **Screen 14 (`14_verification_status` -> `ProVerificationStatusPage`)**: Interactive 3-state view (`In Review`, `Approved`, `Action Req.`), vetting milestones timeline, application dossier card, and FAQ accordions.

---

## Phase 7: Professional Operations — Dashboard & Incoming Job Request (Screens 15, 16)
**Goal**: Complete the professional operational loop and connect end-to-end customer-to-pro job acceptance.

### Deliverables
- Implement **Screen 15 (`15_pro_dashboard` -> `ProDashboardPage`)**:
  - Pro header + interactive `ONLINE • Dispatch Ready` / `OFFLINE • Paused` toggle.
  - Urgent nearby job match banner, Today's Net Earnings forest card (`1,450 EGP`) with 7-day bar chart (`Sat–Fri`), Today's Schedule cards, and Level 3 Master Artisan progress meter.
- Implement **Screen 16 (`16_incoming_job_request` -> `IncomingJobPage`)**:
  - Circular countdown timer banner, gross (`400 EGP`) vs. net artisan pay (`360 EGP`) card, customer mini-profile & diagnostics, distance/route preview, `ACCEPT JOB` action, and `Decline Job Request` bottom sheet with reason radio options.
- End-to-end integration tests covering Customer Booking -> Pro Job Offer -> Pro Accept -> Live Tracking -> Completion -> Review.


# Fixo — Fixed 16-Screen Scope & Route Map (`docs/SCREEN_MAP.md`)

The UI scope is strictly bounded to the 16 official Stitch screens retrieved via **Google Stitch MCP (`StitchMCP`)**:
- **Official Stitch Project ID**: `projects/18114732464114306203` (`Fixo Home Services App` — *Nilotic Craft & Home*, `#173F35`, `Manrope`)
- **Single Source of Truth**: Fetch all screen HTML, screenshots, and metadata directly from `StitchMCP`. Local exported Stitch folders have been removed.
- **Detailed Live Reference**: See `docs/LIVE_STITCH_DESIGN.md` for live file resource IDs, token mappings, and asset policies.
- **Do Not Use**: Legacy Stitch project `projects/4897897995916433825` (50-screen `#0F766E` / Inter project).

## Customer Flow (`01`–`10`)

| # | Live Stitch Screen ID | Live Screen Title | Flutter Page | GoRouter Path | Feature Module | Shell / Layout | Key Audit Fixes & Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 01 | `5b44b51fafc3426a8875cf13200c5493` | `01 — Onboarding` | `OnboardingPage` | `/onboarding` | `features/onboarding` | Blank (`mobile_blank`) | **Implemented (Phase 1)**. Replaces unsupported insurance/background-check guarantees with neutral MVP copy; replaces hotlinked hero image with `CairoInteriorHeroCard`; uses local `FixoBrandMark`. |
| 02 | `2f0c722b3ccc4030ac95264aaf5df667` | `02 — Phone Auth & OTP` | `PhoneAuthPage` | `/auth/phone` | `features/auth` | Blank (`mobile_blank`) | Two-state interactive flow (`1. Phone Input` and `2. OTP Code`) inside one screen; `+20` Egyptian phone format validation; 6-digit OTP boxes + numeric keypad; neutral security copy. |
| 03 | `ba52cf458e2a49b191b6912ea76117fa` | `03 — Customer Home` | `CustomerHomePage` | `/customer/home` | `features/customer_home` | Customer Tab (`Home`) | Replace broken `FIXO Brand Logo` external `<img>` with local `FixoBrandMark`; remove duplicated pro header rows (lines 10 & 20) above search input in live HTML; 6 service categories, seasonal AC banner, bundle card & top Cairo pros in EGP. |
| 04 | `5d0dc3e1d535411995445a7197129edb` | `04 — Create Booking` | `CreateBookingPage` | `/customer/bookings/new` | `features/booking` | Stack (`mobile_stack`) | Replace hardcoded `October 2024` dates with dynamic relative dates from current clock; neutral guarantee badge; local Cairo/Giza map preview canvas. |
| 05 | `21eead45bf5a46ed8cab6fb62c1348c3` | `05 — Payment` | `CheckoutPage` | `/customer/bookings/:bookingId/checkout` | `features/payment` | Stack (`mobile_stack`) | Default selection to **Cash on Service** (`Cash to Artisan` / `CASH_ON_SERVICE`) for MVP and badge InstaPay, Smart Wallets, Cards/Meeza, and Fawry as sandbox/coming-soon options. |
| 06 | `c8cc293b883e482f996372b7150f40e8` | `06 — Live Order Tracking` | `OrderTrackingPage` | `/customer/orders/:orderId/tracking` | `features/orders` | Stack (`mobile_stack`) | Replace broken brand logo with `FixoBrandMark`; render all 5 milestone steps (`Booking Confirmed` through `Job Completed & Signed`) & 4-digit arrival code (`5841`). |
| 07 | `104e7c1e31454fb786e493cea82afc86` | `07 — Customer Chat` | `ChatPage` | `/customer/orders/:orderId/chat` (and `/customer/chat`) | `features/chat` | Stack / Tab (`Chat`) | Fix wrong `Payment` header in live PNG and live HTML (`<h1>Payment</h1>`) to `Chat`; local equipment illustration; quick-reply chips (`Gate code is #1402`, `Please ring bell`, `I am at home`). |
| 08 | `09caec0ea80942cd996c54f60ae2ef4f` | `08 — My Orders` | `OrdersPage` | `/customer/orders` | `features/orders` | Customer Tab (`Orders`) | Replace `2024` dates with current fixtures; render `Active` / `Completed` / `Cancelled` filter tabs, active order card (`Quality Assured`), and completed order history. |
| 09 | `928489ce07f04b8b97495558b694c1f6` | `09 — Rate & Review` | `ReviewPage` | `/customer/orders/:orderId/review` | `features/reviews` | Stack (`mobile_stack`) | Fix wrong `Payment` header in live PNG and live HTML (`<h1>Payment</h1>`) to `Rate & Review`; replace `Oct 14, 2024` with dynamic order completion date; optional tip as MVP record. |
| 10 | `8b66f066381d44ae81d66ef7acbcf968` | `10 — Profile & Notifications` | `CustomerProfilePage` | `/customer/profile` | `features/profile` | Customer Tab (`Profile`) | Localize/replace avatar; neutral warranty/payout copy; EN/AR language toggle & role switch entry point (`Register as Pro` -> `/pro/onboarding/signup`). |

## Professional / Technician Flow (`11`–`16`)

| # | Live Stitch Screen ID | Live Screen Title | Flutter Page | GoRouter Path | Feature Module | Shell / Layout | Key Audit Fixes & Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 11 | `1bb379a603d147bb826a987edce6bc9f` | `11 — Pro Sign-Up & Details` | `ProSignUpPage` | `/pro/onboarding/signup` | `features/pro_onboarding` | Stack (`Step 1 of 4`) | Use synthetic demo identity data only; remove `Gov Check OK` badge; keep `Flexible Payouts` neutral copy. |
| 12 | `1031cf7b22094bb98f3fffbf4686f214` | `12 — Services & Skills` | `ProSkillsPage` | `/pro/onboarding/skills` | `features/pro_onboarding` | Stack (`Step 2 of 4`) | Primary trade selection (5 trades), sub-skills chips, experience tier (`1-2y`, `3-5y`, `6-8y`, `8+y`), Greater Cairo & Giza coverage zones (6 zones), standard rate card toggle (`350 - 450 EGP`). |
| 13 | `55f0714919644190a587b5fc2d05e79f` | `13 — ID & Licenses Upload` | `ProVerificationDocsPage` | `/pro/onboarding/documents` | `features/pro_onboarding` | Stack (`Step 3 of 4`) | Synthetic specimen placeholders only (never commit real IDs); replace `fish_geena2y_2024.pdf` hardcoded year; remove fake `99.4%` AI/OCR biometric match claims. |
| 14 | `55499bed0daa4a338b166e95927a59f8` | `14 — Verification Status` | `ProVerificationStatusPage` | `/pro/onboarding/status` | `features/pro_onboarding` | Stack (`Stage 3/4`) | Supports 3 explicit states (`In Review` / `PENDING_REVIEW`, `Approved` / `APPROVED`, `Action Req.` / `ACTION_REQUIRED`) with interactive preview switcher for demo inspection. |
| 15 | `d6d3d257cc634ce3ad304818f759a0d4` | `15 — Pro Dashboard` | `ProDashboardPage` | `/pro/dashboard` | `features/pro_dashboard` | Pro Tab (`Dashboard`) | Online/Offline dispatch toggle, nearby job alert banner (`400 EGP`), net earnings summary (`1,450 EGP`), 7-day weekly trajectory bar chart (`Sat–Fri`), today's schedule, 4-tab Pro bottom nav. |
| 16 | `2f83a9b4aa0541ed9c1fc6f7bd07265b` | `16 — Incoming Job Request` | `IncomingJobPage` | `/pro/jobs/:jobId/incoming` | `features/pro_jobs` | Stack (`mobile_stack`) | 45s countdown timer, gross (`400 EGP`) vs. net (`360 EGP`) breakdown (`-40 EGP` 10% platform fee), customer summary (`Salma E.`), route card, `Accept Job` & `Decline Request` reason modal sheet. |

## Architecture & Localization Notes
- The live Stitch UI is English/Light; Flutter is architected to support **Arabic (`ar`) / RTL** and **Dark Mode** centrally via `FixoTheme` and `AppLocalizations` without duplicating the 16 screen widgets.
- Treat live Stitch screenshots and HTML files as visual specifications, not runtime image hosts or executable proof of external integrations.

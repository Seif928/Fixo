# FIXO — Live Stitch MCP Design Reference (`docs/LIVE_STITCH_DESIGN.md`)

Last verified via live `StitchMCP`: **2026-10-31**

> **Single Source of Truth Policy**: Google Stitch MCP (`StitchMCP`) is the **only** approved UI/UX design source for FIXO. Obsolete local exported HTML and screenshot folders have been removed from the repository. Never rely on manual ZIP exports; always fetch live screen metadata, HTML, and screenshots directly through `StitchMCP` using the official project ID and screen IDs below.

---

## 1. Official Stitch Project Identity & Workflow

| Property | Verified Live Value |
| :--- | :--- |
| **Official Project ID** | `projects/18114732464114306203` |
| **Project Title** | `Fixo Home Services App` |
| **Design System Name** | `Nilotic Craft & Home` (`assets/7f245f47c92a4bf080d50b3e1a02cf4a`) |
| **Project Type / Device** | `TEXT_TO_UI_PRO` · `MOBILE` (`390dp` logical width / `780px` @ 2x) |
| **Color Mode & Variant** | `LIGHT` · `FIDELITY` |
| **Primary Brand Color** | `#173F35` (`primary-container` / Deep Forest) · `#002920` (`primary` / Deepest Forest) |
| **Secondary / Accent Colors** | `#245B4B` / `#326857` (Secondary Forest) · `#D5EE76` / `#D7F078` (Fresh Lime Accent) |
| **Typography** | `Manrope` (Headline, Body, Label, Price Display — tabular numerals) |
| **Roundness** | `ROUND_EIGHT` (`8px` base controls, `12px` inner panels, `16px` cards, `24px` sheets, `9999px` pills) |
| **Total Verified Screens** | **16** (`01 — Onboarding` through `16 — Incoming Job Request`) |
| **Deprecated Project (DO NOT USE)** | `projects/4897897995916433825` *(Legacy 50-screen `#0F766E` / Inter project — strictly excluded)* |

### Mandatory Design-to-Code Workflow
```text
Stitch MCP → Live Design Inspection → Native Flutter Implementation → Testing
```
1. **Stitch MCP**: Call `list_screens`, `get_screen`, and `download_file` on `StitchMCP` for `projects/18114732464114306203` to retrieve the latest HTML, screenshot, and design tokens.
2. **Live Design Inspection**: Inspect every section, component, color token, and text string in the live Stitch screen before writing Flutter code.
3. **Native Flutter Implementation**: Build clean, responsive native Flutter widgets using `FixoTheme`, Riverpod, GoRouter, and Dio (no WebViews, no runtime hotlinks).
4. **Testing**: Run `flutter pub get`, `flutter analyze`, `flutter test` (`360dp` / `390dp` / `412dp` viewports, `1.35x` text scale, English LTR & Arabic RTL), and backend tests.

---

## 2. Verified 16-Screen Live Mapping & Route Inventory

All 16 screens are retrieved directly from `projects/18114732464114306203` via `StitchMCP`.

### 2.1 Customer Flow (`01`–`10`)

| # | Live Stitch Title | Live Stitch Screen ID | Live HTML Resource (`htmlCode.name`) | Live Screenshot Resource (`screenshot.name`) | Flutter Page & GoRouter Path | Shell Type |
| :- | :--- | :--- | :--- | :--- | :--- | :--- |
| **01** | `01 — Onboarding` | `5b44b51fafc3426a8875cf13200c5493` | `projects/18114732464114306203/screens/5b44b51fafc3426a8875cf13200c5493/fileEntries/html` | `.../screens/5b44b51fafc3426a8875cf13200c5493/fileEntries/screenshot` (`image/png`, `780×1844`) | `OnboardingPage`<br>`/onboarding` | `mobile_blank` |
| **02** | `02 — Phone Auth & OTP` | `2f0c722b3ccc4030ac95264aaf5df667` | `projects/18114732464114306203/screens/2f0c722b3ccc4030ac95264aaf5df667/fileEntries/html` | `.../screens/2f0c722b3ccc4030ac95264aaf5df667/fileEntries/screenshot` (`image/png`, `780×1768`) | `PhoneAuthPage`<br>`/auth/phone` | `mobile_blank` |
| **03** | `03 — Customer Home` | `ba52cf458e2a49b191b6912ea76117fa` | `projects/18114732464114306203/files/6187654117208055653` | `.../files/11344517335127910457` (`image/jpeg`, `390×2463`) | `CustomerHomePage`<br>`/customer/home` | `mobile_tab`<br>(`Home`) |
| **04** | `04 — Create Booking` | `5d0dc3e1d535411995445a7197129edb` | `projects/18114732464114306203/screens/5d0dc3e1d535411995445a7197129edb/fileEntries/html` | `.../screens/5d0dc3e1d535411995445a7197129edb/fileEntries/screenshot` (`image/png`, `780×3374`) | `CreateBookingPage`<br>`/customer/bookings/new` | `mobile_stack` |
| **05** | `05 — Payment` | `21eead45bf5a46ed8cab6fb62c1348c3` | `projects/18114732464114306203/files/1182845280193114026` | `.../files/1182845280193111149` (`image/jpeg`, `390×1311`) | `CheckoutPage`<br>`/customer/bookings/:bookingId/checkout` | `mobile_stack` |
| **06** | `06 — Live Order Tracking` | `c8cc293b883e482f996372b7150f40e8` | `projects/18114732464114306203/files/18335865377512432963` | `.../files/12260342496205452783` (`image/jpeg`, `390×1402`) | `OrderTrackingPage`<br>`/customer/orders/:orderId/tracking` | `mobile_stack` |
| **07** | `07 — Customer Chat` | `104e7c1e31454fb786e493cea82afc86` | `projects/18114732464114306203/screens/104e7c1e31454fb786e493cea82afc86/fileEntries/html` | `.../screens/104e7c1e31454fb786e493cea82afc86/fileEntries/screenshot` (`image/png`, `780×2228`) | `ChatPage`<br>`/customer/orders/:orderId/chat` | `mobile_stack` / Tab (`Chat`) |
| **08** | `08 — My Orders` | `09caec0ea80942cd996c54f60ae2ef4f` | `projects/18114732464114306203/files/15493188327554533432` | `.../files/11920089209832160464` (`image/jpeg`, `390×1641`) | `OrdersPage`<br>`/customer/orders` | `mobile_tab`<br>(`Orders`) |
| **09** | `09 — Rate & Review` | `928489ce07f04b8b97495558b694c1f6` | `projects/18114732464114306203/screens/928489ce07f04b8b97495558b694c1f6/fileEntries/html` | `.../screens/928489ce07f04b8b97495558b694c1f6/fileEntries/screenshot` (`image/png`, `780×2996`) | `ReviewPage`<br>`/customer/orders/:orderId/review` | `mobile_stack` |
| **10** | `10 — Profile & Notifications` | `8b66f066381d44ae81d66ef7acbcf968` | `projects/18114732464114306203/screens/8b66f066381d44ae81d66ef7acbcf968/fileEntries/html` | `.../screens/8b66f066381d44ae81d66ef7acbcf968/fileEntries/screenshot` (`image/png`, `780×3336`) | `CustomerProfilePage`<br>`/customer/profile` | `mobile_tab`<br>(`Profile`) |

### 2.2 Professional / Technician Flow (`11`–`16`)

| # | Live Stitch Title | Live Stitch Screen ID | Live HTML Resource (`htmlCode.name`) | Live Screenshot Resource (`screenshot.name`) | Flutter Page & GoRouter Path | Shell Type |
| :- | :--- | :--- | :--- | :--- | :--- | :--- |
| **11** | `11 — Pro Sign-Up & Details` | `1bb379a603d147bb826a987edce6bc9f` | `projects/18114732464114306203/files/1277131144460629691` | `.../files/17105119568858126080` (`image/jpeg`, `390×1304`) | `ProSignUpPage`<br>`/pro/onboarding/signup` | `mobile_stack`<br>(`Step 1 of 4`) |
| **12** | `12 — Services & Skills` | `1031cf7b22094bb98f3fffbf4686f214` | `projects/18114732464114306203/screens/1031cf7b22094bb98f3fffbf4686f214/fileEntries/html` | `.../screens/1031cf7b22094bb98f3fffbf4686f214/fileEntries/screenshot` (`image/png`, `780×4220`) | `ProSkillsPage`<br>`/pro/onboarding/skills` | `mobile_stack`<br>(`Step 2 of 4`) |
| **13** | `13 — ID & Licenses Upload` | `55f0714919644190a587b5fc2d05e79f` | `projects/18114732464114306203/screens/55f0714919644190a587b5fc2d05e79f/fileEntries/html` | `.../screens/55f0714919644190a587b5fc2d05e79f/fileEntries/screenshot` (`image/png`, `780×3082`) | `ProVerificationDocsPage`<br>`/pro/onboarding/documents` | `mobile_stack`<br>(`Step 3 of 4`) |
| **14** | `14 — Verification Status` | `55499bed0daa4a338b166e95927a59f8` | `projects/18114732464114306203/files/12812350320353846251` | `.../files/3358581065073206072` (`image/jpeg`, `390×1445`) | `ProVerificationStatusPage`<br>`/pro/onboarding/status` | `mobile_stack`<br>(`Stage 3/4`) |
| **15** | `15 — Pro Dashboard` | `d6d3d257cc634ce3ad304818f759a0d4` | `projects/18114732464114306203/files/83835044438894261` | `.../files/153559010348877441` (`image/jpeg`, `390×1484`) | `ProDashboardPage`<br>`/pro/dashboard` | `mobile_tab`<br>(`Dashboard`) |
| **16** | `16 — Incoming Job Request` | `2f83a9b4aa0541ed9c1fc6f7bd07265b` | `projects/18114732464114306203/files/12355502674182673147` | `.../files/14818214165936677608` (`image/jpeg`, `390×1196`) | `IncomingJobPage`<br>`/pro/jobs/:jobId/incoming` | `mobile_stack` |

---

## 3. Detailed Live Screen Specifications (Screens 01–16)

### 3.1 Screen 01 — `01 — Onboarding` (`5b44b51fafc3426a8875cf13200c5493`)
- **Live Stitch Design**:
  1. **Brand Header**: `32×32` `#173F35` rounded-lg icon box with `#D5EE76` `handyman` icon, `FIXO` (`18px` extra-bold `#173F35`), subtitle `Better Homes. Better Everyday.`, right-aligned pill `Cairo & Giza Verified` (`bg-surface-container-high` `#DFEBE4` with `#326857` dot).
  2. **Hero Visual Showcase**: `288px` (`h-72`) rounded-xl sunlit Zamalek apartment photo with bottom-to-top `#002920` gradient scrim, top-left floating pill (`Tier-1 Certified Artisans`), and bottom floating availability card (`142 Pros On Call`, `Maadi • New Cairo • Zamalek • Zayed`, pulsing `#D5EE76` dot, and `~18 min` bolt badge).
  3. **Editorial Headline & Copy**: Uppercase shield badge `THE STANDARD IN HOME CARE`, `<h1>Your home, in better hands.</h1>` (`26px/34px` bold `#002920`), and descriptive body copy.
  4. **Trust Value Pillars**: 3 white elevated chips (`100% Background Checked`, `Fixed EGP Quotes`, `Live Arrival Tracking`).
  5. **Step Milestone Bar**: `#E5F1EA` (`surface-container`) card with `Step 1 of 3: Verification Overview`, `30 sec onboarding`, and 3 progress bars (bar 1 `#D5EE76`, bars 2–3 `#DAE5DF`).
  6. **Action CTAs & Footer**: Primary `#173F35` button `Get Started` with circular `#D5EE76` arrow badge; secondary `#FFFFFF` button `I already have an account`; footer note with lock icon.
- **Flutter Implementation Status (`mobile/lib/features/onboarding/`)**:
  - **Implemented & Verified**: `OnboardingPage` and `CairoInteriorHeroCard` match the live Stitch visual hierarchy, colors, typography, and component geometry 1:1 while using the local custom-painted `CairoInteriorHeroCard` and compliant MVP copy (`Cairo & Giza Active`, `Skilled Local Artisans`, `Identity-Reviewed Pros`, `Upfront EGP quotes • Cash on service available in Cairo & Giza`).

### 3.2 Screen 02 — `02 — Phone Auth & OTP` (`2f0c722b3ccc4030ac95264aaf5df667`)
- **Live Stitch Design**:
  - Single-page, two-state interactive flow (`section-phone` and `section-otp`) controlled by a top segmented pill switcher (`1. Phone Input` / `2. OTP Code`) and inline action buttons (`Continue` / `Edit`).
  - **Shared Editorial Header**: Centered `48×48` (`w-12 h-12`) `#173F35` rounded-xl container with `#D5EE76` `home_repair_service` icon, `<h1>Welcome to FIXO</h1>` (`26px` bold), and subtitle `Enter your Egyptian mobile number to sign in or register.`
  - **State 1 (`1. Phone Input`)**:
    - White card (`bg-surface-container-lowest rounded-xl p-5`) containing:
      - Label `Egyptian Mobile Number`
      - `#173F35` country prefix badge (`h-12 px-3.5 rounded-lg`) with 3-stripe Egypt flag motif (`#C8102E`, `#FFFFFF` + `#C09300` eagle dot, `#000000`) and `+20` label.
      - Phone text field (`h-12 bg-surface-container-low rounded-lg`, value/placeholder `010 2345 6789`, trailing `cancel` clear icon button).
      - Quick benefits strip (`bg-surface-container-low rounded-lg`): `bolt` `Instant SMS code` • `lock_reset` `No password required`.
    - Primary CTA button (`h-12 bg-primary-container text-on-primary`): `Continue` + `arrow_forward`.
    - Neighborhood credibility card (`bg-surface-container-low rounded-xl p-4`): `verified_user` icon box + `Verified Pro Network` (`Maadi • Zamalek • New Cairo • Sheikh Zayed`).
    - Visual lifestyle mood anchor (`h-28 rounded-xl` with `#002920` gradient overlay): `handyman` icon + `Over 2,400 certified Cairo craftsmen ready for booking`.
  - **State 2 (`2. OTP Code`)**:
    - White verification card (`bg-surface-container-lowest rounded-xl p-5`):
      - Header label `Verification Code`, `Sent 6-digit code to +20 102 345 6789`, and `Edit` pill button (`bg-surface-container-low`) that returns to State 1.
      - **6 Individual OTP Digit Boxes (`w-12 h-14 rounded-lg`)**: Boxes 1–3 filled (`4`, `8`, `2` in `22px` extra-bold tabular figures); Box 4 active cursor state (`bg-gradient-to-b from-tertiary-fixed/30 to-tertiary-fixed/10`, pulsing `#002920` cursor bar, bottom `#D5EE76` pill indicator); Boxes 5–6 empty placeholder dashes.
      - Resend row: `schedule` icon + `Resend code in 00:42` and `Resend SMS` action button.
    - Trust badge strip (`bg-surface-container-high rounded-xl p-3.5`): `Protected by 256-bit encryption • 24/7 Cairo Support`.
    - High-energy lime CTA (`h-12 bg-tertiary-fixed text-primary-container font-bold`): `check_circle` + `Verify & Access Account`.
    - Tactile 3×4 numeric keypad card (`bg-surface-container-lowest rounded-2xl p-3`) with keys `1–9`, `emergency`, `0`, and `backspace`.
  - **Shared Footer**: `By continuing, you agree to FIXO's Terms of Service and Privacy Policy.`

### 3.3 Screen 03 — `03 — Customer Home` (`ba52cf458e2a49b191b6912ea76117fa`)
- **Verified Purpose in Live Stitch**:
  - Screen 03 is the **Customer Service Discovery & Marketplace Home** screen (`CustomerHomePage`, route `/customer/home`, shell `mobile_tab` with `Home` active in the 4-tab Customer bottom navigation bar).
- **Live Stitch Sections (Top to Bottom)**:
  1. **Fixed Top App Bar (`h-16`)**: Brand mark + `FIXO` label + `Cairo / Giza` location selector on the left; notification bell button + customer profile avatar on the right.
  2. **Location Pill & Search Bar**:
     - District selector pill (`Sheikh Zayed, Dist. 9` with `location_on` and `expand_more`).
     - Search input (`Search electrical, plumbing, AC repair...`) with trailing `tune` filter icon button.
     - *Live HTML prototype defect*: Lines 10 and 20 of the live HTML accidentally duplicate the inner flex rows for `Eng. Tarek Mansour` (`250 EGP`) and `Hassan El-Sayed` (`350 EGP`) directly inside the header/search flex containers. In Flutter, only the clean location selector row and search input bar should render here.
  3. **Hero Seasonal Promo Card (`bg-primary-container rounded-2xl p-5`)**:
     - Top badges: `SEASONAL PEAK` (`bg-tertiary-fixed text-tertiary`) and `Daikin & Carrier Pros` (`verified` icon).
     - Title: `Summer AC Deep Clean & Gas Refill`.
     - Description: `Complete coil flush, antibacterial sanitized mist, and pressure gauge test.`
     - Bottom price & CTA row: `Flat 350 EGP` (`24px` extra-bold `#D5EE76`) + `Book Now ->` lime button.
  4. **Service Categories Grid (`Select Service Category` + `6 Ready` badge + `View All` button)**:
     - 2-column grid of 6 white category tiles (`h-36 rounded-2xl`):
       1. `AC Maintenance` (`mode_fan`, `~450 EGP`, `Inverter, split & duct`)
       2. `Plumbing & Leaks` (`plumbing`, `~280 EGP`, `Pipes, heaters & traps`)
       3. `Electrical & Lighting` (`bolt`, `~250 EGP`, `Breakers, wiring & LED`)
       4. `Deep Home Cleaning` (`cleaning_services`, `~600 EGP`, `Post-renovation & villas`)
       5. `Carpentry & Repairs` (`handyman`, `~320 EGP`, `Hinges, locks & bespoke`)
       6. `Painting & Finishing` (`format_paint`, `~850 EGP`, `Jotun primed coatings`)
  5. **Bundle Save Card (`bg-surface-container-high rounded-2xl p-4`)**:
     - `#173F35` icon box (`health_and_safety` in `#D5EE76`), `BUNDLE SAVE` lime tag, `Home Safety Inspection`, subtitle `Complete Electrical & Plumbing dual audit`, price `450 EGP`.
  6. **Top Rated Cairo Professionals (`Explore` link)**:
     - Pro Card 1: `Eng. Tarek Mansour` (`Master Electrician • New Cairo & Maadi`, `★ 4.9 (184 reviews)`, `Est. 250 EGP`, `Verified Master Pro` pill, `#173F35` `Book Slot` button).
     - Pro Card 2: `Hassan El-Sayed` (`AC Specialist • Sheikh Zayed & Dokki`, `★ 4.95 (240 reviews)`, `Est. 350 EGP`, `Fast Responder (<15m)` mint pill, `#173F35` `Book Slot` button).
  7. **Residential Facility Concierge Card (`bg-surface-container rounded-2xl p-4`)**:
     - `support_agent` icon + `Need a custom enterprise quote?` / `Talk with a residential facility manager` + circular `chevron_right` button.
  8. **Customer Bottom Navigation Bar (`h-16`)**:
     - 4 tabs: `Home` (`home`, active), `Orders` (`receipt_long`), `Chat` (`chat_bubble`), `Profile` (`account_circle`).

### 3.4 Summary of Screens 04–16 (Live Stitch Verification)
- **Screen 04 (`04 — Create Booking`)**: `Step 1 of 2` header, selected service summary (`Split AC Deep Cleaning & Chemical Wash`, `Eng. Hassan El-Sayed`, `★ 4.95`), `Service Location` map preview (`Palm Hills Villa 14`, `Apartment 4B, Building 14`), `Select Date` 4-day horizontal date selector, `Preferred Time Window` radio cards (`Morning 09:00–12:00`, `Afternoon 01:00–04:00` selected with lime radio dot, `Evening 05:00–08:00`), `Issue Description` textarea + photo upload tiles, `Fare Breakdown` (`150 EGP` base + `250 EGP` chemical wash + `WAIVED 0 EGP` transport = `400 EGP`), sticky bottom bar (`Bookmark` icon button + `Proceed to Payment • 400 EGP`).
- **Screen 05 (`05 — Payment`)**: Verified service summary card (`AC Deep Cleaning & Wash`, `400 EGP`, `Beverly Hills, Sheikh Zayed`, `FIXO Free 7-Day Protection Included`), `Payment Method` radio list (`InstaPay Egypt` with IPA input `@ tarek.aly@instapay`, `Smart Wallets`, `Cards & Meeza`, `Fawry Pay Kiosk`, `Cash to Artisan`), `Receipt Breakdown` (`400 EGP`), sticky bottom CTA (`Due Now 400 EGP` + `Confirm & Pay 400 EGP`).
- **Screen 06 (`06 — Live Order Tracking`)**: Map hero with route line (`Arriving in 14 mins`, `Palm Hills Villa 42, Zayed`, `38 km/h • 2.4 km away`), technician card (`Eng. Hassan El-Sayed`, `Master Pro`, vehicle plate `ب ق د ٤٨٢١`, `Call Pro` & `Message (1)` buttons), `Service Milestone` vertical stepper (`Booking Confirmed`, `Artisan Dispatched`, `On the Way LIVE`, `Diagnostic & Service`, `Job Completed & Signed`), `Order Summary #FX-8842` (`400 EGP`), dark green `Artisan Arrival Code` card (`5841`), safety helpdesk & `Cancel Booking` links.
- **Screen 07 (`07 — Customer Chat`)**: Technician sub-header (`Hassan El-Sayed`, `MASTER`, `Online • Typically replies in 1m`, call & info buttons), floating order context pill (`#FX-8842 • Palm Hills`, `AC Deep Cleaning`, `400 EGP`, `Arriving ~1:45 PM`), message bubbles with timestamps & read receipts, photo attachment bubble (`Sanitized Equipment`), live location event notice (`Hassan passed Palm Hills Main Avenue`), horizontal quick-reply chips (`Gate code is #1402`, `Please ring bell`, `I am at home`), bottom message composer (`+`, input, mic, send button).
- **Screen 08 (`08 — My Orders`)**: Header (`My Orders`, `Cairo & Giza Scheduled Services`, search & filter buttons), 3-tab segmented control (`Active 1`, `Completed 4`, `Cancelled 0`), `Active Job` card (`In Progress • Arriving in 14m`, `#FX-8842`, `AC Deep Cleaning & Chemical Wash`, `Eng. Hassan El-Sayed`, `400 EGP`, `Quality Assured` pill, mini map banner, `Track Live`, chat & call buttons), `Past Completed Work` list (`Master Electrician 350 EGP`, `Plumbing & Water Heater Maintenance 280 EGP`, `Master Carpentry & Door Alignment 520 EGP` with `Invoice` & `Rebook` buttons), `FIXO 30-Day Guarantee` card, 4-tab Customer bottom nav (`Orders` active).
- **Screen 09 (`09 — Rate & Review`)**: Completion check badge, `How was Hassan's service?`, service summary card (`Hassan El-Sayed`, `400 EGP`, `AC Deep Chemical Wash`), interactive 5-star rating selector (`Outstanding Experience! (5.0)`), multi-select compliment chips (`Punctual & On Time`, `Super Clean Work`, `Polite & Professional`, `Equipped with Pro Tools`, `Quick Diagnosis`, `Followed Safety Rules`, `Transparent Pricing`), written review box (`164/500`), `Photos of Completed Work` (`Clean Coil` thumbnail + `Add Photo` slots), `Add a bonus tip for Hassan?` (`20 EGP`, `50 EGP`, `100 EGP` selected, `Custom`), sticky bottom CTA (`Submit Review & Tip • 500 EGP total`).
- **Screen 10 (`10 — Profile & Notifications`)**: Customer profile card (`Salma El-Shazly`, `+20 10 2345 6789`, `FIXO Gold • 8 Bookings`, stats row: `Completed 8`, `Saved Hours 34h`, `Reward Pts 1,420`), dark green partner acquisition banner (`EARN WITH FIXO PRO — Are you a certified craftsman or artisan?` + lime `Register as Pro ->` button), `Recent Alerts` (`Hassan is en route` with `Live Map` & `Call Pro`, `Autumn AC Pre-Winter Prep`), `MANAGE & DETAILS` (`Saved Addresses`, `Payments & InstaPay`, `Arrival Alerts` switch), `PREFERENCES & GUARANTEE` (`App Language EN / ع`, `FIXO Protection Guarantee`, `Cairo & Giza Concierge`), `Log Out of Salma's Account` button, 4-tab Customer bottom nav (`Profile` active).
- **Screen 11 (`11 — Pro Sign-Up & Details`)**: `STEP 1 OF 4` progress bar, `Join Cairo's Elite Craftsmen Network`, `National Identity Photo` upload card, form inputs (`Full Legal Name`, `Egyptian Mobile Number` with `+20` & `SMS Verified`, `National ID (14 Digits)` with Arabic label `الرقم القومي`, `Email Address`, `Primary Residential Hub & Coverage Zone` dropdown `Giza — Sheikh Zayed / 6th of October`), 3-column `Primary Transportation for Site Visits` selector (`Motorcycle` active, `Work Van`, `Metro / Bus`), `Flexible Payouts` info card (`0% Fees`), sticky bottom CTA (`Continue to Skills & Trade`).
- **Screen 12 (`12 — Services & Skills`)**: `STEP 2 OF 4` (`50% Completed`), `What is your primary trade?`, 5 trade specialty radio cards (`HVAC & Air Conditioning` active with lime check, `Plumbing & Sanitary`, `Electrical & Wiring`, `Carpentry & Doors`, `Painting & Finishing`), `Specialized Sub-skills & Badges` toggle chips (3 active in dark forest + 3 inactive), `Years of Active Experience` 4-tier selector (`1-2y`, `3-5y`, `6-8y`, `8+y` active), `Service Coverage Zones` map banner + 6 neighborhood checkboxes (`Sheikh Zayed City`, `6th of October`, `Dokki & Mohandessin`, `Zamalek`, `New Cairo & 5th Stl.`, `Maadi & Degla`), `FIXO Standard Rate Card` switch (`350 - 450 EGP`), `Professional Toolkit Commitment` checkbox, sticky bottom CTA (`Continue to ID Upload • Step 3 ->`).
- **Screen 13 (`13 — ID & Licenses Upload`)**: `Step 3 of 4`, `Verify your Egyptian National ID`, `Fast-Track Verification Active` banner, `National ID — Front` (`الرقم القومي - الوجه الأمامي`) card with scanned preview & `Replace Photo`, `National ID — Back` (`الرقم القومي - الوجه الخلفي`) card with barcode preview, `Criminal Record Certificate` (`صحيفة الحالة الجنائية - الفيش الجنائي`, `Required`) PDF upload card, `Syndicate & Vocational License` (`نقابة التطبيقيين أو شهادة قياس مهارة`, `Optional (+15% higher bookings)`) upload zone, `Bank-Grade 256-bit AES Encryption` notice, sticky bottom CTA (`Submit for Verification`).
- **Screen 14 (`14 — Verification Status`)**: Interactive 3-state preview switcher (`In Review`, `Approved`, `Action Req.`), State 1 (`Application Under Verification`, `Stage 3 of 4 Processing`, queue `#14`, `Vetting Milestones` 4-step vertical timeline, `Application Dossier #FX-PRO-9921`), State 2 (`Welcome to FIXO Pro!`, `Verified Master Artisan`, `Go to Pro Dashboard` CTA), State 3 (`National ID Resubmission`, `Upload New Front ID Photo` CTA), expandable FAQ accordions, `Need Onboarding Help?` WhatsApp/Hotline card, bottom action buttons (`Check Status Refresh`, `Back to Home Dashboard`).
- **Screen 15 (`15 — Pro Dashboard`)**: Top bar (`Dashboard`), pro status header (`Eng. Hassan El-Sayed`, `Master Pro` lime pill, `★ 4.95 · 240 jobs completed`, `ONLINE • Dispatch Ready` switch), urgent `New Job Match Nearby!` card (`AC Capacitor Failure & Tune`, `400 EGP`, `Accept Job (400 EGP)` lime button & `Decline`), dark green `TODAY'S NET EARNINGS` card (`1,450 EGP`, `+320 EGP vs yesterday`, `Request Payout / Withdraw`, stats boxes: `Weekly Total 8,750 EGP`, `Completed 18 Jobs`, `Acceptance 96%`, 7-day `Weekly Earnings Trajectory` bar chart `Sat–Fri` with `Thu` highlighted in lime), `Today's Schedule` (`02:00 PM Split AC Chemical Wash & Gas Refill 400 EGP` with `Start Journey`, `04:30 PM Inverter Diagnostic Inspection 250 EGP`), `Level 3 Master Artisan` progress bar (`18 / 20`), 3 quick-action tiles (`Order History`, `Price Guide`, `Safety SOS`), 4-tab Pro bottom nav (`Dashboard`, `Jobs`, `Earnings`, `Profile`).
- **Screen 16 (`16 — Incoming Job Request`)**: Dark green `INSTANT DISPATCH — New Job Match` banner with `Auto-expires in 00:45` countdown, `GROSS JOB PRICE` card (`400 EGP`, `Net Artisan Pay 360 EGP`, `After 10% platform protection -40 EGP`), homeowner & job card (`Salma E.`, `FIXO Gold`, `★ 5.0 · 8 Cairo bookings`, `Split AC Deep Cleaning & Chemical Wash · 1 Unit`, `Est. Duration 45 - 60 mins`, `Location Living Room (2.5 HP)`, `Homeowner Diagnostics` quote block), `Distance & Route` map card (`2.4 km (~8 mins drive)`, `Palm Hills Developments, Zone 4`, `Villa 42, Private Gate 3`), `Artisan Support Active` card, high-energy lime `ACCEPT JOB — TAP TO DISPATCH ->` button + `Decline Request` button (opens slide-up decline reason modal sheet in HTML).

---

## 4. Shared Design Tokens (Live Stitch vs. `FixoTheme`)

The live Stitch project defines tokens in the screen Tailwind configuration (`tailwind.config`) and the project's `designTheme.designMd`. Both are reconciled in `mobile/lib/core/theme/`:

### 4.1 Color Tokens (`FixoColors` & `FixoPaletteExtension`)

| Token Name | Live Tailwind Hex | Live `designMd` Narrative Hex | Flutter `FixoColors` Constant | Primary Usage |
| :--- | :--- | :--- | :--- | :--- |
| `primary` | `#002920` | — | `FixoColors.deepestForest` | High-emphasis primary headlines, dark surfaces |
| `primary-container` | `#173F35` | `#173F35` (Deep Forest) | `FixoColors.primaryForest` | Core brand anchor, primary buttons, active tabs, dark hero cards |
| `secondaryForest` | — | `#245B4B` | `FixoColors.secondaryForest` | Button press/hover states, secondary forest accents |
| `secondary` | `#326857` | `#326857` | `FixoColors.secondary` | Verified badges, status icons, secondary interactive labels |
| `secondary-container` | `#B3ECD6` | `#B3ECD6` | `FixoColors.secondaryContainer` | Mint status pills (`Fast Responder`, `Paid via InstaPay`, `Quality Assured`) |
| `on-secondary-container` | `#366C5B` | `#366C5B` | `FixoColors.onSecondaryContainer` | Foreground text/icons inside mint status pills |
| `tertiary-fixed` | `#D5EE76` | `#D7F078` (Fresh Lime) | `FixoColors.limeAccent` / `limeHighlight` | High-energy CTAs (`Book Now`, `Accept Job`), active toggles, highlights |
| `on-tertiary-fixed` | `#171E00` | `#173F35` | `FixoColors.onTertiaryFixed` | High-contrast dark text on lime surfaces (WCAG AAA) |
| `surface` / `background` | `#F1FCF5` | `#F7F5EF` (Warm Cream) | `FixoColors.surfaceBotanical` / `warmCream` | Screen scaffold background canvas |
| `surface-container-lowest` | `#FFFFFF` | `#FFFFFF` | `FixoColors.surfaceContainerLowest` | Elevated content cards, input fields, bottom sheets |
| `surface-container-low` | `#EBF6EF` | `#EBF6EF` | `FixoColors.surfaceContainerLow` | Recessed input backgrounds, inner card panels |
| `surface-container` | `#E5F1EA` | `#E5F1EA` | `FixoColors.surfaceContainer` | Step milestone containers, segmented control tracks |
| `surface-container-high` | `#DFEBE4` | `#DFEBE4` | `FixoColors.surfaceContainerHigh` | Neutral pills, icon containers, secondary badges |
| `surface-container-highest` | `#DAE5DF` | `#DAE5DF` | `FixoColors.surfaceContainerHighest` | Inactive progress segments, avatar placeholders |
| `on-surface` | `#141E1A` | `#19231F` (Dark Ink) | `FixoColors.onSurface` / `ink` | Primary body and title typography |
| `on-surface-variant` | `#414845` | `#78817A` (Muted Text) | `FixoColors.onSurfaceVariant` / `mutedText` | Captions, subtitles, timestamps |
| `outline` / `outline-variant` | `#717975` / `#C0C8C4` | `#E7E8DF` (Soft Border) | `FixoColors.outline` / `softBorder` | 1px card borders, dividers, input outlines |
| `coral` / `error` | `#BA1A1A` | `#FF795F` (Warm Coral) | `FixoColors.error` / `coral` | Destructive actions, countdown warnings, Safety SOS |

### 4.2 Typography Scale (`FixoTypography`)

- **Font Families**: `Manrope` for English (`en`, LTR); `Cairo` for Arabic (`ar`, RTL).
- **Tabular Figures (`FontFeature.tabularFigures()`)**: Applied to all EGP prices, ratings, countdown timers, and OTP inputs.

| Style Token | Size / Line Height | Weight | Letter Spacing | Flutter Method |
| :--- | :--- | :--- | :--- | :--- |
| `display` | `48px / 56px` | `800` (ExtraBold) | `-0.03em` (`-1.44px`) | `FixoTypography.display()` |
| `display-mobile` | `36px / 44px` | `800` (ExtraBold) | `-0.02em` (`-0.72px`) | `FixoTypography.displayMobile()` |
| `headline-lg` | `32px / 40px` | `700` (Bold) | `-0.02em` (`-0.64px`) | `FixoTypography.headlineLg()` |
| `headline-lg-mobile` | `26px / 34px` | `700` (Bold) | `-0.015em` (`-0.39px`) | `FixoTypography.headlineLgMobile()` |
| `price-display` | `24px / 28px` | `800` (ExtraBold) | `-0.02em` (`-0.48px`) | `FixoTypography.priceDisplay()` |
| `headline-md` | `22px / 30px` | `600` (SemiBold) | `-0.01em` (`-0.22px`) | `FixoTypography.headlineMd()` |
| `headline-sm` | `18px / 26px` | `600` (SemiBold) | `0.0em` | `FixoTypography.headlineSm()` |
| `body-lg` | `16px / 24px` | `400` (Regular) | `0.0em` | `FixoTypography.bodyLg()` |
| `body-md` | `14px / 20px` | `400` (Regular) | `0.0em` | `FixoTypography.bodyMd()` |
| `body-sm` | `12px / 18px` | `400` (Regular) | `0.0em` | `FixoTypography.bodySm()` |
| `label-lg` | `14px / 20px` | `600` (SemiBold) | `0.01em` (`+0.14px`) | `FixoTypography.labelLg()` |
| `label-md` | `12px / 16px` | `600` (SemiBold) | `0.02em` (`+0.24px`) | `FixoTypography.labelMd()` |

### 4.3 Spacing, Radius & Elevation (`FixoSpacing`, `FixoRadius`, `FixoShadows`)
- **8pt Spacing Scale**: `xs = 4dp`, `sm = 8dp`, `gutterMobile = 12dp`, `md = 16dp` (standard mobile margin/gutter), `lg = 24dp`, `xl = 40dp`, `minTouchTarget = 48dp`.
- **Border Radius**: `xs = 4dp`, `sm = 8dp` (buttons/inputs), `md = 12dp` (inner panels), `lg = 16dp` (cards), `xl = 24dp` (bottom sheets), `pill = 9999dp`.
- **Elevation**: `FixoShadows.level1CardResting`, `FixoShadows.level2Interactive`, `FixoShadows.level3Overlay`.

---

## 5. Reusable Component Inventory

### 5.1 Implemented in `mobile/lib/core/widgets/`
1. `FixoBrandMark` — Local vector brand icon (`#173F35` box + `#D5EE76` handyman icon) + `FIXO` wordmark & subtitle. Replaces broken external `FIXO Brand Logo` `<img>` tags on Screens `01, 03, 04, 06, 07, 08, 09, 10, 15`.
2. `FixoPrimaryButton` — `#173F35` full-width `48dp` CTA button supporting both standard trailing icons and the circular `#D5EE76` arrow badge (`showCircularLimeBadge: true`).
3. `FixoAccentButton` — High-luminance `#D5EE76` button with `#173F35` bold text (used on Screens `02, 03, 10, 15, 16`).
4. `FixoSecondaryButton` — `#FFFFFF` card-surface button with `#E7E8DF` border and Level 1 shadow.
5. `FixoSurfaceCard` — Elevated `#FFFFFF` card container with customizable padding, radius, and border.
6. `FixoTrustPillarChip` — Compact trust badge chip with `#326857` icon and `labelMd` text.
7. `FixoStatusBadge` — Pill-shaped status/category tag with optional status dot, leading icon, and uppercase tracking.
8. `FixoTextField` — Labeled form input primitive with optional right-aligned secondary caption (e.g., Arabic label `الرقم القومي` on Screen 11).
9. `FixoEgyptPhoneField` — Egyptian `+20` phone input with native 3-stripe Egypt flag motif and clear action (ready for Screen 02 & Screen 11).

### 5.2 Planned Shared Components for Upcoming Phases (`mobile/lib/core/widgets/`)
1. `FixoSegmentedPillSwitcher` — Top pill state switcher used on Screen 02 (`1. Phone Input` / `2. OTP Code`), Screen 08 (`Active` / `Completed` / `Cancelled`), and Screen 14 (`In Review` / `Approved` / `Action Req.`).
2. `FixoOtpDigitRow` — 6-box tabular numeral OTP input widget with active lime highlight cursor and keyboard/keypad binding (Screen 02).
3. `FixoCustomerBottomNav` — 4-tab Customer navigation bar (`Home`, `Orders`, `Chat`, `Profile` across Screens `03, 08, 10`).
4. `FixoProBottomNav` — 4-tab Pro navigation bar (`Dashboard`, `Jobs`, `Earnings`, `Profile` on Screen `15`).
5. `FixoCategoryTile` — Service category card with icon box, `~EGP` estimate badge, title, and subtitle (Screen `03`).
6. `FixoProSummaryCard` — Technician profile card with avatar, verified badge, star rating, review count, `Est. EGP` price display, and `Book Slot` CTA (Screens `03, 04, 06, 08, 09`).
7. `FixoStepProgressHeader` — Multi-step onboarding progress bar (`Step 1 of 4`..`Step 3 of 4` on Screens `04, 11, 12, 13`).
8. `FixoMapPreviewCard` — Local vector/canvas Cairo & Giza map preview card with route pins and distance badges (replacing hotlinked static map images on Screens `04, 06, 08, 12, 16`).

---

## 6. Flutter Image & Asset Policy

Google Stitch MCP is the design specification source, **not** a runtime image CDN. Across the 16 live Stitch HTML screens, there are **43 external image references (28 distinct URLs)** hosted on `lh3.googleusercontent.com` (`37 <img src="...">` elements + `6 CSS background-image: url(...)` properties).

For production Flutter implementation:
- Bundle required legally usable images, icons, and vector illustrations locally or render them via deterministic Flutter custom painters.
- Preserve existing working local assets and widgets (`FixoBrandMark`, `CairoInteriorHeroCard`).
- Never rely on temporary Stitch or `lh3.googleusercontent.com` URLs at runtime.
- Do not replace the original Stitch visual design unnecessarily; if an asset cannot be retrieved or legally reused (e.g., National ID specimens), report the issue and use a faithful synthetic replacement.

| Asset Category | Screens Affected | Occurrences | Flutter Local Replacement Strategy |
| :--- | :--- | :---: | :--- |
| **FIXO Brand Logo (`alt="FIXO Brand Logo"`)** | `03, 04, 06, 07, 08, 09, 10` | 7 | Replaced by `FixoBrandMark` widget (already implemented). |
| **Customer Avatar (`Salma El-Shazly`)** | `03, 04, 05, 06, 07, 08, 09, 10, 16` | 10 | Local `FixoAvatar` widget with deterministic initials/vector portrait illustration. |
| **Technician Avatars (`Hassan El-Sayed`, `Tarek Mansour`)** | `03, 04, 06, 07, 08, 09, 11, 15` | 13 | Local `FixoAvatar` widget with role/trade badge and vector artisan avatar. |
| **Cairo Apartment / Lifestyle Mood Banners** | `01, 02` | 2 | Custom-painted `CairoInteriorHeroCard` (Screen 01, implemented) and `CairoMoodBanner` (Screen 02). |
| **Service & Equipment Photos (AC unit, van tools)** | `04, 05, 07, 09` | 4 | Local vector/canvas service illustrations (`SplitAcIllustration`, `SanitizedToolkitIllustration`). |
| **Static Cairo/Giza Map Previews** | `04, 06, 08, 12, 16` | 5 | Local custom-painted `FixoCairoMapPreview` canvas widget with Sheikh Zayed / 26th of July Corridor road geometry and animated route pins. |
| **National ID Front/Back Specimens** | `13` | 2 | Clearly labeled synthetic vector specimen cards (`SYNTHETIC DEMO SPECIMEN — NOT A REAL ID`). |

---

## 7. Live Stitch MCP Artifact Characteristics & Known Design Issues

### 7.1 Live Stitch Screenshot Formats (`PNG` vs `JPEG`)
- **8 Screens (`01, 02, 04, 07, 09, 10, 12, 13`)**: Stored on Stitch MCP as full-resolution **2x Retina (`780px` width) PNGs** (`.../fileEntries/screenshot`).
- **8 Screens (`03, 05, 06, 08, 11, 14, 15, 16`)**: Stored on Stitch MCP as regenerated **1x (`390px` width) JPEGs** (`projects/18114732464114306203/files/<id>`).
  - *Note on Live Headless JPEG Capture*: On screens `15` and `16`, Stitch's cloud JPEG renderer captured after the 45-second inline JS timer completed (`Expired` on Screen 15, `00:00` on Screen 16), and on screens `03, 06, 08` certain Material Symbol ligatures or nested flex labels rendered faintly in the JPEG capture. Always inspect **both** the live HTML (`download_file` on `htmlCode.name`) and the live screenshot (`download_file` on `screenshot.name`) via `StitchMCP`.

### 7.2 Known Design Issues & Required Flutter Remediations

| ID | Screen(s) | Live Stitch Issue | Required Flutter Implementation Fix |
| :--- | :--- | :--- | :--- |
| **ISS-01** | `07`, `09` | Live HTML and live PNG screenshots contain `<h1>Payment</h1>` in the top app bar of **Customer Chat** (`07`) and **Rate & Review** (`09`). | Render `Chat` on Screen 07 and `Rate & Review` on Screen 09. |
| **ISS-02** | `03` | Live HTML lines 10 and 20 contain duplicated `Eng. Tarek Mansour` and `Hassan El-Sayed` pro summary blocks inside the top location/search header container. | Omit the duplicated header pro rows; render the clean location pill (`Sheikh Zayed, Dist. 9`) and search bar (`Search electrical, plumbing, AC repair...`), keeping the pro cards in the `Top Rated Cairo Professionals` section below. |
| **ISS-03** | `03, 04, 06, 07, 08, 09, 10` | Live HTML references a broken external URL for `alt="FIXO Brand Logo"`, which renders as a broken image icon or gray `img` box in the Stitch screenshots. | Use our native `FixoBrandMark` widget across all headers. |
| **ISS-04** | `01, 03, 04, 10, 13` | Remaining unverified prototype copy in HTML (`100% Background Checked`, `Insured up to 25,000 EGP` on `01`/`10`, `Identity match: 99.4%` AI OCR claim on `13`). | Use honest MVP copy (`Identity-Reviewed Pros`, `Upfront EGP quotes`, manual document review) until third-party integrations exist. |
| **ISS-05** | `04, 05, 08, 09, 13` | Hardcoded `2024` dates (`October 2024`, `Oct 14, 2024`, `Sep 28, 2024`, `fish_geena2y_2024.pdf`). | Generate dynamic relative dates from the current clock/fixtures. |
| **ISS-06** | `05` | Live HTML defaults radio selection to `InstaPay Egypt` (`tarek.aly@instapay`). | Per `AGENTS.md`, default MVP selection to **Cash on Service** (`Cash to Artisan`) and badge `InstaPay`, `Smart Wallets`, `Cards & Meeza`, and `Fawry` as Sandbox / Coming Soon. |

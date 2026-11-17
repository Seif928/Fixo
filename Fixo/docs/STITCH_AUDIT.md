# FIXO — Live Stitch Design Audit & Flutter Handoff

Audit date: 2026-10-31
Source of Truth: **Google Stitch MCP (`StitchMCP`)** — Official Project `projects/18114732464114306203` (`Fixo Home Services App`, *Nilotic Craft & Home*)
Detailed Live Reference: `docs/LIVE_STITCH_DESIGN.md`

## Live Stitch Inventory

- Exactly 16 official screens (`01 — Onboarding` through `16 — Incoming Job Request`), each with live HTML (`htmlCode.name`) and live visual screenshots (`screenshot.name`) accessible via `StitchMCP`.
- Live design system specification stored in `designTheme.designMd` (*Nilotic Craft & Home*).
- Local exported Stitch folders have been removed from the workspace so that `StitchMCP` remains the single source of truth.
- All Stitch screens are HTML/CSS/Tailwind/JavaScript prototypes and visual previews; UI must be implemented natively in Flutter.
- The 16 screens contain 43 externally linked `lh3.googleusercontent.com` references (37 `<img>` tags + 6 CSS `background-image` URLs; 28 distinct URLs). Bundle local/vector assets in Flutter and never rely on runtime external URL hotlinks.

## Critical findings to resolve

| Priority | Screen(s) | Finding | Suggested correction |
| --- | --- | --- | --- |
| P0 | 06, 07, 09 | Exported PNG previews show the wrong header **Payment** on Tracking, Chat, and Review. HTML content for Chat and Review also contains `Payment` as the header label; Tracking's HTML says `Live Order Tracking`, suggesting code/preview mismatch. | Use `Live Tracking`, `Chat`, `Rate & Review`; regenerate preview from the actual final HTML. |
| P0 | 03–10 (multiple) | Screenshots show broken image icons and the literal text **FIXO Brand Logo**. The HTML references an external logo image instead of a bundled local brand asset. | Create a local vector wordmark/icon and use it consistently. |
| P0 | 08 | The PNG preview shows a visible technical identifier beginning `PIXEL_4_4XL...` above the active order. It was **not found in extracted HTML text**, so exported preview and code may not match. | Regenerate screenshot and verify output from the definitive code. |
| P0 | 01, 04, 05, 11, 13, 14, 16 | Prototype copy asserts background checks, government identity checks, insurance/guarantees, instant payouts, or similar financial/institutional capabilities without implementation evidence. | Use neutral language until real integrations and terms are implemented; mark examples as mock content. |
| P1 | 04, 08, 09, 13 | Several example dates and filenames refer to 2024 (e.g. `October 2024` and `Oct 14, 2024`). | Replace hardcoded dates with generated demo data or current fixtures. |
| P1 | 03, 06, 07, 08, 12, 15 | Extremely dense cards, long names and small labels may harm legibility; screenshots use different pixel widths/heights. | Validate on real 360 / 390 / 412 logical-pixel Flutter viewports and large text scaling. |
| P1 | All | UI contains local JavaScript demo interactions, but no real auth, chat transport, location tracking, payment, storage or server data. | Treat screens as visual reference, not working app logic. |
| P1 | 11, 13 | Prototype National ID fields/images and documents should never be treated as real user records. | Use clearly synthetic demo identity data; avoid committing personal IDs or documents. |

## Screen inventory and implementation mapping

| Screen | Feature / Flutter page | Notes |
| --- | --- | --- |
| 01 Onboarding | `OnboardingPage` | Replace unsupported trust and guarantee claims. |
| 02 Phone Auth/OTP | `PhoneAuthPage` / `OtpStep` | Both within one flow; backend provider required. |
| 03 Customer Home | `CustomerHomePage` | Categories, pros and promotions from API. |
| 04 Create Booking | `CreateBookingPage` | Dynamic date/time; map and address. |
| 05 Payment | `CheckoutPage` | Implement cash first, then a real payment gateway in sandbox. |
| 06 Live Tracking | `OrderTrackingPage` | Order state events and location must be real, not mock map. |
| 07 Chat | `ChatPage` | Header label needs fixing; real messaging later. |
| 08 My Orders | `OrdersPage` | PNG technical text needs regeneration. |
| 09 Rate & Review | `ReviewPage` | Header label needs fixing. |
| 10 Profile & Notifications | `CustomerProfilePage` | Settings and alerts grouped in one page. |
| 11 Pro Sign-Up | `ProSignUpPage` | Validate profile on backend. |
| 12 Services & Skills | `ProSkillsPage` | Backend taxonomy + professional service areas. |
| 13 ID & Licenses | `ProVerificationDocsPage` | Secure upload, no unsupported auto-verification claims. |
| 14 Verification Status | `ProVerificationStatusPage` | Pending / approved / rejected states. |
| 15 Pro Dashboard | `ProDashboardPage` | Backend earnings and operational data. |
| 16 Incoming Request | `IncomingJobPage` | Accept/reject with server state and timeout. |

## Fixo design tokens to adopt initially

Reference values from the DESIGN.md narrative (some Tailwind screen configurations may differ):

- Primary forest: `#173F35`
- Secondary forest: `#245B4B`
- Lime highlight: `#D7F078`
- Warm cream: `#F7F5EF`
- White: `#FFFFFF`
- Ink: `#19231F`
- Muted text: `#78817A`
- Border: `#E7E8DF`
- Coral: `#FF795F`
- Typeface: Manrope for English; Cairo for Arabic Flutter localization.

Create Flutter `ThemeData`, `ColorScheme`, typography, radius and spacing tokens centrally instead of copying inline Tailwind style per page.

## Development decision

**Conditional GO:** enough to start implementation, but use the HTML and screenshots as **UI references only** and fix the critical UI/copy issues while implementing Flutter.

Proposed order:
1. Initialize mono-repo with Flutter app, NestJS API, PostgreSQL/Prisma, and documentation.
2. Define normalized domain schema, workflow and endpoint contracts.
3. Add the Flutter design system, routing, localization (AR/EN), themes and app shell.
4. Build customer/pro authentication and role-based API.
5. Complete service discovery → booking → job acceptance MVP with cash-on-service.
6. Add chat, real-time tracking, notifications and review workflow.
7. Add payment sandbox, pro verification processes, admin management, tests and CI/CD.
8. Deploy a safe public demo using fictional accounts/data, record a walkthrough, and document architectural decisions.

## Quality gates

- [ ] Verify that each header is correct in the rendered Flutter screen.
- [ ] Replace broken/hotlinked branding and bundle permitted assets.
- [ ] Remove technical artifacts from `My Orders` preview.
- [ ] Audit all regulatory/guarantee/payout text against implemented features.
- [ ] Validate devices at 360 / 390 / 412dp and with larger font sizes.
- [ ] Use real state models and tests; do not depend on Tailwind/JS demo handlers.
- [ ] Check English LTR and Arabic RTL, light/dark and accessibility.
- [ ] Include only synthetic sample users, IDs, documents and bookings.

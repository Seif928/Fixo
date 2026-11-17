# FIXO — Agent Instructions (Read Before Editing)

## Mission
Build a portfolio-grade Egyptian home-services marketplace for customers and technicians. Preserve the official Stitch look: deep forest green (`#173F35` / `#002920`), fresh lime accent (`#D5EE76` / `#D7F078`), botanical/cream surfaces (`#F1FCF5` / `#F7F5EF`), and `Manrope` English typography (`Cairo` for Arabic RTL). Build real working architecture using native Flutter widgets, not mock HTML inside WebViews.

## Single Source of Truth for UI/UX Design (Google Stitch MCP Only)
**Google Stitch MCP is the ONLY approved UI/UX design source for this repository.** Local exported Stitch HTML/screenshot directories have been permanently removed; do not ask the user to manually export ZIP archives.

1. **Official Stitch Project**:
   - **Project ID**: `projects/18114732464114306203`
   - **Project Name**: `Fixo Home Services App`
   - **Design System**: `Nilotic Craft & Home` (`assets/7f245f47c92a4bf080d50b3e1a02cf4a`)
   - **Expected Screens**: 16 (`01 — Onboarding` through `16 — Incoming Job Request`)
   - **Deprecated Project (DO NOT USE)**: `projects/4897897995916433825`
2. **Design Reference Priority**:
   1. **Live Stitch MCP (`StitchMCP`)**: Fetch screen metadata (`list_screens`, `get_screen`) and download live HTML and screenshots (`download_file`) directly from `projects/18114732464114306203` using the verified screen IDs in `docs/LIVE_STITCH_DESIGN.md` and `docs/SCREEN_MAP.md`.
   2. `docs/LIVE_STITCH_DESIGN.md`: Complete verified inventory of all 16 live Stitch screen IDs, routes, tokens, reusable components, and asset policies.
   3. `docs/STITCH_AUDIT.md`: Known prototype defects and misleading regulatory/financial claims that must be remediated during native Flutter implementation.

## Stack and Architecture
- **Mobile (`mobile/`)**: Flutter, Dart, Riverpod, GoRouter, Dio, feature-first modular organization, central `FixoTheme` (`ThemeData`, `ColorScheme`, `FixoPaletteExtension`), Material 3.
- **Backend (`backend/`)**: Node.js, NestJS, TypeScript, PostgreSQL, Prisma, `class-validator`, Swagger/OpenAPI; JWT access/refresh tokens (securely stored/revoked), roles and authorization rules.
- **Admin (`admin/`)**: Later phase; do not build it now.
- **CI/Testing**: `flutter analyze` + `flutter test`; backend lint + unit tests; introduce integration tests as real routes are built.
- Single Flutter app with customer/pro role-dependent navigation. Support `en` (LTR) and `ar` (RTL) via localization infrastructure; keep dark mode extensible centrally via `FixoTheme`.

## Flutter Image & Asset Policy
Google Stitch MCP is the design specification source, **not** a runtime image hosting CDN:
- Bundle required legally usable images, vector illustrations, and icons as local Flutter assets or deterministic custom painters.
- Preserve existing working local assets and custom widgets (e.g., `FixoBrandMark`, `CairoInteriorHeroCard`).
- Never rely on temporary Stitch or `lh3.googleusercontent.com` hotlinked URLs at runtime.
- Do not replace the original Stitch visual design unnecessarily; if an asset cannot be retrieved or legally reused (such as National ID specimens), report the issue and provide a faithful synthetic/local replacement.

## Invariants
- **Only** the 16 official Stitch screens define the UI scope. Do not invent top-level screens without approval.
- Avoid unsupported claims of Egyptian government verification, insurance, guaranteed electronic transfers, or official partnership. Payment starts with **Cash on Service** (`CASH_ON_SERVICE`); other methods are clearly labeled sandbox/coming-soon UI placeholders until a sandbox integration exists.
- Never use real personal ID card photos/credentials in demo data; avoid including secrets in Git.
- Use Egypt locations (Greater Cairo & Giza) and `EGP` demo prices. Any fake data must be clearly mock data.
- Do not modify the original live Stitch designs unless explicitly instructed. Do not auto-push or deploy without approval.
- Avoid huge one-shot implementations: work in short, testable phases; always run available tools and report exact results.
- Implement responsive layouts: test `360dp`, `390dp`, and `412dp` logical widths and increased text scale (`1.35x`).

## Mandatory Development Workflow
For every implementation phase, strictly follow:
1. **Stitch MCP** — Query `projects/18114732464114306203` via `StitchMCP` using the official screen IDs (`get_screen`, `download_file`).
2. **Live Design Inspection** — Inspect the live Stitch HTML, screenshot, tokens, and copy against `docs/LIVE_STITCH_DESIGN.md` and `docs/STITCH_AUDIT.md` before writing code.
3. **Native Flutter Implementation** — Build responsive native Flutter widgets using `FixoTheme`, Riverpod, GoRouter, and Dio (no WebViews, no runtime hotlinks).
4. **Testing** — Run `flutter pub get`, `flutter analyze`, `flutter test` (including responsive viewport & RTL tests), and backend tests before reporting completion.

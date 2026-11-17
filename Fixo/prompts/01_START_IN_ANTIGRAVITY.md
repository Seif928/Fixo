You are my principal engineer and Flutter + NestJS technical lead for FIXO, a serious portfolio project.

First, read `AGENTS.md`, `README.md`, `docs/LIVE_STITCH_DESIGN.md`, `docs/STITCH_AUDIT.md`, `docs/SCREEN_MAP.md`, and inspect the 16 official screens in live Google Stitch project `projects/18114732464114306203` (`Fixo Home Services App`) via `StitchMCP`. Reconcile the `Nilotic Craft & Home` design system metadata with the 16 live screens.

IMPORTANT: Google Stitch MCP (`projects/18114732464114306203`) is the single source of truth for design input. Do not ask me to export ZIP archives or upload screenshots again. Do not use WebViews or convert HTML to a mobile site: produce native Flutter UI.

Technical direction:
- Flutter app in `mobile/` with Riverpod, GoRouter, Dio, feature-first clean architecture.
- NestJS TypeScript backend in `backend/` with PostgreSQL + Prisma, modular APIs, role-based auth, validation, Swagger, tests.
- Future admin dashboard in `admin/` (do not build it yet).
- Preserve exact modern Fixo forest-green / lime / cream look, with responsive mobile layouts.
- Egyptian market: EGP, Cairo/Giza, English UI first, AR/RTL and Dark Mode architecture ready.
- Source design is a prototype: correct wrong `Payment` titles in Tracking/Chat/Review; remove debug identifiers and broken branding. No fake regulatory, payment, or insurance integrations.

PHASE 1 ONLY:
1. Inspect the workspace, project files, installed Flutter/Dart/Node/PostgreSQL/Docker toolchains. Report what is found.
2. Map the 16 screens to Flutter routes/features and write `docs/ARCHITECTURE.md`, `docs/IMPLEMENTATION_PLAN.md`, `docs/DATABASE_SCHEMA.md`, `docs/API_CONTRACT.md` with realistic MVP scope and order states.
3. Scaffold a Flutter app in `mobile/` and NestJS starter in `backend/` IF required tooling is installed, without modifying the Stitch source files. Use safe, current package APIs and pin sensible versions.
4. Build Flutter design-system tokens (`colors`, typography, spacing, radius, buttons, inputs) and a working native implementation of Screen 01 Onboarding only. Add routing for the initial flow. Use demo-safe/local assets and make broken external images explicit placeholders if needed.
5. Create initial tests and run available formatter, analyzer, tests and basic build/checks; fix problems found. Do not claim tests passed if not run.
6. Give me a concise report: completed changes, folder tree, commands/tests/results, blockers, and exact next prompt for Phase 2.

Do NOT generate all 16 pages at once, fake the backend endpoints, run migrations against any production database, add unapproved external credentials, push to GitHub, or deploy. Stop after completing Phase 1.

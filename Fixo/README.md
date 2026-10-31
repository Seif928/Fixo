# FIXO — Egyptian Home Services Marketplace

**FIXO** (*Better Homes. Better Everyday.*) is a bilateral home-services marketplace for Greater Cairo and Giza connecting homeowners with skilled local technicians across HVAC, Plumbing, Electrical, Deep Cleaning, Carpentry, and Painting.

---

## Repository Structure

- `mobile/` — Native Flutter application (Customer + Professional flows in a single binary using Riverpod, GoRouter, Dio, and `FixoTheme`).
- `backend/` — Modular NestJS TypeScript REST API backed by PostgreSQL and Prisma ORM (`backend/prisma/schema.prisma`).
- `admin/` — Reserved placeholder for a future back-office web portal.
- `docs/` — Architecture, live Stitch design reference, route map, implementation plan, API contracts, database schema, and design audit documentation:
  - `docs/LIVE_STITCH_DESIGN.md` — Verified live Google Stitch MCP reference (Official Project ID, all 16 screen IDs, design tokens, component inventory, and asset policy).
  - `docs/SCREEN_MAP.md` — Fixed 16-screen scope and GoRouter route mapping.
  - `docs/ARCHITECTURE.md` — Full-stack system & state-machine architecture.
  - `docs/IMPLEMENTATION_PLAN.md` — Phased engineering roadmap.
  - `docs/API_CONTRACT.md` — REST API specification.
  - `docs/DATABASE_SCHEMA.md` — Normalized PostgreSQL / Prisma data model.
  - `docs/STITCH_AUDIT.md` — Prototype audit findings and MVP compliance rules.
- `AGENTS.md` — Mandatory instructions and invariants for AI coding agents.

---

## Single Source of Truth for UI/UX Design (Google Stitch MCP)

All UI/UX design specifications are retrieved **exclusively** from the live Google Stitch project via **Stitch MCP (`StitchMCP`)**. Obsolete local HTML/screenshot exports have been removed from the workspace.

- **Official Stitch Project ID**: `projects/18114732464114306203`
- **Project Name**: `Fixo Home Services App`
- **Design System**: `Nilotic Craft & Home` (`#173F35` Deep Forest, `#D5EE76` Fresh Lime, `#F1FCF5` / `#F7F5EF` surfaces, `Manrope` typography)
- **Scope**: 16 official screens (`01 — Onboarding` through `16 — Incoming Job Request`)
- **Excluded Project**: Do **not** use legacy project `projects/4897897995916433825`.

### Development Workflow
```text
Stitch MCP → Live Design Inspection → Native Flutter Implementation → Testing
```
1. **Stitch MCP**: Retrieve live screen metadata, HTML, and visual screenshots via `StitchMCP` (`list_screens`, `get_screen`, `download_file`).
2. **Live Design Inspection**: Cross-check layout, tokens, and copy against `docs/LIVE_STITCH_DESIGN.md` and `docs/STITCH_AUDIT.md`.
3. **Native Flutter Implementation**: Implement using native Flutter widgets, `FixoTheme`, and bundled local/vector assets (never WebViews or runtime external URL hotlinks).
4. **Testing**: Verify with `flutter pub get`, `flutter analyze`, `flutter test` (`360dp` / `390dp` / `412dp` viewports, `1.35x` text scaling, English LTR & Arabic RTL), and NestJS unit tests (`npm test`).

# FIXO · Application workspace

The maintained project overview, screenshots, account roles and setup instructions are in the [repository README](../README.md).

| Directory | Purpose |
| --- | --- |
| [`mobile/`](mobile/) | Shared Flutter application for Android, iOS, web and administration |
| [`backend/`](backend/) | Active NestJS API with Prisma and PostgreSQL |
| [`docs/`](docs/) | Architecture, API, security and release documentation |
| [`backend_dart/`](backend_dart/) | Inactive migration experiment; not the production API |

- [Getting started](../README.md#getting-started)
- [Testing](../README.md#testing)
- [Current design system](DESIGN.md)
- [Role workspaces](docs/ROLE_WORKSPACES_RELEASE_2026-11-17.md)

Run Flutter commands from `mobile/` and backend commands from `backend/`. The Compose file here starts local PostgreSQL.

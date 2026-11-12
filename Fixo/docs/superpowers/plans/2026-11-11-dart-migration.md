# FIXO Dart migration implementation plan

STOPPED by the user's subsequent decision on 2026-11-11. Keep the current NestJS backend; prioritize working features over language conversion. Do not execute the remaining migration steps unless the user requests resumption.

Execution: single implementer; preserve the active API until contract parity. User explicitly included backend conversion after initially selecting frontend only.

Goal: Flutter/Dart client, Web and administration, with a separate Dart backend and inward dependencies. Flutter is a UI toolkit, not the server runtime. Native platform launchers, SQL, manifests and deployment configuration remain necessary.

## Steps and release gates

1. Build an independently tested Dart service in backend_dart: domain ports/entities, application use case, PostgreSQL adapter and Shelf HTTP composition. First actual ports: health, readiness and categories/zones. No proxy to Nest, demo responses or fabricated authentication. Readiness must remain 503 while migration is incomplete.
2. Inventory every legacy controller route and retain an explicit pending list. Migrate auth/session/password/Firebase verification next; preserve signed-token verification, revoked/deleted account checks and exact error contracts before any client switch.
3. Migrate booking/pricing/payment state transitions and concurrency guarantees, then private media, support/chat, professional/dispatch and private administration. Port regression cases and run against isolated localhost/fixo_test. Do not alter live schema/data or move secrets into Flutter.
4. Extract existing frontend repository contracts into pure Dart domain files; retain compatibility exports during the import transition. Add a domain dependency test rather than imposing decorative use cases with no business behavior.
5. Remove only proven generated diagnostics and empty placeholders. Preserve native launchers, fonts/licenses, schema/migrations, release evidence and original/Gemini work.
6. Before replacement: all route contracts, authorization/state transitions and existing regression cases must pass; choose and verify a free Dart-compatible host with an explicit rollback. Do not deploy the incomplete service behind the production client.

Hosting references checked 2026-11-11: https://dart.dev/server ; https://vercel.com/docs/functions/runtimes ; https://render.com/docs/free . Render Free is a possible development host, has idle spin-down and is not a production-readiness guarantee. No infrastructure or billing change is authorized by this file itself.

# FIXO release verification — 2026-11-09

Baseline: d36dd3c. Branch: codex/fixo-premium-repair.
Design reference: https://www.figma.com/design/xAym32AGTmERySxtIyBbob

## Implemented
- Require verified provider tokens for Apple authentication; remove email-only and synthetic client/server identity fallback.
- Reject all unsupported electronic checkout methods. Cash payments stay PENDING with no paid timestamp or invented verification reference.
- Keep expanded catalog drafts private until administrator pricing/publication. Preserve existing real catalog entries.
- Retire unscoped home cache; replace search results authoritatively and discard responses after area/category changes.
- Preserve saved addresses when updating profile name.
- Charcoal/ivory/champagne theme, responsive editorial home, stable mobile navigation and desktop top navigation. Preserve real service selection, governorate picker, profile/avatar and admin actions.
- Tracking illustration is explicitly illustrative and not the default tracking view.

## Evidence
- Backend: 52 suites, 471 tests passed, including local PostgreSQL tests on guarded localhost:5432/fixo_test.
- TypeScript lint and Nest build passed.
- Flutter: 533 tests passed, 2 skipped; light/dark, EN/AR, 360/390/412dp and enlarged text plus desktop rendering checks.
- Dart analysis: no issues.
- Web release/WASM build succeeded. Existing service-worker retirement script and static Vercel headers copied to release output.
- Reviewed home (mobile light/dark and desktop), checkout, profile and admin screenshots. Golden baselines updated for intentional design changes.
- Desktop screenshot retained as a manual visual artifact; an additional pixel assertion was not retained because the variable-font FIXO wordmark differed by 327 pixels between isolated and full-file execution. Existing desktop overflow/layout checks remain.

## Live database changes
- Explicitly approved repair: 135 unapproved generated offers deactivated, one simulated paid record on a cancelled booking corrected to FAILED with paidAt null. Previous values stored in AdminAuditLog; no service/booking deletion.
- Eight additive booking/message query indexes applied and verified valid. No RLS/billing changes.

## Release and remaining external checks
- User explicitly approved production deployment and GitHub branch push. Both deployments are READY. Vercel MCP still lacks a team grant; the already-authorized CLI was verified against the exact existing team and project IDs and used successfully.
- Android debug APK build succeeded (222.1 seconds): mobile/build/app/outputs/flutter-apk/app-debug.apk. This is a test build, not a store-signed release or proof of device/provider verification. Compiler warnings originate in plugin Java compatibility/deprecation settings.
- iOS build/device verification requires macOS/Xcode and remains unverified. No paid Apple program or service enabled.
- Real Google login, camera/gallery upload and push delivery on physical devices require provider/device smoke checks after deployment; widget/integration tests do not prove them.
- Apple provider configuration has not been verified; failures now reject safely rather than create a false session.
- No electronic payment gateway, SMS or billing enabled. No 120fps/latency guarantee.
- Historical local migration 20261102090000_geo_lookup was already failed; migrate deploy stopped safely. Tests used schema synchronization without reset on isolated fixo_test. This does not establish clean replay of all historical migrations.

## Deployment/rollback plan
Deploy the tested backend first, then build/web to the existing fixo-web project. Preserve environment settings and billing. Smoke-check health and public catalog before and after web rollout. Record current production deployment IDs before promotion; roll back to those exact IDs if smoke checks fail. Do not roll back approved data repairs automatically or re-enable fabricated catalog prices.

## Production release completed
- Application source: 3030fea; verification-only documentation: 6932ea8.
- GitHub branch: codex/fixo-premium-repair (pushed).
- API deployment: dpl_3zbvw9rw2QP8d8C8DNhwrtwtVynk; https://fixo-api.vercel.app.
- Web deployment: dpl_7bTnS7EgDaRvgb8ifJGy7MJZeNzr; https://fixo-web-blue.vercel.app.
- API readiness: ready, databaseReady true. Public catalog: 11 active services, databaseConnected true.
- Missing-token Apple exchange: HTTP 400, no user identity supplied.
- Public website: HTTP 200. Remote flutter_bootstrap.js, main.dart.wasm and firebase-messaging-sw.js SHA-256 hashes match tested local build artifacts.
- Previous API deployment: https://fixo-r874lvl06-gamal6507-3315.vercel.app.
- Previous web deployment: https://fixo-lx32dqb3v-gamal6507-3315.vercel.app.
- No environment, account permissions or billing changes. Physical-device login/push checks remain outstanding as documented above.
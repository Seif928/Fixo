# Web responsiveness and Google sign-in repair — 2026-11-11

## Result and boundaries

Prepared client fixes for the reported all-page freezing and intermittent first Google click error. No server/provider migration, billing change, live data edit, or automatic OAuth retry is included. Clerk remains disabled. Deployment/browser verification is recorded below after rollout.

## Findings and changes

- Source showed permanent decorative painter loops hidden by ordinary widget-test shortcuts. Brand, badge, home scene, receipt, tracking, appliance and skeleton effects now finish instead of continuously scheduling idle frames. The visibility throttler plays once by default.
- Web and reduced-motion surfaces skip large backdrop blurs and pointer-driven caustics/perspective. Children retain normal buttons, scrolling, gradients and borders. A reduced-motion teardown regression also exposed a lazily created tilt controller being initialized during dispose; initialize it in initState instead.
- Firebase initialization previously happened after the Google click. Web controls now prepare Firebase/persistence in advance and enable the real sign-in action after readiness; popup invocation is synchronous from that click. Failed preparation offers a separate reconnect action. Closed/cancelled popups do not display an invalid-password error; blocked/network failures have specific messages.
- Both Google controls use Google's unmodified bundled official G asset. Three reviewed login goldens changed. The golden harness explicitly waits for real image decoding before capture.
- Session restoration previously blocked runApp. A first-frame startup gate now paints while restoration runs; application routing and device recovery/push resume wait for successful restoration. Existing account epoch/CAS protections are retained. Unexpected restoration failure keeps protected content gated.

## Verified locally

- flutter analyze --no-pub: no issues.
- flutter test --no-pub: **577 passed, 2 existing opt-in skips**.
- Production-path idle-frame regressions bypass the app's legacy runtimeType test suppression and verify brand/badge/home tickers stop; they are not device GPU/FPS measurements.
- Readiness/coalescing/synchronous popup, cancellation, reconnect, startup pending/error gating, existing phone/profile/role, responsive/RTL and reviewed golden checks passed.
- Release Web build and Android debug APK build passed.
- Web main.dart.js SHA256: `10BAA2899F6ECC85D45C3C0ADFF18B3A7342B36BC93918D439EF44593922AE27`.
- Android debug APK SHA256: `78C9356D27D17272C07565990A0A64CCFA6A2353AA543244CF2CF23B47432698`.
- No backend code changed, so the previously verified backend suite was not redundantly rerun for this client repair.

## Live checks

Before the repair, one real Google attempt succeeded and recent sanitized Firebase rejection logs/client errors were empty. The reported intermittent error was not reproduced consistently. The readiness change addresses a concrete popup timing hazard; it does not establish that every first-click failure had that cause. No claim of universal all-device performance or iOS validation is made.

Rollout and post-deployment browser results: pending.

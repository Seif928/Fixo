# Notification cleanup follow-up

The existing NestJS backend remains active; Dart migration stays stopped.

## Reproduced and fixed

- A native Firebase unregister failure caused disable() to exit before removing the remembered registration or attempting the authenticated server-device DELETE. Cleanup now independently attempts native invalidation, remembered-ID removal and server removal. It rethrows the first failure after attempting all steps, so callers do not receive a false success; logout retains its existing offline behavior.
- enable() could create the next account's token while the previous account's slow native unregister was still running. It now waits for pending cleanup. Concurrent disable calls share the same cleanup operation; session generation and account-bound request checks remain in place.

Two regression cases failed before the correction and passed afterward. The focused device-push suite passed all twelve tests, covering both new cases, permission denial, stale registration/initialization, offline server cleanup and callback cancellation.

These are mocked platform/network regressions, not proof of OS notification delivery. Actual Android/browser receipt, APNs/iOS and offline provider failures still require device verification. Failure of both native and server cleanup cannot be represented as guaranteed cleanup.

Full Flutter verification: 549 passed with two intentional live opt-in skips; analyze clean. No backend source, schema, credentials or billing setting changed.

Released source 7109382: Web release and ordinary Android debug APK builds succeeded. Vercel deployment dpl_5KvFuMW5BXBwapqBiUZvSLJMdSWq is Ready at https://fixo-web-blue.vercel.app, mirrored on Firebase. Tested and both public main.dart.js hashes match 6E05C386F20B3D249151E51EFD41649594746BC47B44CEC41041AD2DA9242BD4. No UI redesign or API cutover was included.

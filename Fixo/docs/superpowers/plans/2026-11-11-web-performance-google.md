# Web responsiveness and first Google click

Execute inline; user approved repairs and publication, free services only. Preserve current theme/layout and existing authentication, do not switch to Clerk.

## Evidence

- User reports freezing on every page, especially first Google sign-in failing and the second succeeding.
- Live browser first Google click completed in this session; no client console errors or recent sanitized Firebase rejection logs were found. Intermittent cold-start/auth errors are not yet fully reproduced.
- `main` awaits a remote session refresh before `runApp`, so network delays leave no Flutter first frame.
- Google service awaits Firebase initialization inside the click handler, and has no explicit readiness/preparation state or provider-specific error UX.
- Brand crest repeats its painter indefinitely; villa/badge also repeat, and test-only branches suppress those costs in ordinary widget tests. Glass surfaces rebuild on pointer moves and run large backdrop blurs. Web tilt transforms large cards.
- Material `g_mobiledata_rounded` is used instead of Google's official mark. Downloaded official unmodified `g-logo.png` from Google Identity branding documentation.

## Tasks

1. Reproduce continuous production-path frames in a binding without the runtimeType test bypass. Make decorative brand/villa/badge motion finite and keep Web glass/tilt inexpensive without removing working controls or accessibility. Test idle frames, retained interactions and reduced motion.
2. Add shared/coalesced Firebase readiness before Google controls become available, invoke a prepared Web popup without pre-popup await, and show provider-specific blocked/closed/cancelled/network feedback. Test pending readiness, immediate popup invocation, cancellation and one real identity exchange; never fabricate sessions or retry identity errors indiscriminately.
3. Present the app before slow restoration completes, preserving protected-route gating and account epoch/CAS checks. Add startup and late-restoration regressions. Bundle the official Google asset and replace both Google buttons.
4. Full relevant tests/analyze, release Web build, browser navigation/render checks, commit/push and deploy existing Web/Firebase projects. Verify asset hashes and honest limitations; no live bookings/payments or account migration.

## Constraints / decisions

- Single implementer; no subagents. Existing responsive layouts and user-approved palette remain.
- No Stitch tool is exposed in this session. This is a repair of effects/auth/icon within existing approved screens, not a new visual layout; retain the existing screen structure and inspect its current code/live rendering.
- Do not remove screen-reader semantics to hide performance issues.
- No paid features, new auth providers, credential changes, unsafe automatic OAuth retries, or broad cache/database resets.

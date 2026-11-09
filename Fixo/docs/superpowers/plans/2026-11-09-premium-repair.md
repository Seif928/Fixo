# FIXO cinematic redesign and correctness repair

User authorized implementation of all review repairs, testing and a cinematic mobile/web redesign, subsequently explicitly replacing the green palette. Single implementer. Free services only; no SMS or paid gateway activation. Preserve existing work; source baseline d36dd3c in codex/fixo-premium-repair.

## Design direction
Use Figma (connected) because Stitch live tools are unavailable. Cinematic warmth: charcoal #17191C, ivory #F6F2EB, champagne #C6A779, dark surface #22252A. Retain Cairo/Manrope; use crisp hierarchy, generous spacing, restrained light and shadow. No invented trust, payment, availability or live tracking. Mobile navigation anchored and predictable; desktop spacious with clear primary booking action. Motion is short, honors reduced motion, and stops offscreen. Existing routes and real workflows stay intact.

## Execution order and verification
1. Regression tests for unsigned Apple exchange and all unsupported payment enums; remove fallback identity/session creation and restore cash-only server behavior. Verify focused Jest suites and lint.
2. Remove pseudo Apple identity sheet and card collection; use only provider-backed login and truthful payment controls. Test actual controllers/screens.
3. Restore private catalog drafts, add index migration, inspect deployed state before any data repair; preserve booking references/history.
4. Separate area cache, invalidate search generations, replace authoritative search results, fix sorting labels and profile merge. Add regression tests.
5. Create Figma mobile/desktop reference and DESIGN.md; implement champagne/charcoal/ivory theme, simplified mobile home and desktop composition, stable navigation and honest tracking.
6. Full available suites, responsive light/dark EN/AR checks at 360/390/412 and desktop, release builds. Report device/provider checks that remain unavailable separately. Deploy verified source only, no paid changes.

## Failure cases to pin
- Missing/invalid provider tokens never issue a session, including an existing victim email.
- Digital payment enum never marks a live booking paid without a gateway.
- An area/account change cannot restore old feed/search results.
- A profile mutation preserves existing address state.
- Reduced motion, large text and slow/offline loading retain usable navigation and truthful status.

## Progress
- Isolated latest Gemini revision; reference review stored outside repository.
- Implementation and local regression verification completed; see docs/PREMIUM_RELEASE_VERIFICATION_2026-11-09.md for evidence, build status and external checks. Production release pending approval/access.

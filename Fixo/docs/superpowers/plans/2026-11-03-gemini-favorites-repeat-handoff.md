# Gemini next assignment: close catalog review, then favorites and repeat booking

Work in the existing fixo-admin-profile checkout at C:\Users\HP\.codex\worktrees\fixo-admin-avatars\Fixo_Home_Services. Preserve all unstaged changes. Read AGENTS.md, PROJECT_STATUS.md and the previous catalog handoff. Explicit user approval covers these features despite older16-screen/admin-later rules. Use the current native Flutter design and existing free dependencies. One Gemini implementer; no Teamwork or subagents.

## Milestone A — close the catalog review before adding features

Codex reviewed your local catalog diff and found a versioning issue in admin-catalog.service.ts: deactivate/reactivate unconditionally set publishedVersion to the incremented draft version, even if the draft already contains unpublished edits. publish then returns early and never publishes those edits.

Add a failing real-PostgreSQL regression for: publish version1 at priceA → save an unpublished priceB edit → deactivate → reactivate → priceA remains public and the priceB draft still counts as unpublished → explicitly publish the current version → public price becomesB. Toggles must never publish content or lose pending edits. Keep the last actually published revision when edits are pending; only advance the published marker with the concurrency version if the content was already fully published. Preserve stale-version checks and transactional audit.

Also reject an unknown category slug unless both explicit bilingual category names are supplied. Do not fabricate an Arabic category name from an English slug. Existing known categories may reuse their actual stored labels. Add a focused validation regression. Review these new audit actions' bilingual labels and ensure private mutation responses use no-store. Leave your existing catalog changes intact except these necessary corrections.

## Milestone B — actual service/professional favorites

Implement persisted user-owned favorites for real services and professionals: idempotent add/remove, unique ownership, bounded pagination, empty/loading/error states and suitable native UI entry/cards. Start empty; never seed fictional favorites. Deny access to another user's favorites and never treat app ADMIN as an ownership bypass. Respect inactive services and unapproved/suspended professionals: show truthful unavailable states, permit removal, and never present them as bookable. Use existing JWT/session ownership patterns. Add focused backend persistence/access tests and widget tests.

## Milestone C — repeat a booking using current data

Add an explicit "Book again" action to the customer's own eligible order history. Retrieve the current active service and prices from the backend; reuse the existing CreateBooking flow so the customer chooses/confirms the new date, time and owned address. Revalidate service/category/coverage and availability. Never copy historical prices, payments, status events, PINs, reviews or old private-photo references. Never create, confirm, pay for, or dispatch a new booking merely by opening repeat booking. An unavailable/deactivated service gets a clear explanation instead of a dummy replacement. Test price changes, inactive services, ownership denial and the real UI navigation.

## Ownership and integration constraints

- Codex owns notifications/messages, Android photo recovery, private media, incoming-offer timing, complaints and account deletion. Do not edit those areas, main.dart, device_media_picker.dart, private_media_picker_sheet.dart, incoming_job_page.dart, pro_workflow_screens_test.dart, or create_booking_page.dart/review_page.dart. The existing creation route already accepts a current offering; pass validated current data into it.
- Use separate FavoritesRepository/RepeatBookingRepository and new focused tests, rather than adding methods to existing ProRepository/BookingRepository interfaces that would break Codex's fakes. You may add minimal navigation/Profile/Orders entry points, preserving profile edits, location selection, logout only in Profile, and existing booking/checkout behavior. Do not edit administration membership, professional review or booking operational controls.
- Gemini owns necessary additive favorites schema/local migrations during this assignment. New private tables must follow the existing restricted backend-role grants/RLS pattern. Validate the target before connecting/writing: only localhost:5432/fixo_test. Run database tests in-band. No cloud migration or real account/data change; Codex handles shared database/release verification after your report.
- EN/AR, RTL, light/dark,360/390/412dp at1.35x, and suitable desktop layouts. Preserve the existing design tokens and reduced-motion behavior. No unsupported insurance, official verification, payment or availability claims.
- Test each milestone, report a short checkpoint, and continue to the next without an interview. Stop on a genuine missing product decision or outside-scope conflict, not routine implementation details. Do not run exhaustive commands, upgrade dependencies, enable billing, use paid scans/models, or claim untested device behavior.
- Do not reset/switch/rebase the branch, discard other changes, commit, push, deploy or modify the original E: checkout, port3001, or local Flutter5178. Return focused changed paths, exact test results, migration requirements and unresolved limitations. Do not mark a milestone complete while its checks fail. Codex will review and release.

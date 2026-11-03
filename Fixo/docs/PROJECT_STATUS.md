# FIXO — consolidated approved work and remaining scope

Updated: 2026-11-03, Africa/Cairo. This is the current scope index, not a claim that the whole product is finished. Older progress notes are chronological evidence and may contain superseded pending/deployment statements.

## Standing user instructions

- Free plans/services only; no billing, trials, SMS or paid map API activation.
- Single implementer, no Teamwork/subagents. Explain meaningful product choices and let the user choose before adding a new feature.
- Android, iPhone and Web are targets. Responsive widget tests and successful builds do not establish real-device/iOS behavior.
- Preserve the original checkout, concurrent Gemini work, port3001 and the local Flutter5178 session. Work is on fixo-admin-profile; original-branch integration remains open.
- Authenticated live photo/account verification was explicitly deferred. Do not ask for login again or automate authentication dialogs.
- Friend email remains deferred; owner membership is configured for the approved verified account. Do not fabricate a second account/invite.

## Implemented and deployed; some live journeys still need verification

| Request | Implemented scope | Remaining evidence or limitation |
| --- | --- | --- |
| No SMS; first Google registration, name/phone/password, later phone/password | Connected authentication and first-profile flow; current-password-protected phone changes | User confirmed login/logout earlier; complete current Google/profile/password journey is not independently reverified |
| First-profile photo and editable profile | Optional photo, name/phone edits, camera/gallery and24local avatars; private uploads; Home reflects profile metadata | Real authenticated photo/camera journey remains deferred |
| Logout only in Profile | Shared/home logout removed; new administration has only a Profile return action | Continue checking this invariant in future screens |
| All Egypt, lists and optional automatic location | 27governorates,6108offline places, manual fallback, user-scoped selection, optional GPS and free map picker; logo/location interactions repaired | Real permission-denial/device cases still need device coverage; location catalog does not promise technician availability |
| Search button opens all services | Live paginated catalog with search and real prices | No exhaustive fake catalog or fabricated availability |
| Arabic/English, light/dark, animation and suitable mobile/Web layout | Shared themes/localization, reduced-motion-aware transitions, responsive administration and wider desktop marketplace grids | Continued screen/device visual QA, especially iPhone, is still open |
| Separate professional entry, legal name/ID, identity images and criminal record | Professional onboarding, private ID front/back/certificate uploads, wait-for-review lifecycle and document checks | Owner/Admin review UI and conversion of legacy reviewer/document authority are unfinished |
| Two-person private administration | Owner/Admin membership, Owner-only second-member management, real summary and audit; desktop sidebar/mobile drawer | Professional and booking operational pages are unfinished |
| More home services, prices controlled by user | 138new private/unpriced drafts in21groups plus8linked existing services; edit/save/versioned explicit publish | Custom service creation and soft deactivation remain open; drafts become bookable only after intentional pricing/publication |
| Git, Supabase, Firebase and Vercel | Existing free cloud integrations configured; API/Web release deployed and source pushed | Source branch is not merged into the original working branch |
| Skills | grilling, security-audit and official penetration-testing-with-strix installed | Installing Strix is not running a scan; no paid engine/cloud scan was started |

## Approved work still open

1. **Complete professional administration:** list/review dossiers, protected document viewing, approve/reject/request corrections, prohibit self-approval, replace legacy app-role reviewer bypasses, transactional audit and access tests. Do not auto-approve real people.
2. **Complete booking administration:** real booking details/history and permitted state operations, assignment/dispatch controls constrained by eligibility, cash/payment correctness and audit. Preserve historical prices and completed events.
3. **Notifications and messages:** integration code exists, but actual delivery, permission behavior, foreground/background/logout handling and device/browser receipt still require verification. iPhone/APNs readiness is not established.
4. **Private booking/review media:** migrate remaining legacy inline/HMAC media paths to owned private objects with bounded decoding/upload/access and failure handling. Professional documents/avatars do not close this separate scope.
5. **Mobile lifecycle issues:** Android image-picker lost-data recovery, monotonic offer countdown/resume handling and any uncovered cross-tab/session races.
6. **Favorites and repeat booking:** approved for actual services/professionals, using current service prices/availability rather than copied stale booking prices.
7. **Complaints:** create and follow status, optional private images, appropriate administration visibility and actual updates.
8. **Professional working days and leave:** real availability/schedule controls wired into eligible dispatch, without overwriting existing bookings.
9. **Account deletion and data controls:** clear user flow, protected identity confirmation, retention/deletion behavior and administrative-owner constraints; not a destructive blanket cleanup.
10. **Remaining catalog controls:** custom service creation and safe deactivation; existing draft editing/publication is already implemented.
11. **Full security/code/design review:** finish the frozen incomplete audit and validate unresolved findings. Development regression suites do not independently complete audit coverage. Recheck dependency advisories rather than declaring all dependencies clean.
12. **Final integration/release validation:** integrate the original/Gemini branch without discarding work; real Android/Web end-to-end verification; iPhone runtime, permissions, APNs and signing/release readiness within the free-only constraint. Do not imply paid Apple distribution is free.

## Explicit incomplete request/tradeoff

Login field format/empty/length errors are specific, but incorrect phone/password credentials remain a combined message to avoid revealing whether an account exists. This is not the separately worded unknown-phone/wrong-password behavior requested by the user; keep the distinction visible rather than marking it fulfilled verbatim.

## Latest verified delivery

- Source release8217fb0; release notes4673c6d, pushed on fixo-admin-profile.
- API: https://fixo-api.vercel.app, deployment dpl_E7qEa8T3W2g7kYRRjGXTaHVSsA8X.
- Web: https://fixo-web-blue.vercel.app, deployment dpl_CJi3JsxLFzHKwZ5fjQqYtqPnwmko.
- 314backend tests/39suites and361Flutter tests passed, with2existing opt-in skips; lint/analyze/backend and Web builds passed. 19focused administration UI checks passed.
- New private table RLS and actual restricted backend-role reads verified. Public catalog remains8services/6categories;138new drafts have no invented prices. Admin membership initializes only on real verified Owner access.
- Staged/public API readiness and anonymous admin denial verified. Deployed Web artifact hash equals the tested build; administration SPA fallback and legacy cache retirement verified.
- These checks do not establish full authenticated E2E, iPhone delivery, all-device notifications or a clean comprehensive security audit.

Detailed evidence: superpowers/plans/2026-11-03-private-admin.md and superpowers/plans/2026-11-02-admin-profile-egypt.md.

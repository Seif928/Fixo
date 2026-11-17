# Phone/password and free map change

User approved: no SMS; first registration proves Google identity, then captures name, Egyptian phone alias and a new FIXO password once. Later sign-in uses phone/password. Passwords remain in Firebase Auth, never in Prisma. The phone is an unverified username, not proof of phone ownership. Preserve the existing authenticated user ID and never merge existing accounts merely because a phone matches.

Implement backend phone/password gateway using Firebase's documented REST signInWithPassword endpoint. Resolve the email privately on the server; never expose a phone-to-email resolver. Verify the returned Firebase ID token and ensure its UID matches the phone's already-linked account. Generic failures, bounded requests, no credential logging. Complete first profile through a JWT-protected, transactional endpoint; do not let repeated setup overwrite another account or established profile.

Flutter: add a separate native Screen 02 variant to avoid overwriting Gemini's ongoing presentation work. Google first-use -> required profile/password setup -> home. Phone/password for returning users. Email recovery remains available. Keep sandbox OTP tooling only for explicit local tests; remove it from the normal user flow.

Free map: OpenFreeMap vector tiles/styles with MapLibre; no account, card, API key or billing. Display required attribution. Let the user explicitly pick a real coordinate; never fabricate a location from the address text. Existing backend address latitude/longitude fields can persist the selection. Keep address search/GPS and routing distinct from displaying map tiles; do not claim those APIs exist until implemented.

Verify backend ownership, UID mismatch, missing account, unavailable Firebase, one-time setup, phone conflicts and concurrent requests. Verify client login/setup routing and no SMS calls. Re-run appropriate suites before deployment/push. Gemini's completed presentation work has now been integrated and the Web build passes; see CONNECTED_SERVICES_STATUS.md for current evidence and remaining runtime checks.

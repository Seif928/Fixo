# Premium entry screens

User confirmed Google works and requested the appearance of the former Supabase/Next.js entry screens. Implement the approved visual reference as native Flutter: slate canvas, white bordered surface, amber accent and centered compact identity/form. Reuse existing Google/email/phone/profile-setup actions, keys and validation. Keep customer/pro intent and session persistence. Light/dark, Arabic/English, 360/390/412dp and large text remain supported. No provider or permission changes and no perpetual effects.

The previous Next.js source at 6115723 is the visual reference explicitly selected by the owner. Only onboarding and login/registration presentation are in scope; the shared app theme outside entry screens is unchanged. Existing responsive and authentication tests plus reviewed entry-screen goldens will verify this change.

Owner follow-up: replaced entry support copy with all Egyptian governorates; actual bookable coverage still comes from the server. Customer marketplace, professional jobs/earnings workspace and administration remain separate. Live read-only verification found the requested account has an active linked OWNER membership. ADMIN cannot manage memberships; only OWNER can. No grants or roles were changed from the client.

All entry logos now use FixoBrandMark. tool/export_brand_assets.dart renders that same Flutter crest into Web/PWA, Android launcher and iOS AppIcon assets. No new logo variant or paid asset dependency.

Validation: 598 Flutter tests passed, 2 existing opt-in skips; reviewed and updated six changed entry goldens; brand export passed; final analyzer has no issues. Android debug build passed. iOS assets updated; native iOS compilation requires macOS and was not run.

Final Web release build passed. Google functionality was confirmed by the owner before styling; no external Google sign-in was performed as part of this visual change.

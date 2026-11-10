# Apple sign-in platform restriction

User requested Apple registration on iPhone only. The current Flutter client now exposes Apple sign-in only on native TargetPlatform.iOS, never on Flutter Web, Android, macOS, Windows, Linux or Fuchsia. This is a native iOS policy (including the existing iPad-compatible iOS target), not user-agent detection for Safari.

- Central policy in core/auth/platform_auth_capabilities.dart, used by phone/password, email and legacy phone-auth screens.
- EmailAccessService rejects unsupported direct Apple calls before Firebase initialization or OAuth prompts. This client platform check is not a backend authorization boundary.
- Google and ordinary phone/password/email entry remain unchanged. The legacy Apple button no longer misleadingly says “Apple or Google”.
- Added Runner.entitlements with com.apple.developer.applesignin Default, linked in Debug/Release/Profile, plus the Xcode Sign in with Apple capability. XML and all three links verified locally.
- Platform tests exercise six native platform policies plus Web-on-each-platform rejection; widget variants prove Apple remains visible on iOS and absent on Android/macOS while Google stays visible. Unsupported direct service call rejects without starting Firebase.
- Flutter analyze clean; 559 tests passed, two deliberate live opt-in skips. Four changed login golden references were visually inspected before updating. No backend source, database schema or provider settings changed.

## Remaining activation

This does not establish working native Apple OAuth. Apple Developer/App ID/provisioning, provider credentials/configuration and macOS/Xcode/real iOS verification remain required. No membership, billing or credentials were created. Reference: https://firebase.google.com/docs/auth/flutter/federated-auth#apple .

The separate Clerk-hosted DEVELOPMENT portal is not the Flutter app. Its existing Apple connection was not disabled globally: doing so would also affect any future native Clerk flow. When the Clerk-to-FIXO identity exchange and client integration are completed, the same client platform policy must govern its entry points. Do not claim the hosted test portal is already platform-filtered or the production FIXO login already uses Clerk.

Other remaining delivery work is unchanged: Clerk identity linking/session revocation and role continuity, actual push/photo/device verification, iOS runtime and merchant/Apple production activation. NestJS remains the live API; the Dart rewrite stays stopped.

## Released

Source bc4837e pushed; Web release and ordinary Android debug APK builds passed. Vercel deployment dpl_C7GCCrBbKZTx5C6MdioyqfrVaY3x is Ready at https://fixo-web-blue.vercel.app; Firebase mirror also released. Tested/Vercel/Firebase main.dart.js SHA256 matches C56ABBBC581FCB302ABD9B52AABEA00C10507713DAD800AFCC8F2F0ADA183E0B. Real browser inspection of the stable phone-login route showed Google and phone/password controls with no Apple entry. iOS visibility was verified with widget platform variants, not a real iPhone or macOS build.

# FIXO · Flutter application

One Flutter/Dart client for Android, iOS, web and administration, with separate customer, professional and administrative workspaces. Supports Arabic/English, RTL/LTR, light/dark themes and responsive layouts.

See the [main README](../../README.md) for architecture, Firebase/Supabase configuration, screenshots and delivery status.

## Run locally

From this directory, with a configured FIXO backend on port `3001`:

```powershell
flutter pub get
flutter run -d chrome --dart-define=FIXO_USE_LOCAL_API=true
```

For a selected Android emulator:

```powershell
flutter run --dart-define=FIXO_USE_LOCAL_API=true
```

The local flag uses `10.0.2.2:3001` on Android and `localhost:3001` elsewhere. Use `--dart-define=FIXO_API_BASE_URL=http://YOUR_LAN_IP:3001/api/v1` for a physical device. Without overrides, the client uses the hosted API.

## Verify

```powershell
flutter analyze
flutter test
```

The visual system lives in [`../DESIGN.md`](../DESIGN.md). Firebase configuration must match your platform registrations. Service-account and Supabase service-role credentials belong only on the server.

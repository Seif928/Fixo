# Local booking UI verification

This is an opt-in Flutter widget integration test against a real local PostgreSQL API. It is **not Chrome/device E2E or Google/password sign-in verification**. The legacy filename is retained for existing commands.

## Isolation

- Requires an existing migrated `fixo_test` database on localhost port 5432.
- `backend/scripts/local-ui-verification.ts` rejects non-test mode, validates the test database URL, verifies `current_database()`, seeds only the test catalog, and listens on **127.0.0.1:3002**.
- The write-capable Flutter suite independently rejects any target except HTTP loopback port 3002 with `/api/v1`.
- `FIXO_LIVE_API=true` (the read-only catalog opt-in) no longer enables this write-capable suite. Only `FIXO_LIVE_WEB_E2E=true` does.
- The authenticated fixture uses the development OTP API on this isolated backend. OS token storage is replaced with temporary memory storage in the widget VM. The real app/router, HTTP repositories, controllers, backend authorization and database persistence remain in use.
- No Firebase account, payment provider, production booking, or production database write is involved.

## Start the local API

From `Fixo/backend`, in PowerShell, after Docker/PostgreSQL is healthy:

```powershell
$env:NODE_ENV='test'
$env:FIXO_TEST_FORCE_PRISMA='true'
$env:TEST_DATABASE_URL='postgresql://fixo_user:fixo_dev_password@localhost:5432/fixo_test?schema=public'
$env:DATABASE_URL=$env:TEST_DATABASE_URL
$env:JWT_ACCESS_SECRET=[Guid]::NewGuid().ToString('N')+[Guid]::NewGuid().ToString('N')
$env:JWT_REFRESH_SECRET=[Guid]::NewGuid().ToString('N')+[Guid]::NewGuid().ToString('N')
$env:OTP_HMAC_SECRET=[Guid]::NewGuid().ToString('N')+[Guid]::NewGuid().ToString('N')
$env:SMS_PROVIDER_TYPE='DEV_SANDBOX_SMS'
$env:ALLOW_DEV_SMS='true'
$env:ALLOW_TEST_FIXED_OTP='true'
$env:ALLOW_IN_MEMORY_FALLBACK='false'
node -r ts-node/register scripts/local-ui-verification.ts
```

The example connection credentials are the local Docker development values, not production credentials. Stop this API with Ctrl+C after testing. Never point the harness at Supabase or deploy it as an API entrypoint.

## Run the UI integration

From `Fixo/mobile`, in a separate terminal:

```powershell
flutter test --no-pub test/web_booking_checkout_flow_test.dart --plain-name "Local booking UI:" --dart-define=FIXO_LIVE_WEB_E2E=true --dart-define=FIXO_API_BASE_URL=http://localhost:3002/api/v1
```

The test selects an actual seeded offering, saves a synthetic address through the current governorate picker, opens the full calendar, chooses a date fourteen days ahead and 21:45, creates a draft through the UI, confirms cash checkout, returns home, and reopens the same checkout route. It verifies persisted date/time, `PENDING_DISPATCH`, a `PENDING` cash payment with null `paidAt`, and the same payment ID after retry.

## Verified on 2026-11-10

- Local UI integration: passed.
- Independent PostgreSQL query for the tested booking: database `fixo_test`, time `21:45`, status `PENDING_DISPATCH`, one payment and one pending unpaid cash payment.
- Regression reproduced before the application fix: the saved-address snackbar covered the confirmation button. The footer now uses `Scaffold.bottomNavigationBar`, reserving space above it for snackbars.
- Draft-success notification no longer follows navigation to checkout, where it previously covered the return-home action. Standalone callers retain their fallback notice.
- Full offline Flutter suite after the fix: 543 passed, two explicit live opt-ins skipped; analysis clean.

Native provider login, OS push display, iOS and production end-to-end bookings require separate verification and are not implied by this result.

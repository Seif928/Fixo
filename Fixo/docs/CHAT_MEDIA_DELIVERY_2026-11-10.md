# Chat photos and push session correction

## Implemented

- Replace the inert booking-chat attachment icon with camera/library selection and a preview requiring explicit Send. Cancel never uploads. Unassigned/inactive bookings remain read-only.
- Reuse the existing private storage service and existing ChatMessage attachment column; no schema migration, public bucket or new paid service.
- Bound multipart requests to one photo, 2 MB and zero extra fields. Decode/re-encode JPEG/PNG/WebP to metadata-stripped WebP with bounded pixel dimensions before storage.
- Check participant authorization before decoding and again under the booking row lock before persistence; require an assigned professional and active confirmed booking.
- Store a generated private key, never a client URL. Hide the key in message responses; download through an authenticated booking/message route with private/no-store and nosniff headers.
- Clean uploaded objects on failed database persistence. Notification errors do not turn persisted photo messages into apparent send failures. Refresh/check before a manual retry after an ambiguous timeout; automatic photo retries are not enabled.
- Android interrupted photo selection is scoped to the account/booking and offered for review before sending. Expired or cross-account recovery is handled by the existing picker.
- Evict preview/message photos from Flutter's decoded-image cache on completion/disposal.
- Reproduce and fix push enable/logout race: check current account and session generation before Firebase setup, permission request and token generation.

## Verification

- Backend: 55 suites, 493 tests passed; TypeScript check and Nest build passed.
- Flutter: 545 passed, two opt-in live suites skipped. These skips do not stand in for device/live testing.
- New tests include unauthorized and inactive uploads, normalization/private-key hiding, failed-persistence cleanup, participant-only reads, multipart size/extra-field rejection, authenticated HTTP headers, real PostgreSQL persistence with an in-memory storage substitute, preview cancel/send/display and stale notification permission prevention.
- Chat English/light and Arabic/dark golden references were inspected and updated for the intentional attachment control change only.
- Initial full backend invocation omitted required auth environment variables; another invocation incorrectly forced Prisma for an in-memory fixture. Neither was an application regression. The final full run used explicit local test credentials and let each suite choose its intended test persistence; all passed.

## Remaining evidence and limits

- Cloud private storage and authenticated native camera/notification receipt still need actual authorized runtime verification. No production media, real identity documents or bookings were created for this verification.
- Camera availability and permission handling depend on the device/browser. No iOS runtime proof is claimed.
- Attachments apply to booking participant chat. Administrator support chat remains a separate text workflow.
- Existing free storage quota applies; this feature is not unlimited storage and does not enable billing.
- See REMAINING_2026-11-10.md for the wider unresolved product/account/device work. This delivery is not a claim that all requested integrations or a comprehensive security audit are complete.

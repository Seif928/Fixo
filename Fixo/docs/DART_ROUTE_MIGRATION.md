# Dart API migration route checklist

Generated from legacy decorators; manually confirm dynamic/implicit routes before cutover.
Readiness is deliberately blocked until migration is complete.

| Route | Dart implementation |
| --- | --- |
| `GET /api/v1/admin/me` | Pending |
| `GET /api/v1/admin/members` | Pending |
| `GET /api/v1/admin/summary` | Pending |
| `PUT /api/v1/admin/member` | Pending |
| `DELETE /api/v1/admin/member` | Pending |
| `GET /api/v1/admin/audit` | Pending |
| `GET /api/v1/admin/bookings` | Pending |
| `GET /api/v1/admin/bookings/:id` | Pending |
| `GET /api/v1/admin/bookings/:id/candidates` | Pending |
| `POST /api/v1/admin/bookings/:id/cancel` | Pending |
| `POST /api/v1/admin/bookings/:id/offer` | Pending |
| `GET /api/v1/admin/catalog` | Pending |
| `POST /api/v1/admin/catalog` | Pending |
| `PUT /api/v1/admin/catalog/:id` | Pending |
| `POST /api/v1/admin/catalog/:id/publish` | Pending |
| `POST /api/v1/admin/catalog/:id/deactivate` | Pending |
| `POST /api/v1/admin/catalog/:id/reactivate` | Pending |
| `GET /api/v1/admin/professionals` | Pending |
| `GET /api/v1/admin/professionals/:id` | Pending |
| `PATCH /api/v1/admin/professionals/:id/review` | Pending |
| `GET /api/v1/admin/professionals/:id/documents/:docId/content` | Pending |
| `POST /api/v1/auth/otp/request` | Pending |
| `POST /api/v1/auth/otp/verify` | Pending |
| `POST /api/v1/auth/refresh` | Pending |
| `POST /api/v1/auth/logout` | Pending |
| `POST /api/v1/auth/phone-password` | Pending |
| `PATCH /api/v1/auth/phone-alias` | Pending |
| `POST /api/v1/auth/first-profile` | Pending |
| `POST /api/v1/bookings` | Pending |
| `GET /api/v1/bookings` | Pending |
| `GET /api/v1/bookings/:id` | Pending |
| `POST /api/v1/bookings/:bookingId/checkout` | Pending |
| `GET /api/v1/bookings/:bookingId/tracking` | Pending |
| `POST /api/v1/bookings/:bookingId/cancel` | Pending |
| `GET /api/v1/bookings/:bookingId/receipt` | Pending |
| `GET /api/v1/bookings/:bookingId/review` | Pending |
| `POST /api/v1/bookings/:bookingId/review` | Pending |
| `POST /api/v1/uploads/private` | Pending |
| `GET /api/v1/uploads/private/verify` | Pending |
| `POST /api/v1/bookings/:bookingId/messages/photo` | Pending |
| `GET /api/v1/bookings/:bookingId/messages/:messageId/photo` | Pending |
| `GET /api/v1/bookings/:bookingId/messages` | Pending |
| `POST /api/v1/bookings/:bookingId/messages` | Pending |
| `PATCH /api/v1/bookings/:bookingId/messages/:messageId/read` | Pending |
| `GET /api/v1/users/me/notifications` | Pending |
| `PATCH /api/v1/users/me/notification-preferences` | Pending |
| `GET /api/v1/users/me/push-status` | Pending |
| `POST /api/v1/users/me/push-devices` | Pending |
| `DELETE /api/v1/users/me/push-devices/:id` | Pending |
| `POST /api/v1/complaints` | Pending |
| `GET /api/v1/complaints/my` | Pending |
| `GET /api/v1/complaints/:id` | Pending |
| `GET /api/v1/admin/complaints` | Pending |
| `GET /api/v1/admin/complaints/:id` | Pending |
| `PATCH /api/v1/admin/complaints/:id/status` | Pending |
| `GET /api/v1/favorites/ids` | Pending |
| `GET /api/v1/favorites/services` | Pending |
| `POST /api/v1/favorites/services/:offeringId` | Pending |
| `DELETE /api/v1/favorites/services/:offeringId` | Pending |
| `GET /api/v1/favorites/professionals` | Pending |
| `POST /api/v1/favorites/professionals/:proProfileId` | Pending |
| `DELETE /api/v1/favorites/professionals/:proProfileId` | Pending |
| `GET /api/v1/health` | Implemented (readiness cutover gate remains closed) |
| `GET /api/v1/health/ready` | Implemented (readiness cutover gate remains closed) |
| `POST /api/v1/users/me/avatar` | Pending |
| `GET /api/v1/users/me/avatar` | Pending |
| `GET /api/v1/pro/schedule` | Pending |
| `PUT /api/v1/pro/schedule` | Pending |
| `POST /api/v1/pro/leaves` | Pending |
| `DELETE /api/v1/pro/leaves/:id` | Pending |
| `GET /api/v1/pro/catalog-options` | Pending |
| `GET /api/v1/pro/me` | Pending |
| `POST /api/v1/pro/onboarding/personal` | Pending |
| `PUT /api/v1/pro/onboarding/skills` | Pending |
| `POST /api/v1/pro/onboarding/documents` | Pending |
| `GET /api/v1/pro/onboarding/documents/:docId/access` | Pending |
| `GET /api/v1/pro/onboarding/documents/:docId/content` | Pending |
| `POST /api/v1/pro/onboarding/submit` | Pending |
| `GET /api/v1/pro/onboarding/status` | Pending |
| `PATCH /api/v1/pro/admin/profiles/:proProfileId/review` | Pending |
| `PATCH /api/v1/pro/availability` | Pending |
| `GET /api/v1/pro/dashboard` | Pending |
| `GET /api/v1/pro/job-offers/:offerId` | Pending |
| `POST /api/v1/pro/job-offers/:offerId/accept` | Pending |
| `POST /api/v1/pro/job-offers/:offerId/decline` | Pending |
| `POST /api/v1/pro/bookings/:bookingId/status` | Pending |
| `GET /api/v1/bookings/:id/repeat-quote` | Pending |
| `GET /api/v1/professionals` | Pending |
| `GET /api/v1/services/categories` | Implemented (readiness cutover gate remains closed) |
| `GET /api/v1/services` | Pending |
| `GET /api/v1/services/:id` | Pending |
| `PATCH /api/v1/users/me/profile` | Pending |
| `GET /api/v1/users/me` | Pending |
| `POST /api/v1/users/me/addresses` | Pending |
| `GET /api/v1/users/me/addresses` | Pending |
| `POST /api/v1/users/me/delete-account` | Pending |

96 explicitly decorated routes; 3 initial ports. Protected business flows are not migrated.

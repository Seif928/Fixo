# Payment and Apple activation handoff

Status: account setup pending. No live electronic payment acceptance is enabled.

## Merchant account
Create/verify a merchant account in a supported Egyptian payment provider (Paymob is one candidate; final provider choice remains open). Confirm settlement bank details, merchant documents, supported methods, refunds and transaction fees directly with the provider. No billing enrollment is authorized by this document.

Paymob Apple Pay supports Egypt and uses Live integration IDs only. Embedded/SDK integrations require certificates; embedded web integration also requires domain verification. Do not pretend test IDs prove Apple Pay acceptance.
Reference: https://developers.paymob.com/paymob-docs/payments-and-features/payment-methods/apple-pay-all-regions

After merchant approval, configure server credentials through the hosting secret manager, never through chat, Git or Flutter assets. The gateway adapter is NOT implemented yet because no provider/account is selected. It must create hosted checkout from server-calculated booking totals, validate return URLs, verify signed provider webhooks and amount/currency/order ownership, and process duplicate/delayed events idempotently. Browser redirects alone never mark a booking paid. Keep cash checkout operational. Enable only methods actually approved for this merchant/device.

Acceptance: success, rejection, abandonment, webhook retry, forged signature, mismatched total/currency, cancellation and refund. Real money tests require explicit agreement after account setup.

## Sign in with Apple
Existing Flutter provider flow and Nest token verification are implemented. Enable Apple in Firebase only after Apple Developer membership, App ID capability, Services ID, web domain/return URL and signing key configuration are ready. Confirm current Firebase callback URL in the console. Private keys stay in Firebase/provider configuration. Native iOS requires capability/entitlements and macOS build verification. Never fabricate an email/session on OAuth failure.
Reference: https://firebase.google.com/docs/auth/flutter/federated-auth

User action: complete Apple and merchant onboarding themselves when available; provide account availability and provider name only in chat. No password, key or OTP is required in chat.

## Presentation
Keep unavailable payment methods out of the customer checkout until configured. Preserve accurate cash timing and the actual receipt. Remove duplicate technical badges, obsolete provider promises and legacy green brand accents. These refinements are local until separately built and deployed.

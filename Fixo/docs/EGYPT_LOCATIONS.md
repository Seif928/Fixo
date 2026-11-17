# Egypt location catalog

The offline picker includes 27 governorates, 365 districts and 5,716 localities from
[Open Admin Data](https://github.com/open-admin-data/egypt-administrative-divisions),
revision `76b47b22872288c0d8b0c757975980e6986945e8`.
Copyright 2026 jakkrapongt, licensed under
[Creative Commons Attribution 4.0](https://creativecommons.org/licenses/by/4.0/).
The original license is bundled at `mobile/assets/locations/LICENSE.txt`.

FIXO converted the source into a compact bilingual parent/child name index, normalized
governorate names and added stable application slugs. Coordinates, postal codes and
upstream website metadata were omitted. Duplicate IDs, empty names, governorate
membership and parent levels were checked during conversion.

This is an open name catalog, not an official guarantee of current administrative
boundaries or exhaustive village coverage. Users can always enter missing/new places
manually. Catalog coordinates must never become a user's selected service address.
Governorate selection also does not promise available technicians: discovery uses
actual approved technician coverage. Coverage seed changes are explicit, idempotent
and preserve administrator edits; ordinary catalog requests perform no writes.

GPS is one-shot and optional, requested only from the Detect action. Android uses
foreground coarse/fine location; iOS declares When In Use only. No background stream
is started. Area detection sends rounded (3 decimal) coordinates to the server in a
POST body and to configurable HTTPS reverse geocoding. Nominatim default requests have
a FIXO User-Agent, 5-second timeout, Arabic response and a 128KB response cap. PostgreSQL
gates enforce 30 seconds per user and 1.1 seconds globally across serverless instances.
Area results cache for 30 days, capped at approximately 5,000 rows with bounded cleanup.
No search-as-you-type requests are made: all city/village search is offline. Provider
attribution is displayed in the picker. Denial, provider failure, outside-Egypt or an
unknown governorate preserve the manual flow. GPS does not silently save an address.

Provider operations: set `GEOCODING_ENABLED=false` to disable reverse lookup or
`GEOCODING_REVERSE_URL` to an alternative compatible HTTPS provider. No key, billing
or paid plan is required for the default development setup. Respect
[Nominatim's usage policy](https://operations.osmfoundation.org/policies/nominatim/).

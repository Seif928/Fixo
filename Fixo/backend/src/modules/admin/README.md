# Private administration access foundation

The user approved two-person membership independent of `User.role`: slot1 is Owner, slot2 is Admin. Both may perform future operations; only Owner may replace/revoke the second member. Invites expire after7days and require the matching currently verified Firebase identity. Mutation authority is rechecked under a shared database lock and audit creation is transactional. Fresh confirmation uses403/ADMIN_REAUTH_REQUIRED so the app does not mistake it for an expired access token.

Implemented here: access resolution, membership APIs and latest20audit events. Not implemented yet: dashboard UI and professional/catalog/booking operation endpoints. Before a development deployment, apply migration20261103020000_private_admin_access and configure server-only FIXO_OWNER_EMAIL. Before enabling operations, convert legacy reviewer/document entry points to this membership boundary, prohibit self-review, and keep decisions/audits in one transaction. Never infer authority from app ADMIN/PRO roles or auto-approve real dossiers.

This increment has been tested only locally. No live owner membership or friend invite has been created. No new paid service is required. The user wants the dashboard layout choice before frontend implementation.

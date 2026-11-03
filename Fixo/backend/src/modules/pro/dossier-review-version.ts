import { createHash } from 'crypto';

/** Includes private object revisions in the digest without returning their references. */
export function dossierReviewVersion(profile: {
  id: string;
  updatedAt: Date;
  verificationStatus: string;
  documents: {
    id: string;
    docType: string;
    status: string;
    uploadedAt: Date;
    storageKey: string;
  }[];
}) {
  return createHash('sha256')
    .update(
      JSON.stringify([
        profile.id,
        profile.updatedAt.toISOString(),
        profile.verificationStatus,
        [...profile.documents]
          .sort((a, b) => a.id.localeCompare(b.id))
          .map((d) => [
            d.id,
            d.docType,
            d.status,
            d.uploadedAt.toISOString(),
            d.storageKey,
          ]),
      ]),
    )
    .digest('hex');
}

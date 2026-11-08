import { CATALOG_DRAFT_GROUPS, CATALOG_DRAFTS } from './admin-catalog.seed';
import { EGYPT_SERVICE_OFFERINGS } from '../../prisma/egypt-demo-seed.data';
describe('Curated private home-services draft catalog', () => {
  it('covers the approved home-service groups with unique bilingual entries and no prices or fabricated public offers', () => {
    expect(CATALOG_DRAFT_GROUPS).toHaveLength(21);
    expect(CATALOG_DRAFTS.length).toBeGreaterThan(100);
    expect(new Set(CATALOG_DRAFTS.map((d) => d.slug)).size).toBe(
      CATALOG_DRAFTS.length,
    );
    const published = new Set(EGYPT_SERVICE_OFFERINGS.map((d) => d.slug));
    for (const draft of CATALOG_DRAFTS) {
      expect(published.has(draft.slug)).toBe(true);
      expect(draft.titleEn.trim().length).toBeGreaterThan(3);
      expect(draft.titleAr).toMatch(/[\u0600-\u06ff]/);
      expect(draft).not.toHaveProperty('baseInspectionEgp');
      expect(draft).not.toHaveProperty('serviceFeeEgp');
      expect(draft).not.toHaveProperty('offeringId');
    }
  });
});

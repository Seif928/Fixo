import { EGYPT_SERVICE_OFFERINGS } from "./egypt-demo-seed.data";
import { CATALOG_DRAFT_GROUPS } from "../modules/admin/admin-catalog.seed";

it("keeps owner-unpriced catalog drafts out of the public seed", () => {
  const draftSlugs = new Set(
    CATALOG_DRAFT_GROUPS.flatMap((g) =>
      g.services.map(([key]) => `home-${key}`),
    ),
  );
  expect(EGYPT_SERVICE_OFFERINGS.filter((o) => draftSlugs.has(o.slug))).toEqual(
    [],
  );
});

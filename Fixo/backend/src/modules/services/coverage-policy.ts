import { Prisma } from '@prisma/client';
import { EGYPT_GOVERNORATES } from '../../prisma/egypt-governorates';

export interface CoverageArea {
  id?: string;
  slug: string;
  governorate: string;
  isActive?: boolean;
}

function wholeGovernorate(area: CoverageArea) {
  return EGYPT_GOVERNORATES.find(
    (g) => g.slug === area.slug && g.governorate === area.governorate,
  );
}

/** An approved district never silently becomes coverage of the entire governorate. */
export function coversServiceArea(
  coverage: CoverageArea,
  target: CoverageArea,
): boolean {
  if (coverage.isActive === false || target.isActive === false) return false;
  return Boolean(
    (coverage.id && coverage.id === target.id) ||
      coverage.slug === target.slug ||
      (wholeGovernorate(coverage) &&
        coverage.governorate === target.governorate),
  );
}

export function professionalCoverageWhere(
  target: CoverageArea,
): Prisma.ProProfileWhereInput {
  if (target.isActive === false) return { OR: [] };
  const governorate = EGYPT_GOVERNORATES.find(
    (g) => g.governorate === target.governorate,
  );
  const slugs = [target.slug, ...(governorate ? [governorate.slug] : [])];
  const zone: Prisma.CoverageZoneWhereInput = {
    isActive: true,
    slug: { in: slugs },
  };
  return { OR: [{ primaryZone: zone }, { coverageZones: { some: zone } }] };
}

export function addressCoverageWhere(
  areas: CoverageArea[],
): Prisma.CustomerAddressWhereInput {
  const active = areas.filter((a) => a.isActive !== false);
  const governorates = active
    .filter((a) => wholeGovernorate(a))
    .map((a) => a.governorate);
  return {
    OR: [
      { zone: { isActive: true, slug: { in: active.map((a) => a.slug) } } },
      ...(governorates.length
        ? [{ zone: { isActive: true, governorate: { in: governorates } } }]
        : []),
    ],
  };
}

import { EGYPT_COVERAGE_ZONES } from './egypt-demo-seed.data';

it('provides all 27 governorates without removing existing detailed zones', () => {
  const national = EGYPT_COVERAGE_ZONES.filter((z) => z.id.startsWith('gov-'));
  expect(national).toHaveLength(27);
  expect(new Set(national.map((z) => z.slug)).size).toBe(27);
  expect(
    national.some((z) => z.slug === 'north-sinai' && z.nameAr === 'شمال سيناء'),
  ).toBe(true);
  expect(EGYPT_COVERAGE_ZONES.some((z) => z.slug === 'sheikh-zayed')).toBe(
    true,
  );
});

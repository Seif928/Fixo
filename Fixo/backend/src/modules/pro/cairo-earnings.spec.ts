import { cairoDateKey, cairoWeekKeys } from './cairo-earnings';

describe('Egypt calendar earnings windows', () => {
  it('uses Cairo midnight in winter and summer, rather than UTC midnight', () => {
    expect(cairoDateKey(new Date('2026-11-02T21:59:59Z'))).toBe('2026-11-02');
    expect(cairoDateKey(new Date('2026-11-02T22:00:00Z'))).toBe('2026-11-03');
    expect(cairoDateKey(new Date('2026-07-02T21:00:00Z'))).toBe('2026-07-03');
  });
  it('keeps seven distinct civil days over the daylight-saving transition', () => {
    expect(cairoWeekKeys(new Date('2026-10-31T23:00:00Z'))).toEqual([
      '2026-10-26',
      '2026-10-27',
      '2026-10-28',
      '2026-10-29',
      '2026-10-30',
      '2026-10-31',
      '2026-11-01',
    ]);
  });
});

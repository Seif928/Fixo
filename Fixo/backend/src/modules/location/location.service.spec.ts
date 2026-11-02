import { LocationService } from './location.service';

describe('Privacy-aware area reverse lookup', () => {
  let service: LocationService;
  let db: any;
  beforeEach(() => {
    db = {
      isDatabaseConnected: () => true,
      $queryRaw: jest.fn().mockResolvedValue([{ key: 'ok' }]),
      $executeRaw: jest.fn(),
      geoLookupCache: {
        findUnique: jest.fn().mockResolvedValue(null),
        upsert: jest.fn(),
        deleteMany: jest.fn(),
      },
      coverageZone: {
        findUnique: jest.fn().mockResolvedValue({ isActive: true }),
      },
    };
    service = new LocationService(db);
    jest.spyOn(global, 'fetch').mockResolvedValue(
      new Response(
        JSON.stringify({
          address: {
            country_code: 'eg',
            state: 'محافظة الجيزة',
            city: 'الشيخ زايد',
          },
        }),
      ),
    );
  });
  afterEach(() => jest.restoreAllMocks());
  it('returns actual governorate/locality with rounded provider coordinates', async () => {
    const result = await service.reverse('user-id', 30.045987, 31.012345);
    expect(result.area.zoneSlug).toBe('giza');
    expect(result.area.localityAr).toBe('الشيخ زايد');
    const url = new URL(String((fetch as jest.Mock).mock.calls[0][0]));
    expect(url.searchParams.get('lat')).toBe('30.046');
    expect(url.searchParams.get('lon')).toBe('31.012');
    expect(
      (fetch as jest.Mock).mock.calls[0][1].headers['User-Agent'],
    ).toContain('FIXO');
  });
  it('serves cache without making an external request', async () => {
    db.geoLookupCache.findUnique.mockResolvedValue({
      result: { zoneSlug: 'giza' },
      expiresAt: new Date(Date.now() + 60000),
    });
    expect((await service.reverse('user-id', 30, 31)).area).toEqual({
      zoneSlug: 'giza',
    });
    expect(fetch).not.toHaveBeenCalled();
  });
  it('does not call provider when shared/global rate gate refuses', async () => {
    db.$queryRaw.mockResolvedValue([]);
    await expect(service.reverse('user-id', 30, 31)).rejects.toThrow(/wait/i);
    expect(fetch).not.toHaveBeenCalled();
  });
  it('rejects outside Egypt provider results without inventing an area', async () => {
    (fetch as jest.Mock).mockResolvedValue(
      new Response(
        JSON.stringify({ address: { country_code: 'ly', state: 'Giza' } }),
      ),
    );
    await expect(service.reverse('user-id', 30, 31)).rejects.toThrow(/Egypt/i);
    expect(db.geoLookupCache.upsert).not.toHaveBeenCalled();
  });
  it('keeps manual choice available when provider fails or returns unknown state', async () => {
    (fetch as jest.Mock).mockRejectedValue(new Error('network'));
    await expect(service.reverse('user-id', 30, 31)).rejects.toThrow(
      /manually/i,
    );
    (fetch as jest.Mock).mockResolvedValue(
      new Response(
        JSON.stringify({ address: { country_code: 'eg', state: 'unknown' } }),
      ),
    );
    await expect(service.reverse('user-id', 30, 31)).rejects.toThrow(
      /manually/i,
    );
  });
});

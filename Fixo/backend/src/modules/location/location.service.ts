import {
  BadRequestException,
  HttpException,
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { EGYPT_GOVERNORATES } from '../../prisma/egypt-governorates';

@Injectable()
export class LocationService {
  constructor(private readonly prisma: PrismaService) {}
  async reverse(
    userId: string,
    latitude: number,
    longitude: number,
  ): Promise<any> {
    if (
      !Number.isFinite(latitude) ||
      !Number.isFinite(longitude) ||
      latitude < 21.7 ||
      latitude > 32 ||
      longitude < 24.5 ||
      longitude > 37.5
    ) {
      throw new BadRequestException('Choose a service area in Egypt.');
    }
    if (
      !this.prisma.isDatabaseConnected() ||
      process.env.GEOCODING_ENABLED === 'false'
    ) {
      throw this.unavailable();
    }
    // Application-wide gates are stored in PostgreSQL, shared across serverless instances.
    const userGate = await this.prisma.$queryRaw<Array<{ key: string }>>`
      INSERT INTO "GeoRequestGate" ("key", "nextAllowedAt")
      VALUES (${'user:' + userId}, clock_timestamp() + interval '30 seconds')
      ON CONFLICT ("key") DO UPDATE SET "nextAllowedAt" = clock_timestamp() + interval '30 seconds'
      WHERE "GeoRequestGate"."nextAllowedAt" <= clock_timestamp() RETURNING "key"`;
    if (!userGate.length)
      throw new HttpException(
        'Please wait before detecting your area again, or choose it manually.',
        429,
      );
    // Send only area-level, rounded coordinates to the geocoder. No GPS in logs/query routes.
    const lat = latitude.toFixed(3),
      lon = longitude.toFixed(3);
    const key = `ar:v1:${lat}:${lon}`;
    const cached = await this.prisma.geoLookupCache.findUnique({
      where: { key },
    });
    if (cached && cached.expiresAt.getTime() > Date.now())
      return {
        area: cached.result,
        attribution: '© OpenStreetMap contributors',
      };
    const globalGate = await this.prisma.$queryRaw<Array<{ key: string }>>`
      INSERT INTO "GeoRequestGate" ("key", "nextAllowedAt")
      VALUES ('nominatim:global', clock_timestamp() + interval '1100 milliseconds')
      ON CONFLICT ("key") DO UPDATE SET "nextAllowedAt" = clock_timestamp() + interval '1100 milliseconds'
      WHERE "GeoRequestGate"."nextAllowedAt" <= clock_timestamp() RETURNING "key"`;
    if (!globalGate.length)
      throw new HttpException(
        'Please wait a moment, or choose your area manually.',
        429,
      );
    let area: {
      zoneSlug: string;
      governorateEn: string;
      governorateAr: string;
      localityEn: string;
      localityAr: string;
    };
    try {
      const url = new URL(
        process.env.GEOCODING_REVERSE_URL ||
          'https://nominatim.openstreetmap.org/reverse',
      );
      if (url.protocol !== 'https:') throw new Error('HTTPS required');
      url.search = new URLSearchParams({
        lat,
        lon,
        format: 'jsonv2',
        zoom: '14',
        addressdetails: '1',
        'accept-language': 'ar',
      }).toString();
      const response = await fetch(url, {
        signal: AbortSignal.timeout(5000),
        headers: {
          'User-Agent': 'FIXO/1.0 (+https://fixo-web-blue.vercel.app)',
          Accept: 'application/json',
        },
      });
      if (!response.ok || !response.body)
        throw new Error('Provider unavailable');
      const reader = response.body.getReader();
      const chunks: Uint8Array[] = [];
      let size = 0;
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        size += value.length;
        if (size > 128 * 1024) {
          await reader.cancel();
          throw new Error('Response too large');
        }
        chunks.push(value);
      }
      const json = JSON.parse(Buffer.concat(chunks).toString('utf8'));
      const address = json.address;
      if (address?.country_code !== 'eg')
        throw new BadRequestException('Choose a service area in Egypt.');
      const normalize = (s: string) =>
        s
          .toLowerCase()
          .replace(/محافظة/g, '')
          .replace(/[\u064B-\u065F\u0670\u0640]/g, '')
          .replace(/[أإآ]/g, 'ا')
          .replace(/ة/g, 'ه')
          .replace(/ى/g, 'ي')
          .replace(/ governorate/g, '')
          .trim();
      const state =
        typeof address.state === 'string' ? normalize(address.state) : '';
      const governorate = EGYPT_GOVERNORATES.find(
        (g) => normalize(g.nameAr) === state || normalize(g.nameEn) === state,
      );
      if (!governorate) throw new Error('Unknown governorate');
      const zone = await this.prisma.coverageZone.findUnique({
        where: { slug: governorate.slug },
      });
      if (!zone?.isActive) throw new Error('Governorate unavailable');
      const locality =
        [
          address.city,
          address.town,
          address.village,
          address.municipality,
          address.suburb,
        ]
          .find((s) => typeof s === 'string' && s.trim())
          ?.trim()
          .slice(0, 120) ?? '';
      area = {
        zoneSlug: governorate.slug,
        governorateEn: governorate.nameEn,
        governorateAr: governorate.nameAr,
        localityEn: locality,
        localityAr: locality,
      };
    } catch (error) {
      if (error instanceof BadRequestException) throw error;
      throw this.unavailable();
    }
    await this.prisma.geoLookupCache.upsert({
      where: { key },
      create: {
        key,
        result: area,
        expiresAt: new Date(Date.now() + 30 * 86400000),
      },
      update: { result: area, expiresAt: new Date(Date.now() + 30 * 86400000) },
    });
    // Bounded maintenance, no scheduler/paid service and no user IDs in the area cache.
    await this.prisma.$executeRaw`DELETE FROM "GeoLookupCache" WHERE "key" IN (
      SELECT "key" FROM "GeoLookupCache" WHERE "expiresAt" < NOW() LIMIT 50)`;
    await this.prisma.$executeRaw`DELETE FROM "GeoLookupCache" WHERE "key" IN (
      SELECT "key" FROM "GeoLookupCache" ORDER BY "expiresAt" DESC OFFSET 5000 LIMIT 50)`;
    await this.prisma.$executeRaw`DELETE FROM "GeoRequestGate" WHERE "key" IN (
      SELECT "key" FROM "GeoRequestGate" WHERE "nextAllowedAt" < NOW() - interval '1 day' LIMIT 50)`;
    return { area, attribution: '© OpenStreetMap contributors' };
  }
  private unavailable() {
    return new ServiceUnavailableException(
      'Could not detect your area. Please choose it manually.',
    );
  }
}

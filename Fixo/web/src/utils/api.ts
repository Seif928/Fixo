export interface LiveCategory {
  id: string;
  slug: string;
  nameEn: string;
  nameAr: string;
  subtitleEn?: string;
  subtitleAr?: string;
  startingPriceEgp: number;
}

export interface LiveOffering {
  id: string;
  slug: string;
  categoryId: string;
  categorySlug: string;
  titleEn: string;
  titleAr: string;
  descriptionEn: string;
  descriptionAr: string;
  badgeEn?: string | null;
  badgeAr?: string | null;
  flatPriceEgp: number;
  estimatedDurationMins: number;
}

const DEFAULT_API_URL = 'https://fixo-api.vercel.app/api/v1';

export function getApiBaseUrl(): string {
  return (process.env.NEXT_PUBLIC_API_URL || DEFAULT_API_URL).replace(
    /\/+$/,
    '',
  );
}

export async function fetchLiveCatalog(): Promise<{
  categories: LiveCategory[];
  offerings: LiveOffering[];
  connected: boolean;
}> {
  const baseUrl = getApiBaseUrl();

  try {
    const [catRes, offRes] = await Promise.all([
      fetch(`${baseUrl}/services/categories`, {
        next: { revalidate: 60 },
        signal: AbortSignal.timeout(5000),
      }),
      fetch(`${baseUrl}/services?limit=8`, {
        next: { revalidate: 60 },
        signal: AbortSignal.timeout(5000),
      }),
    ]);

    if (!catRes.ok || !offRes.ok) {
      return { categories: [], offerings: [], connected: false };
    }

    const catJson = (await catRes.json()) as { categories?: LiveCategory[] };
    const offJson = (await offRes.json()) as { items?: LiveOffering[] };

    return {
      categories: Array.isArray(catJson.categories) ? catJson.categories : [],
      offerings: Array.isArray(offJson.items) ? offJson.items : [],
      connected: true,
    };
  } catch {
    return { categories: [], offerings: [], connected: false };
  }
}

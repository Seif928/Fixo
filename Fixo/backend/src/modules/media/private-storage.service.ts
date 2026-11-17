import { BadRequestException, Injectable, ServiceUnavailableException } from '@nestjs/common';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

const MAX_BYTES = 2 * 1024 * 1024;

/** Server-only access to a non-public bucket. Callers enforce resource ownership. */
@Injectable()
export class PrivateStorageService {
  private client?: SupabaseClient;
  private readonly bucket = 'fixo-private';

  private storage() {
    if (!this.client) {
      const url = process.env.SUPABASE_URL;
      const key = process.env.SUPABASE_SECRET_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY;
      if (!url || !/^https:\/\/[a-z0-9]{20}\.supabase\.co\/?$/.test(url) || !key) {
        throw new ServiceUnavailableException('Private media storage is not configured.');
      }
      this.client = createClient(url, key, {
        auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
        global: { fetch: (input, options) => fetch(input, { ...options, signal: AbortSignal.timeout(8000) }) },
      });
    }
    return this.client.storage.from(this.bucket);
  }

  private validateKey(key: string) {
    if (!/^(avatars|documents|bookings)\/[a-zA-Z0-9-]+\/[a-zA-Z0-9._-]+$/.test(key) || key.includes('..')) {
      throw new BadRequestException('Invalid private media reference.');
    }
  }

  async put(key: string, bytes: Buffer, mimeType: string): Promise<string> {
    this.validateKey(key);
    if (!bytes.length || bytes.length > MAX_BYTES ||
        !['image/jpeg', 'image/png', 'image/webp', 'application/pdf'].includes(mimeType)) {
      throw new BadRequestException('Unsupported media or file larger than 2 MB.');
    }
    try {
      const { error } = await this.storage().upload(key, bytes, { contentType: mimeType, upsert: false, cacheControl: '0' });
      if (error) throw error;
      return key;
    } catch {
      // Do not include provider messages, credentials, private paths or bytes in responses/logs.
      throw new ServiceUnavailableException('Private media could not be saved. Please retry.');
    }
  }

  async get(key: string): Promise<Buffer> {
    this.validateKey(key);
    try {
      const { data, error } = await this.storage().download(key);
      if (error || !data || data.size > MAX_BYTES) throw new Error('Unavailable');
      return Buffer.from(await data.arrayBuffer());
    } catch {
      throw new ServiceUnavailableException('Private media is temporarily unavailable.');
    }
  }

  async remove(key: string): Promise<void> {
    this.validateKey(key);
    try {
      const { error } = await this.storage().remove([key]);
      if (error) throw error;
    } catch {
      throw new ServiceUnavailableException('Private media could not be removed.');
    }
  }
}

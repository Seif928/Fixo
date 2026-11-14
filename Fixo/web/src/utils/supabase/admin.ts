import { createClient } from '@supabase/supabase-js';

/**
 * Server-only Supabase admin client for reading RLS-protected platform tables
 * after verifying the signed-in user's identity and authorization in SSR routes.
 * Returns null if a service-role/secret key is not configured in the environment.
 */
export function createAdminClient() {
  const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const serviceKey =
    process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_SECRET_KEY;

  if (!supabaseUrl || !serviceKey) {
    return null;
  }

  return createClient(supabaseUrl, serviceKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });
}

const DEFAULT_PRODUCTION_WEB_ORIGINS = [
  'https://fixo-web-blue.vercel.app',
  'https://fixo-home-services-6507.web.app',
  'https://fixo-home-services-6507.firebaseapp.com',
];

const LOCAL_DEV_ORIGIN_PATTERN =
  /^https?:\/\/(localhost|127\.0\.0\.1)(:\d{1,5})?$/i;

export function getAllowedCorsOrigins(
  env: NodeJS.ProcessEnv = process.env,
): string[] {
  const configured = env.CORS_ALLOWED_ORIGINS?.split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);
  if (configured && configured.length > 0) {
    return configured;
  }
  return [...DEFAULT_PRODUCTION_WEB_ORIGINS];
}

export function isAllowedCorsOrigin(
  origin: string | undefined,
  env: NodeJS.ProcessEnv = process.env,
): boolean {
  // Non-browser native mobile clients, health checks, and CLI tools do not send an Origin header.
  if (!origin) {
    return true;
  }
  const normalized = origin.trim();
  const allowed = getAllowedCorsOrigins(env);
  if (allowed.includes('*')) {
    return env.NODE_ENV !== 'production';
  }
  if (allowed.includes(normalized)) {
    return true;
  }
  if (env.NODE_ENV !== 'production' && LOCAL_DEV_ORIGIN_PATTERN.test(normalized)) {
    return true;
  }
  return false;
}

export function shouldExposeSwaggerDocs(
  env: NodeJS.ProcessEnv = process.env,
): boolean {
  if (env.NODE_ENV === 'production') {
    return env.ENABLE_SWAGGER_DOCS === 'true';
  }
  return env.ENABLE_SWAGGER_DOCS !== 'false';
}


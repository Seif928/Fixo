import {
  CanActivate,
  ExecutionContext,
  HttpException,
  HttpStatus,
  Injectable,
  Optional,
  SetMetadata,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Request, Response } from 'express';
import { normalizeEgyptPhone } from '../../modules/auth/utils/egypt-phone.util';

export const RATE_LIMIT_KEY = 'fixo:rate_limit';

export interface RateLimitOptions {
  /** Maximum requests permitted inside `windowMs`. */
  max: number;
  /** Sliding window duration in milliseconds. */
  windowMs: number;
  /** Keying strategy: client IP, authenticated user ID (fallback IP), or both IP and normalized Egyptian phone. */
  keyBy?: 'ip' | 'userOrIp' | 'phoneAndIp';
  /** Optional custom limit for the phone bucket when `keyBy` is `'phoneAndIp'`. */
  phoneMax?: number;
  /** Optional custom window in ms for the phone bucket when `keyBy` is `'phoneAndIp'`. */
  phoneWindowMs?: number;
}

export const RateLimit = (options: RateLimitOptions) =>
  SetMetadata(RATE_LIMIT_KEY, options);

interface BucketEntry {
  timestamps: number[];
}

const MAX_TRACKED_KEYS = 5000;

@Injectable()
export class RateLimitGuard implements CanActivate {
  private static readonly buckets = new Map<string, BucketEntry>();

  constructor(@Optional() private readonly reflector?: Reflector) {}

  static clearAllForTests(): void {
    RateLimitGuard.buckets.clear();
  }

  canActivate(context: ExecutionContext): boolean {
    const reflector = this.reflector ?? new Reflector();
    const options = reflector.getAllAndOverride<RateLimitOptions | undefined>(
      RATE_LIMIT_KEY,
      [context.getHandler(), context.getClass()],
    );
    if (!options) {
      return true;
    }

    const http = context.switchToHttp();
    const request = http.getRequest<
      Request & { user?: { sub?: string }; route?: { path?: string } }
    >();
    const response = http.getResponse<Response>();
    const now = Date.now();
    const routeKey = `${request.method}:${request.baseUrl || ''}${request.route?.path || request.path || ''}`;
    const clientIp = this.extractClientIp(request);
    const keyMode = options.keyBy ?? 'ip';

    const primarySubject =
      keyMode === 'userOrIp' && request.user?.sub
        ? `user:${request.user.sub}`
        : `ip:${clientIp}`;

    const primaryCheck = this.consume(
      `${routeKey}:${primarySubject}`,
      options.max,
      options.windowMs,
      now,
    );

    if (response && typeof response.setHeader === 'function') {
      response.setHeader('X-RateLimit-Limit', String(options.max));
      response.setHeader(
        'X-RateLimit-Remaining',
        String(Math.max(0, options.max - primaryCheck.count)),
      );
    }

    if (!primaryCheck.allowed) {
      if (response && typeof response.setHeader === 'function') {
        response.setHeader('Retry-After', String(primaryCheck.retryAfterSec));
      }
      throw new HttpException(
        'Too many requests. Please wait and try again.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }

    if (keyMode === 'phoneAndIp') {
      const rawPhone =
        typeof (request.body as Record<string, unknown> | undefined)?.phone ===
        'string'
          ? ((request.body as Record<string, unknown>).phone as string)
          : '';
      if (rawPhone) {
        let phoneKey = rawPhone.trim();
        try {
          phoneKey = normalizeEgyptPhone(rawPhone);
        } catch {
          // Malformed phone falls through to ValidationPipe after IP bucket check.
        }
        const phoneCheck = this.consume(
          `${routeKey}:phone:${phoneKey}`,
          options.phoneMax ?? options.max,
          options.phoneWindowMs ?? options.windowMs,
          now,
        );
        if (!phoneCheck.allowed) {
          if (response && typeof response.setHeader === 'function') {
            response.setHeader('Retry-After', String(phoneCheck.retryAfterSec));
          }
          throw new HttpException(
            'Too many sign-in attempts for this account. Please wait before trying again.',
            HttpStatus.TOO_MANY_REQUESTS,
          );
        }
      }
    }

    return true;
  }

  private extractClientIp(request: Request): string {
    if (request.ip) {
      return request.ip;
    }
    return request.socket?.remoteAddress ?? 'unknown';
  }

  private consume(
    key: string,
    max: number,
    windowMs: number,
    now: number,
  ): { allowed: boolean; count: number; retryAfterSec: number } {
    if (
      !RateLimitGuard.buckets.has(key) &&
      RateLimitGuard.buckets.size >= MAX_TRACKED_KEYS
    ) {
      // Evict stale entries first; if still full, drop oldest key.
      for (const [k, entry] of RateLimitGuard.buckets) {
        if (
          entry.timestamps.length === 0 ||
          now - entry.timestamps[entry.timestamps.length - 1] >= windowMs
        ) {
          RateLimitGuard.buckets.delete(k);
        }
      }
      if (RateLimitGuard.buckets.size >= MAX_TRACKED_KEYS) {
        const oldestKey = RateLimitGuard.buckets.keys().next().value;
        if (oldestKey) {
          RateLimitGuard.buckets.delete(oldestKey);
        }
      }
    }

    const entry = RateLimitGuard.buckets.get(key) ?? { timestamps: [] };
    const cutoff = now - windowMs;
    entry.timestamps = entry.timestamps.filter((ts) => ts > cutoff);

    if (entry.timestamps.length >= max) {
      RateLimitGuard.buckets.set(key, entry);
      const oldestInWindow = entry.timestamps[0] ?? now;
      const retryAfterSec = Math.max(
        1,
        Math.ceil((oldestInWindow + windowMs - now) / 1000),
      );
      return {
        allowed: false,
        count: entry.timestamps.length,
        retryAfterSec,
      };
    }

    entry.timestamps.push(now);
    RateLimitGuard.buckets.set(key, entry);
    return {
      allowed: true,
      count: entry.timestamps.length,
      retryAfterSec: 0,
    };
  }
}


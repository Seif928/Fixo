import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { AuthService } from '../auth.service';
import { FixoJwtPayload } from '../utils/jwt-token.util';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(private readonly authService: AuthService) {}

  canActivate(context: ExecutionContext): boolean | Promise<boolean> {
    const request = context.switchToHttp().getRequest<{
      headers?: Record<string, string | string[] | undefined>;
      user?: FixoJwtPayload;
    }>();

    const authHeader = request.headers?.authorization ?? request.headers?.Authorization;
    if (!authHeader || typeof authHeader !== 'string') {
      throw new UnauthorizedException('Authorization Bearer token is required.');
    }

    const [scheme, token] = authHeader.trim().split(/\s+/);
    if (scheme?.toLowerCase() !== 'bearer' || !token) {
      throw new UnauthorizedException('Invalid Authorization header format. Expected Bearer <token>.');
    }

    const payload = this.authService.verifyAccessToken(token);
    if (
      typeof this.authService.isDatabaseConnected === 'function' &&
      this.authService.isDatabaseConnected() &&
      typeof this.authService.verifyActiveAccessUser === 'function'
    ) {
      return this.authService
        .verifyActiveAccessUser(payload)
        .then((activePayload) => {
          request.user = activePayload;
          return true;
        });
    }
    request.user = payload;
    return true;
  }
}


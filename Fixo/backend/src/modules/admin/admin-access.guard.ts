import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { FixoJwtPayload } from '../auth/utils/jwt-token.util';
import { AdminAccessService, AdminActor } from './admin-access.service';

export interface AdminRequest {
  user?: FixoJwtPayload;
  adminActor?: AdminActor;
}
@Injectable()
export class AdminAccessGuard implements CanActivate {
  constructor(private readonly access: AdminAccessService) {}
  async canActivate(context: ExecutionContext) {
    const request = context.switchToHttp().getRequest<AdminRequest>();
    if (!request.user) throw new UnauthorizedException('Sign in first.');
    request.adminActor = await this.access.resolve(request.user);
    return true;
  }
}

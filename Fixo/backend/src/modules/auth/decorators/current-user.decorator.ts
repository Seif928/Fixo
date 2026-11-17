import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { FixoJwtPayload } from '../utils/jwt-token.util';

export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): FixoJwtPayload => {
    const request = ctx.switchToHttp().getRequest<{ user: FixoJwtPayload }>();
    return request.user;
  },
);


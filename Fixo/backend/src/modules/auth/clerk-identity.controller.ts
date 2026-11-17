import {
  Body,
  CanActivate,
  Controller,
  ExecutionContext,
  HttpCode,
  HttpException,
  Injectable,
  Post,
  UseGuards,
} from "@nestjs/common";
import { IsString, MaxLength, MinLength } from "class-validator";
import { CurrentUser } from "./decorators/current-user.decorator";
import { JwtAuthGuard } from "./guards/jwt-auth.guard";
import { FixoJwtPayload } from "./utils/jwt-token.util";
import { ClerkIdentityService } from "./clerk-identity.service";
import { ClerkSessionPolicy } from "./clerk-session-policy.service";

export class ClerkExchangeDto {
  @IsString() @MinLength(20) @MaxLength(10000) clerkToken!: string;
}
export class ClerkLinkDto extends ClerkExchangeDto {
  @IsString() @MinLength(20) @MaxLength(10000) firebaseIdToken!: string;
}

/** A bounded per-process trial abuse limit; not a distributed production quota. */
@Injectable()
export class ClerkTrialRateGuard implements CanActivate {
  private readonly attempts = new Map<
    string,
    { since: number; count: number }
  >();
  constructor(private readonly clerk: ClerkSessionPolicy) {}
  canActivate(context: ExecutionContext): boolean {
    this.clerk.assertConfigured();
    const request = context
      .switchToHttp()
      .getRequest<{ ip?: string; socket?: { remoteAddress?: string } }>();
    const key = request.ip ?? request.socket?.remoteAddress ?? "unknown";
    const now = Date.now();
    for (const [ip, attempt] of this.attempts)
      if (now - attempt.since >= 60000) this.attempts.delete(ip);
    let attempt = this.attempts.get(key);
    if (!attempt) {
      if (this.attempts.size >= 1000)
        throw new HttpException("Clerk trial is busy. Try again later.", 429);
      attempt = { since: now, count: 0 };
      this.attempts.set(key, attempt);
    }
    if (++attempt.count > 10)
      throw new HttpException(
        "Too many Clerk trial attempts. Try again later.",
        429,
      );
    return true;
  }
}

@Controller("auth/clerk/trial")
@UseGuards(ClerkTrialRateGuard)
export class ClerkIdentityController {
  constructor(private readonly service: ClerkIdentityService) {}
  @Post("link")
  @HttpCode(200)
  @UseGuards(JwtAuthGuard)
  link(@CurrentUser() user: FixoJwtPayload, @Body() dto: ClerkLinkDto) {
    return this.service.link(user.sub, dto.firebaseIdToken, dto.clerkToken);
  }
  @Post("exchange")
  @HttpCode(200)
  exchange(@Body() dto: ClerkExchangeDto) {
    return this.service.exchange(dto.clerkToken);
  }
}

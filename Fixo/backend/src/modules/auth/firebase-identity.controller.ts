import { Body, Controller, HttpCode, Post, UseGuards } from "@nestjs/common";
import { ApiProperty, ApiTags } from "@nestjs/swagger";
import { IsString, MaxLength, MinLength } from "class-validator";
import { RateLimit, RateLimitGuard } from "../../common/guards/rate-limit.guard";
import { FirebaseIdentityService } from "./firebase-identity.service";

class FirebaseSessionDto {
  @ApiProperty({
    description:
      "Signed Firebase ID token for a verified email; never an app-supplied user ID or role.",
  })
  @IsString()
  @MinLength(20)
  @MaxLength(10000)
  idToken!: string;
}

class AppleIdentitySessionDto extends FirebaseSessionDto {}

@ApiTags("auth")
@UseGuards(RateLimitGuard)
@Controller("auth/firebase")
export class FirebaseIdentityController {
  constructor(private readonly service: FirebaseIdentityService) {}
  @Post("session")
  @RateLimit({ max: 20, windowMs: 60_000, keyBy: "ip" })
  @HttpCode(200)
  exchange(@Body() dto: FirebaseSessionDto) {
    return this.service.exchange(dto.idToken);
  }

  @Post("apple")
  @RateLimit({ max: 20, windowMs: 60_000, keyBy: "ip" })
  @HttpCode(200)
  exchangeApple(@Body() dto: AppleIdentitySessionDto) {
    return this.service.exchangeApple(dto);
  }
}

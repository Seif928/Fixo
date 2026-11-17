import { Body, Controller, Get, Param, Post, Patch, UseGuards } from "@nestjs/common";
import { IsString, MaxLength, Matches } from "class-validator";
import { JwtAuthGuard } from "../auth/guards/jwt-auth.guard";
import { CurrentUser } from "../auth/decorators/current-user.decorator";
import { FixoJwtPayload } from "../auth/utils/jwt-token.util";
import { AdminAccessService } from "../admin/admin-access.service";
import { SupportService } from "./support.service";
class MessageDto {
  @IsString() @MaxLength(2000) @Matches(/\S/) body!: string;
}
class ThreadDto extends MessageDto {
  @IsString() @MaxLength(120) @Matches(/\S/) subject!: string;
}
@Controller("support")
@UseGuards(JwtAuthGuard)
export class SupportController {
  constructor(
    private readonly service: SupportService,
    private readonly access: AdminAccessService,
  ) {}
  @Get("threads") list(@CurrentUser() u: FixoJwtPayload) {
    return this.service.list(u.sub);
  }
  @Post("threads") create(
    @CurrentUser() u: FixoJwtPayload,
    @Body() d: ThreadDto,
  ) {
    return this.service.create(u.sub, d.subject, d.body);
  }
  @Get("threads/:id/messages") messages(
    @CurrentUser() u: FixoJwtPayload,
    @Param("id") id: string,
  ) {
    return this.service.messages(id, u.sub);
  }
  @Post("threads/:id/messages") send(
    @CurrentUser() u: FixoJwtPayload,
    @Param("id") id: string,
    @Body() d: MessageDto,
  ) {
    return this.service.send(id, u.sub, d.body);
  }
  @Get("admin/threads") async all(@CurrentUser() u: FixoJwtPayload) {
    await this.access.resolve(u);
    return this.service.list(u.sub, true);
  }
  @Get("admin/threads/:id/messages") async adminMessages(
    @CurrentUser() u: FixoJwtPayload,
    @Param("id") id: string,
  ) {
    await this.access.resolve(u);
    return this.service.messages(id, u.sub, true);
  }
  @Post("admin/threads/:id/messages") async reply(
    @CurrentUser() u: FixoJwtPayload,
    @Param("id") id: string,
    @Body() d: MessageDto,
  ) {
    await this.access.resolve(u);
    return this.service.send(id, u.sub, d.body, true);
  }
  @Patch('admin/threads/:id/close')
  async close(@CurrentUser() u:FixoJwtPayload,@Param('id') id:string) {await this.access.resolve(u);return this.service.close(id);}

}

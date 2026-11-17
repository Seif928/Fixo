import { Module } from "@nestjs/common";
import { AuthModule } from "../auth/auth.module";
import { AdminAccessModule } from "../admin/admin-access.module";
import { SupportController } from "./support.controller";
import { SupportService } from "./support.service";
@Module({
  imports: [AuthModule, AdminAccessModule],
  controllers: [SupportController],
  providers: [SupportService],
})
export class SupportModule {}

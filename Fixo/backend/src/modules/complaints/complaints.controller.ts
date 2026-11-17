import {
  Body,
  Controller,
  Get,
  Header,
  Param,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { FixoJwtPayload } from '../auth/utils/jwt-token.util';
import { AdminAccessGuard, AdminRequest } from '../admin/admin-access.guard';
import { ComplaintsService } from './complaints.service';
import {
  ComplaintsQueryDto,
  CreateComplaintDto,
  UpdateComplaintStatusDto,
} from './complaints.dto';

@Controller('complaints')
export class ComplaintsController {
  constructor(private readonly complaints: ComplaintsService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  @Header('Cache-Control', 'private, no-store')
  createComplaint(
    @CurrentUser() user: FixoJwtPayload,
    @Body() dto: CreateComplaintDto,
  ) {
    return this.complaints.createComplaint(user.sub, dto);
  }

  @Get('my')
  @UseGuards(JwtAuthGuard)
  @Header('Cache-Control', 'private, no-store')
  listMyComplaints(
    @CurrentUser() user: FixoJwtPayload,
    @Query() query: ComplaintsQueryDto,
  ) {
    return this.complaints.listMyComplaints(user.sub, query);
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard)
  @Header('Cache-Control', 'private, no-store')
  getComplaintDetails(
    @CurrentUser() user: FixoJwtPayload,
    @Param('id') id: string,
  ) {
    return this.complaints.getComplaintDetails(user.sub, id, false);
  }
}

@Controller('admin/complaints')
@UseGuards(JwtAuthGuard, AdminAccessGuard)
export class AdminComplaintsController {
  constructor(private readonly complaints: ComplaintsService) {}

  @Get()
  @Header('Cache-Control', 'private, no-store')
  listComplaints(@Query() query: ComplaintsQueryDto) {
    return this.complaints.adminListComplaints(query);
  }

  @Get(':id')
  @Header('Cache-Control', 'private, no-store')
  getComplaintDetails(@Req() req: AdminRequest, @Param('id') id: string) {
    const adminId = req.adminActor?.userId ?? req.user!.sub;
    return this.complaints.getComplaintDetails(adminId, id, true);
  }

  @Patch(':id/status')
  @Header('Cache-Control', 'private, no-store')
  updateComplaintStatus(
    @Req() req: AdminRequest,
    @Param('id') id: string,
    @Body() dto: UpdateComplaintStatusDto,
  ) {
    const adminId = req.adminActor?.userId ?? req.user!.sub;
    return this.complaints.adminUpdateStatus(adminId, id, dto);
  }
}

import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Put,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { FixoJwtPayload } from '../auth/utils/jwt-token.util';
import {
  CreateLeaveDto,
  UpdateWeeklyScheduleDto,
} from './dto/pro-schedule.dto';
import { ProScheduleService } from './pro-schedule.service';

@ApiTags('Professional Scheduling & Leaves')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('pro')
export class ProScheduleController {
  constructor(private readonly scheduleService: ProScheduleService) {}

  @Get('schedule')
  @ApiOperation({
    summary: 'Get professional weekly working schedule and leaves',
  })
  async getSchedule(@CurrentUser() user: FixoJwtPayload) {
    return this.scheduleService.getSchedule(user.sub);
  }

  @Put('schedule')
  @ApiOperation({
    summary: 'Update professional weekly working schedule',
  })
  async updateSchedule(
    @CurrentUser() user: FixoJwtPayload,
    @Body() dto: UpdateWeeklyScheduleDto,
  ) {
    return this.scheduleService.updateSchedule(user.sub, dto);
  }

  @Post('leaves')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary: 'Request leave period (validates against active bookings)',
  })
  @ApiResponse({ status: 201, description: 'Leave successfully created' })
  @ApiResponse({
    status: 409,
    description: 'Conflict with active booking scheduled during this period',
  })
  async createLeave(
    @CurrentUser() user: FixoJwtPayload,
    @Body() dto: CreateLeaveDto,
  ) {
    return this.scheduleService.createLeave(user.sub, dto);
  }

  @Delete('leaves/:id')
  @ApiOperation({
    summary: 'Cancel an existing leave request',
  })
  @ApiParam({ name: 'id', description: 'Leave ID' })
  async cancelLeave(
    @CurrentUser() user: FixoJwtPayload,
    @Param('id') leaveId: string,
  ) {
    return this.scheduleService.cancelLeave(user.sub, leaveId);
  }
}


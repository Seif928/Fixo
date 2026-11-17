import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Header,
  StreamableFile,
  Param,
  Patch,
  Post,
  Put,
  UseGuards,
  Req,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiTags,
} from '@nestjs/swagger';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { FixoJwtPayload } from '../auth/utils/jwt-token.util';
import {
  ProAdvanceJobStatusDto,
  ProAdminReviewDto,
  ProAvailabilityDto,
  ProDeclineOfferDto,
  ProDocumentUploadDto,
  ProPersonalDetailsDto,
  ProSkillsUpdateDto,
} from './dto/pro.dto';
import { ProService } from './pro.service';
import { AdminAccessGuard, AdminRequest } from '../admin/admin-access.guard';

@ApiTags('Professional Workflows (Screens 11–16)')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('pro')
export class ProController {
  constructor(private readonly proService: ProService) {}

  @Get('catalog-options')
  @ApiOperation({
    summary:
      'Get active categories, sub-skills, coverage zones, transport modes, and experience tiers (Screens 11–12)',
  })
  async getCatalogOptions() {
    return this.proService.getCatalogOptions();
  }

  @Get('me')
  @ApiOperation({
    summary: 'Get authenticated professional profile and onboarding progress',
  })
  async getMyProfile(@CurrentUser() user: FixoJwtPayload) {
    const profile = await this.proService.getMyProProfile(user.sub);
    return { profile };
  }

  @Post('onboarding/personal')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Step 1 of 4: Save legal name and 14-digit National ID for private manual review (Screen 11)',
  })
  async savePersonalDetails(
    @CurrentUser() user: FixoJwtPayload,
    @Body() dto: ProPersonalDetailsDto,
  ) {
    return this.proService.upsertPersonalDetails(user.sub, dto);
  }

  @Put('onboarding/skills')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Step 2 of 4: Save primary trade category, sub-skills, experience tier, coverage zones, and toolkit commitment (Screen 12)',
  })
  async saveSkillsAndCoverage(
    @CurrentUser() user: FixoJwtPayload,
    @Body() dto: ProSkillsUpdateDto,
  ) {
    return this.proService.updateSkillsAndCoverage(user.sub, dto);
  }

  @Post('onboarding/documents')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({
    summary:
      'Step 3 of 4: Upload private verification document photo (Screen 13)',
  })
  async uploadDocument(
    @CurrentUser() user: FixoJwtPayload,
    @Body() dto: ProDocumentUploadDto,
  ) {
    return this.proService.uploadVerificationDocument(user.sub, dto);
  }

  @Get('onboarding/documents/:docId/access')
  @Header('Cache-Control', 'private, no-store')
  @ApiParam({ name: 'docId', description: 'Verification Document UUID' })
  @ApiOperation({
    summary:
      'Get authenticated access to an owned private verification document',
  })
  async getDocumentAccess(
    @CurrentUser() user: FixoJwtPayload,
    @Param('docId') docId: string,
  ) {
    return this.proService.getVerificationDocumentAccess(user.sub, docId);
  }

  @Get('onboarding/documents/:docId/content')
  @Header('Cache-Control', 'private, no-store')
  @Header('X-Content-Type-Options', 'nosniff')
  async getDocumentContent(
    @CurrentUser() user: FixoJwtPayload,
    @Param('docId') docId: string,
  ) {
    const content = await this.proService.getVerificationDocumentContent(
      user.sub,
      docId,
    );
    return new StreamableFile(content.bytes, {
      type: content.mimeType,
      disposition: 'attachment; filename="verification-document"',
    });
  }

  @Post('onboarding/submit')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary:
      'Submit completed onboarding dossier for manual verification review (Screen 13 -> Screen 14)',
  })
  async submitForVerification(@CurrentUser() user: FixoJwtPayload) {
    return this.proService.submitForVerification(user.sub);
  }

  @Get('onboarding/status')
  @ApiOperation({
    summary:
      'Step 4 of 4: Get real verification status, vetting milestones, and reviewer notes (Screen 14)',
  })
  async getVerificationStatus(@CurrentUser() user: FixoJwtPayload) {
    return this.proService.getVerificationStatus(user.sub);
  }

  @Patch('admin/profiles/:proProfileId/review')
  @UseGuards(AdminAccessGuard)
  @ApiParam({ name: 'proProfileId', description: 'ProProfile UUID' })
  @ApiOperation({
    summary:
      'Private Owner/Admin reviewer endpoint with dossier version and transactional audit',
  })
  async adminReviewProfile(
    @Req() request: AdminRequest,
    @Param('proProfileId') proProfileId: string,
    @Body() dto: ProAdminReviewDto,
  ) {
    return this.proService.adminReviewProProfile(
      request.adminActor!,
      proProfileId,
      dto,
    );
  }

  @Patch('availability')
  @ApiOperation({
    summary:
      'Toggle online/offline availability for an APPROVED professional (Screen 15)',
  })
  async updateAvailability(
    @CurrentUser() user: FixoJwtPayload,
    @Body() dto: ProAvailabilityDto,
  ) {
    return this.proService.updateAvailability(user.sub, dto);
  }

  @Get('dashboard')
  @ApiOperation({
    summary:
      'Get Pro Dashboard: real net earnings, 7-day weekly trajectory, active offers, and today schedule (Screen 15)',
  })
  async getDashboard(@CurrentUser() user: FixoJwtPayload) {
    return this.proService.getDashboard(user.sub);
  }

  @Get('job-offers/:offerId')
  @ApiParam({ name: 'offerId', description: 'JobOffer UUID' })
  @ApiOperation({
    summary:
      'Get incoming job offer details, countdown timer, and net EGP breakdown (Screen 16)',
  })
  async getJobOfferById(
    @CurrentUser() user: FixoJwtPayload,
    @Param('offerId') offerId: string,
  ) {
    return this.proService.getJobOfferById(user.sub, offerId);
  }

  @Post('job-offers/:offerId/accept')
  @HttpCode(HttpStatus.OK)
  @ApiParam({ name: 'offerId', description: 'JobOffer UUID' })
  @ApiOperation({
    summary:
      'Atomically accept an incoming job offer with row-level lock (Screen 16)',
  })
  async acceptJobOffer(
    @CurrentUser() user: FixoJwtPayload,
    @Param('offerId') offerId: string,
  ) {
    return this.proService.acceptJobOffer(user.sub, offerId);
  }

  @Post('job-offers/:offerId/decline')
  @HttpCode(HttpStatus.OK)
  @ApiParam({ name: 'offerId', description: 'JobOffer UUID' })
  @ApiOperation({
    summary: 'Decline an incoming job offer with reason (Screen 16)',
  })
  async declineJobOffer(
    @CurrentUser() user: FixoJwtPayload,
    @Param('offerId') offerId: string,
    @Body() dto: ProDeclineOfferDto,
  ) {
    return this.proService.declineJobOffer(user.sub, offerId, dto);
  }

  @Post('bookings/:bookingId/status')
  @HttpCode(HttpStatus.OK)
  @ApiParam({ name: 'bookingId', description: 'Booking UUID' })
  @ApiOperation({
    summary:
      'Advance assigned job status (CONFIRMED -> PRO_EN_ROUTE -> ARRIVED -> IN_PROGRESS w/ PIN -> COMPLETED)',
  })
  async advanceBookingStatus(
    @CurrentUser() user: FixoJwtPayload,
    @Param('bookingId') bookingId: string,
    @Body() dto: ProAdvanceJobStatusDto,
  ) {
    return this.proService.advanceBookingStatus(user.sub, bookingId, dto);
  }
}

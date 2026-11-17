import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength } from 'class-validator';

export class CancelBookingDto {
  @ApiPropertyOptional({
    description: 'Optional customer cancellation reason',
    example: 'Need to reschedule for next week',
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  reason?: string;
}

import { Transform, Type } from 'class-transformer';
import { IsBoolean, IsInt, IsOptional, IsString, Matches, Max, MaxLength, Min } from 'class-validator';

export class NotificationPreferenceDto {
  @IsBoolean()
  arrivalAlertsEnabled!: boolean;
}

export class SendMessageDto {
  @Transform(({ value }: { value: unknown }) => typeof value === 'string' ? value.trim() : value)
  @IsString()
  @Matches(/\S/, { message: 'Message cannot be blank.' })
  @MaxLength(2000)
  body!: string;
}

export class MessageQueryDto {
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(50)
  limit?: number;

  @IsOptional()
  @IsString()
  @MaxLength(100)
  before?: string;
}

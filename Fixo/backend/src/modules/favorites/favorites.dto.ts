import { IsInt, IsOptional } from 'class-validator';
import { Transform } from 'class-transformer';

export class FavoritesQueryDto {
  @IsOptional()
  @Transform(({ value }) => {
    const num = parseInt(value, 10);
    return isNaN(num) || num < 1 ? 1 : num;
  })
  @IsInt()
  page: number = 1;

  @IsOptional()
  @Transform(({ value }) => {
    const num = parseInt(value, 10);
    if (isNaN(num) || num < 1) return 20;
    if (num > 50) return 50;
    return num;
  })
  @IsInt()
  limit: number = 20;
}

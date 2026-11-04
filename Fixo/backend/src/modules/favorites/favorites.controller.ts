import {
  Controller,
  Delete,
  Get,
  Header,
  Param,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { FixoJwtPayload } from '../auth/utils/jwt-token.util';
import { FavoritesService } from './favorites.service';
import { FavoritesQueryDto } from './favorites.dto';

@Controller('favorites')
@UseGuards(JwtAuthGuard)
export class FavoritesController {
  constructor(private readonly favorites: FavoritesService) {}

  @Get('ids')
  @Header('Cache-Control', 'private, no-store')
  getFavoriteIds(@CurrentUser() user: FixoJwtPayload) {
    return this.favorites.getFavoriteIds(user.sub);
  }

  @Get('services')
  @Header('Cache-Control', 'private, no-store')
  listServices(
    @CurrentUser() user: FixoJwtPayload,
    @Query() query: FavoritesQueryDto,
  ) {
    return this.favorites.listFavoriteServices(user.sub, query);
  }

  @Post('services/:offeringId')
  @Header('Cache-Control', 'private, no-store')
  addService(
    @CurrentUser() user: FixoJwtPayload,
    @Param('offeringId') offeringId: string,
  ) {
    return this.favorites.addFavoriteService(user.sub, offeringId);
  }

  @Delete('services/:offeringId')
  @Header('Cache-Control', 'private, no-store')
  removeService(
    @CurrentUser() user: FixoJwtPayload,
    @Param('offeringId') offeringId: string,
  ) {
    return this.favorites.removeFavoriteService(user.sub, offeringId);
  }

  @Get('professionals')
  @Header('Cache-Control', 'private, no-store')
  listProfessionals(
    @CurrentUser() user: FixoJwtPayload,
    @Query() query: FavoritesQueryDto,
  ) {
    return this.favorites.listFavoriteProfessionals(user.sub, query);
  }

  @Post('professionals/:proProfileId')
  @Header('Cache-Control', 'private, no-store')
  addProfessional(
    @CurrentUser() user: FixoJwtPayload,
    @Param('proProfileId') proProfileId: string,
  ) {
    return this.favorites.addFavoriteProfessional(user.sub, proProfileId);
  }

  @Delete('professionals/:proProfileId')
  @Header('Cache-Control', 'private, no-store')
  removeProfessional(
    @CurrentUser() user: FixoJwtPayload,
    @Param('proProfileId') proProfileId: string,
  ) {
    return this.favorites.removeFavoriteProfessional(user.sub, proProfileId);
  }
}

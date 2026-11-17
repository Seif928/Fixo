import { Module } from '@nestjs/common';
import { ProfessionalsController } from './professionals.controller';
import { ServicesController } from './services.controller';
import { ServicesService } from './services.service';

@Module({
  controllers: [ServicesController, ProfessionalsController],
  providers: [ServicesService],
  exports: [ServicesService],
})
export class ServicesModule {}


import { Module } from '@nestjs/common';
import { IngreModule } from './ingrediente/ingre.module';

@Module({
  imports: [IngreModule],
  controllers: [],
  providers: [],
})
export class AppModule {}

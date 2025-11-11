import {Module} from '@nestjs/common';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { JwtModule } from '@nestjs/jwt';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { DatabaseModule } from '../database/database.module';
import { PassportModule } from '@nestjs/passport';
import { JwtStrategy } from './strategies/jwt.strategy';

@Module({
   imports: [
      PassportModule,
      DatabaseModule,
      JwtModule.registerAsync({
         imports: [ConfigModule],
         inject: [ConfigService],
         useFactory: (config: ConfigService) => ({
            secret: config.get<string>('SESSION_SECRET'),
            signOptions: { expiresIn: '10min' },
         }),
      }),
   ],
   controllers: [AuthController],
   providers: [AuthService, JwtStrategy],
})
export class AuthModule {}
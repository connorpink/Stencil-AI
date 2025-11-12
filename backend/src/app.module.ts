import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';

import { AuthModule } from './auth/auth.module';
import { DatabaseModule } from './database/database.module';
import { OenoModule } from './oeno/oeno.module';

@Module({
  imports: [
    // configure the env file
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),

    // rate limit access to the server
    ThrottlerModule.forRoot({
      throttlers: [
        {
          ttl: 60000,
          limit: 10,
        }
      ]
    }),

    // other src modules
    AuthModule,
    DatabaseModule,
    OenoModule
  ],
  controllers: [],
  providers: [
    // apply the rate limiting globally
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    }
  ],
})
export class AppModule {}

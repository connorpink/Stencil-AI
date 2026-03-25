import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';

import { AuthModule } from './auth/auth.module';
import { DatabaseModule } from './database/database.module';
import { OenoModule } from './oeno/oeno.module';
import { ArtworkModule } from './artwork/artwork.module';
import { VolumeModule } from './volume/volume.module';
import { MongooseModule } from '@nestjs/mongoose';

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

    MongooseModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: async (configService: ConfigService) => ({
        uri: configService.get<string>('MONGODB_CONNECTION_STRING'),
        connectionFactory: ((connection) => {
          if (connection.readyState === 1) { console.log('MongoDB connected successfully'); }

          // add event listeners if connection is still in the process of being made
          connection.on('open', () => { console.log('MongoDB connected successfully'); });
          connection.on('error', (error) => { console.error('MongoDB connection error:', error); });
          connection.on('disconnected', () => { console.warn('MongoDB disconnected'); });

          return connection
        }),
      }),
      inject: [ConfigService],
    }),

    // other src modules
    AuthModule,
    ArtworkModule,
    DatabaseModule,
    OenoModule,
    VolumeModule,
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

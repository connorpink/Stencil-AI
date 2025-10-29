import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import cookieParser from 'cookie-parser';

import { AppModule } from './app.module';
import { SetCookieFlags } from './middleware/cookieFlags.middleware';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // make sure all parameters passed from client match the expected dto
  // throw an error if any unexpected values are passed to the server (change before production)
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
  }));

  // manages the default settings for cookies sent out
  app.use(new SetCookieFlags().use.bind(new SetCookieFlags()));

  app.use(cookieParser());

  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();

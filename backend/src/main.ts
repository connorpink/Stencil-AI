import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import cookieParser from 'cookie-parser';

import { AppModule } from './app.module';
import { SetCookieFlags } from './middleware/cookieFlags.middleware';
import { Request, Response, NextFunction } from 'express';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // general logger for incoming requests
  app.use((req: Request, _res: Response, next: NextFunction) => {
    console.log("\n\n\n")
    console.log("REQUEST RECEIVED!");
    console.log("->", req.method, req.path);
    next();
  });

  app.enableCors();

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

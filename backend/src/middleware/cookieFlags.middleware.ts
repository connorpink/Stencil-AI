import { Injectable, NestMiddleware } from '@nestjs/common';
import type { Request, Response, NextFunction } from 'express';

@Injectable()
export class SetCookieFlags implements NestMiddleware {
   use(_req: Request, res: Response, next: NextFunction) {
      const originalSetCookie = res.cookie;

      res.cookie = function (name: string, value: any, options: any = {}) {
         options = {
         httpOnly: true,
         secure: process.env.LOCAL_ENVIRONMENT === 'true' ? false : true,
         sameSite: 'lax',
         maxAge: 15 * 60 * 1000, // 15min
         ...options,
         };

         return originalSetCookie.call(this, name, value, options);
      };

      next();
   }
}
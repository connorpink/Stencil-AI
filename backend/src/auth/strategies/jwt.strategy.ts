import { HttpException, Injectable } from "@nestjs/common";
import { PassportStrategy } from "@nestjs/passport";
import { ExtractJwt, Strategy } from "passport-jwt";

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
   constructor() {
      const secret = process.env.SESSION_SECRET;
      if (!secret) { throw new Error ("SESSION_SECRET is missing! make sure its added to the .env file") }
      super({
         jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
         ignoreExpiration: false,
         secretOrKey: secret,
      });
   }

   validate(payload: any) {
      if (payload.type !== 'access') { throw new HttpException("Internal server error", 500) }
      return {
         id: payload.id,
         username: payload.username
      }
   }
}
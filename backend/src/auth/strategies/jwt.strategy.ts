import { Injectable, UnauthorizedException } from "@nestjs/common";
import { PassportStrategy } from "@nestjs/passport";
import { ExtractJwt, Strategy } from "passport-jwt";

type AccessTokenPayload = {
   id: number;
   username: string;
   type: 'access';
}

export type AuthenticatedUser = {
   id: number;
   username: string;
};

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
   constructor() {
      const secret = process.env.SESSION_SECRET;
      if (!secret) { throw new Error ("SESSION_SECRET is missing! make sure its added to the .env file"); }
      super({
         jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
         ignoreExpiration: false,
         secretOrKey: secret,
      });
   }

   validate(payload: AccessTokenPayload): AuthenticatedUser {
      if (payload.type !== 'access') { throw new UnauthorizedException('Invalid access token provided'); }
      return {
         id: payload.id,
         username: payload.username
      }
   }
}
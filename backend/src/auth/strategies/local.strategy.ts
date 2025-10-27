import { PassportStrategy } from "@nestjs/passport";
import { Strategy } from "passport-local";
import { AuthService } from "../auth.service";
import { Injectable, UnauthorizedException } from "@nestjs/common";

@Injectable()
export class LocalStrategy extends PassportStrategy(Strategy) {
   private readonly authService: AuthService

   constructor (authService: AuthService) {
      super();
      this.authService = authService;
   }

   validate(username: string, password: string) {
      const user = this.authService.validateUser({ username, password });
      if (!user) throw new UnauthorizedException();
      return user;
   }
}
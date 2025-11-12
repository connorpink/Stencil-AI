import { Module } from "@nestjs/common";

import { JwtStrategy } from "src/auth/strategies/jwt.strategy";
import { OenoController } from "./oeno.controller";
import { OenoService } from './oeno.service'

@Module({
   imports: [],
   controllers: [OenoController],
   providers: [OenoService, JwtStrategy],
})
export class OenoModule {}
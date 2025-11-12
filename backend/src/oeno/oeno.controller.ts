import { Controller, Get, Query, UseGuards } from "@nestjs/common";

import { OenoService } from "./oeno.service";
import { JwtAuthGuard } from "src/auth/guards/jwt.guard";
import { oenoPromptDto } from "./dto/oenoPrompt.dto";

@Controller('oeno')
export class OenoController {
   private readonly oenoService: OenoService;

   constructor(oenoService: OenoService) {
      this.oenoService = oenoService;
   }

   @Get('sketchList')
   //@UseGuards(JwtAuthGuard)
   async sketchList(@Query() payload: oenoPromptDto) {
      const brokenPromptList = await this.oenoService.breakPrompt(payload);
      return brokenPromptList
   }
}
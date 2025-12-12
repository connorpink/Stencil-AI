import { Module } from "@nestjs/common";
import { OenoService } from './oeno.service'

@Module({
   providers: [OenoService],
   exports: [OenoService]
})
export class OenoModule {}
import { Module } from "@nestjs/common";
import { VolumeService } from './volume.service'
import { VolumeController } from "./volume.controller";

@Module({
   providers: [VolumeService],
   controllers: [VolumeController],
   exports: [VolumeService]
})
export class VolumeModule {}
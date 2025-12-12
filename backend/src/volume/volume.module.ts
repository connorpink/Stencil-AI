import { Module } from "@nestjs/common";
import { VolumeService } from './volume.service'

@Module({
   providers: [VolumeService],
   exports: [VolumeService]
})
export class VolumeModule {}
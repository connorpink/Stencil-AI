import { Module } from "@nestjs/common";
import { ArtworkService } from "./artwork.service";
import { ArtworkController } from "./artwork.controller";
import { OenoModule } from "src/oeno/oeno.module";
import { VolumeModule } from "src/volume/volume.module";
import { MongooseModule } from "@nestjs/mongoose";
import { Artwork, ArtworkSchema } from "src/database/mongoose_schema/artwork.schema";

@Module({
   imports: [
      OenoModule, 
      VolumeModule,
      
      MongooseModule.forFeature([
         { name: Artwork.name, schema: ArtworkSchema }
      ]),
   ],
   controllers: [ArtworkController],
   providers: [ArtworkService],
})
export class ArtworkModule {}
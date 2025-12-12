import { Body, Controller, Post } from "@nestjs/common";
import { ArtworkService } from "./artwork.service";
import { CreateArtworkDto } from "./dto/createArtwork.dto";

@Controller('artwork')
export class ArtworkController {
   private readonly artworkService: ArtworkService;

   constructor(artworkService: ArtworkService) {
      this.artworkService = artworkService;
   }

   @Post('create')
   async create(@Body() payload: CreateArtworkDto) {
      const newArtwork = await this.artworkService.createArtwork(payload);
      return newArtwork;
   }
};
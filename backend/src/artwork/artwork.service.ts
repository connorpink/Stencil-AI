import { HttpException, Injectable } from '@nestjs/common';
import { OenoService } from 'src/oeno/oeno.service';
import { ArtworkDto, StencilDto } from 'src/server.types';
import { VolumeService } from 'src/volume/volume.service';
import { Artwork } from 'src/database/mongoose_schema/artwork.schema';
import { Model } from 'mongoose';
import { InjectModel } from '@nestjs/mongoose';
import { RouteCreateArtworkDto } from './dto/createArtwork.dto';

@Injectable()
export class ArtworkService {
   private readonly oenoService: OenoService;
   private readonly volumeService: VolumeService;
   private readonly artworkModel: Model<Artwork>;

   constructor (
      oenoService: OenoService, 
      volumeService: VolumeService, 
      @InjectModel(Artwork.name) artworkModel: Model<Artwork>
   ) {
      this.oenoService = oenoService;
      this.volumeService = volumeService;
      this.artworkModel = artworkModel;
   }

   async createArtwork ({title, prompt}: RouteCreateArtworkDto): Promise<ArtworkDto> {
      const stencilCount = 3;
      let stencilList: StencilDto[] = []

      // set the stencilList field for the artwork
      try {
         const subPromptList: string[] = await this.oenoService.breakPrompt(prompt, stencilCount);

         /*
         const promisedStencilList: Promise<StencilDto>[] = subPromptList.map(
            (subPrompt) => { return this.oenoService.generateStencil(subPrompt); }
         );

         stencilList = await Promise.all(promisedStencilList);
         */

         // ! start of test code
         stencilList = [
            {
               prompt: "Knight - swinging a sword", 
               imageList: [
                  {
                     path: "stencil/oenoImage-1767125791021.webp", 
                     url: "public/stencil/oenoImage-1767125791021.webp", 
                     size: undefined, 
                     orig_name: undefined,
                     mime_type: undefined,
                     is_stream: false, 
                     meta: {}
                  }, 
                  {
                     path: "stencil/oenoImage-1767125791031.webp", 
                     url: "public/stencil/oenoImage-1767125791031.webp", 
                     size: undefined, 
                     orig_name: undefined, 
                     mime_type: undefined, 
                     is_stream: false, 
                     meta: {}
                  }
               ]
            }, 
            {
               prompt: "Dragon - spreading wings", 
               imageList: [
                  {
                     path: "stencil/oenoImage-1767126425090.webp", 
                     url: "public/stencil/oenoImage-1767126425090.webp", 
                     size: undefined, 
                     orig_name: undefined, 
                     mime_type: undefined, 
                     is_stream: false, 
                     meta: {}
                  }, 
                  {
                     path: "stencil/oenoImage-1767126425221.webp", 
                     url: "public/stencil/oenoImage-1767126425221.webp", 
                     size: undefined, 
                     orig_name: undefined, 
                     mime_type: undefined, 
                     is_stream: false, 
                     meta: {}
                  }
               ]
            }, 
            {
               prompt: "Knight - holding a shield", 
               imageList: [
                  {
                     path: "stencil/oenoImage-1767125142078.webp", 
                     url: "public/stencil/oenoImage-1767125142078.webp", 
                     size: undefined, 
                     orig_name: undefined, 
                     mime_type: undefined, 
                     is_stream: false, 
                     meta: {}
                  }, 
                  {
                     path: "stencil/oenoImage-1767125142145.webp", 
                     url: "public/stencil/oenoImage-1767125142145.webp", 
                     size: undefined, 
                     orig_name: undefined, 
                     mime_type: undefined, 
                     is_stream: false, 
                     meta: {}
                  }
               ]
            }
         ];
         // ? end of test code
      }
      catch (error) {
         console.error("\x1b[31m[artworkService] server failed to create stencils for the new artwork object\x1b[0m\n", error);
         throw new HttpException("Internal server error", 500);
      }

      // save the artwork in the database
      try {
         const savedArtwork = await new this.artworkModel({
            title: title,
            prompt: prompt,
            stencilList: stencilList,
            strokeList: [],
            updatedAt: new Date(),
         }).save();

         const artwork: ArtworkDto = savedArtwork.toJSON();

         return artwork;
      }
      catch (error) {
         console.error("\x1b[31m[artworkService] server failed to save new artwork to the database\x1b[0m\n", error);

         // Attempt to delete all images associated with the artwork from the volume
         await Promise.all(stencilList.map(async (stencil) => {
            await Promise.all(stencil.imageList.map(async (image) => {
               try { await this.volumeService.deleteImage(image.path); }
               catch(error) { console.error("server failed to delete image from volume: " + image.path, error); }
            }));
         }));

         throw new HttpException("Internal server error", 500);
      }
   }
}
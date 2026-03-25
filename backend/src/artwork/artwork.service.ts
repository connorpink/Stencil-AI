import { HttpException, Injectable, InternalServerErrorException, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { OenoService } from 'src/oeno/oeno.service';
import { VolumeService } from 'src/volume/volume.service';
import { Artwork } from 'src/database/mongoose_schema/artwork.schema';
import { Model } from 'mongoose';
import { InjectModel } from '@nestjs/mongoose';
import { ArtworkDto } from './dto/artwork.dto';
import { ArtworkEntity } from './entities/artwork.entity';
import { StencilEntity } from './entities/stencil.entity';
import { CreateArtworkBodyDto } from './dto/createArtworkBody.dto';

@Injectable()
export class ArtworkService {
   private readonly oenoService: OenoService;
   private readonly volumeService: VolumeService;
   private readonly databaseArtworkModel: Model<Artwork>;

   constructor (
      oenoService: OenoService, 
      volumeService: VolumeService, 
      @InjectModel(Artwork.name) databaseArtworkModel: Model<Artwork>
   ) {
      this.oenoService = oenoService;
      this.volumeService = volumeService;
      this.databaseArtworkModel = databaseArtworkModel;
   }

   async  createDtoList (artworkEntityList: ArtworkEntity[]): Promise<ArtworkDto[]> {
      return artworkEntityList.map(({ ownerId, ...remainingFields }) => { return remainingFields; });
   };

   async fetchArtworkList ({userId, id, limit}: {userId: number, id?: string, limit?: number}): Promise<ArtworkEntity[]> {

      let query = this.databaseArtworkModel.find({
         ownerId: userId,
         ...(id && {_id: id}),
      })
      if (limit !== undefined) { query = query.limit(limit); }

      try {
         const response: ArtworkEntity[] = await query.lean();
         if (response.length == 0) { throw new NotFoundException('No artworks inside the database meet the required parameters provided'); }
         return response;
      }
      catch(error) {
         console.error("\x1b[31m[artworkService] server failed to fetch artwork list from the database\x1b[0m\n", error);
         throw new InternalServerErrorException('Internal server error');
      }
   }

   async createArtwork ({userId, title, prompt}: CreateArtworkBodyDto & {userId: number}): Promise<ArtworkDto> {
      const stencilCount = 3;
      let stencilList: StencilEntity[] = []

      // set the stencilList field for the artwork
      try {
         /*
         const subPromptList: string[] = await this.oenoService.breakPrompt(prompt, stencilCount);

         const promisedStencilList: Promise<StencilDto>[] = subPromptList.map(
            (subPrompt) => { return this.oenoService.generateStencil(subPrompt); }
         );

         stencilList = await Promise.all(promisedStencilList); 
         */


         // ! start of test code
         stencilList = [
            {
               prompt:"knight - raising a sword",
               preferredImageIndex:1,
               imageList:[
                  {
                     path:"/stencil/oenoImage-1769714579404.webp",
                     url:"http://localhost:3000/public/stencil/oenoImage-1769714579404.webp",
                     size:null,
                     orig_name:null,
                     mime_type:null,
                     is_stream:false,
                     meta:{"_type":"gradio.FileData"}
                  },
                  {
                     path:"/stencil/oenoImage-1769714579374.webp",
                     url:"http://localhost:3000/public/stencil/oenoImage-1769714579374.webp",
                     size:null,
                     orig_name:null,
                     mime_type:null,
                     is_stream:false,
                     meta:{"_type":"gradio.FileData"}
                  }
               ]
            },
            {
               prompt:"dragon - breathing fire",
               preferredImageIndex:1,
               imageList:[
                  {
                     path:"/stencil/oenoImage-1769715937365.webp",
                     url:"http://localhost:3000/public/stencil/oenoImage-1769715937365.webp",
                     size:null,
                     orig_name:null,
                     mime_type:null,
                     is_stream:false,
                     meta:{"_type":"gradio.FileData"}},
                  {
                     path:"/stencil/oenoImage-1769715937386.webp",
                     url:"http://localhost:3000/public/stencil/oenoImage-1769715937386.webp",
                     size:null,
                     orig_name:null,
                     mime_type:null,
                     is_stream:false,
                     meta:{"_type":"gradio.FileData"}
                  }
               ]
            },
            {
               prompt:"princess - watching intently",
               preferredImageIndex:1,
               imageList:[
                  {
                     path:"/stencil/oenoImage-1769716955999.webp",
                     url:"http://localhost:3000/public/stencil/oenoImage-1769716955999.webp",
                     size:null,
                     orig_name:null,
                     mime_type:null,
                     is_stream:false,
                     meta:{"_type":"gradio.FileData"}
                  },
                  {
                     path:"/stencil/oenoImage-1769716955963.webp",
                     url:"http://localhost:3000/public/stencil/oenoImage-1769716955963.webp",
                     size:null,
                     orig_name:null,
                     mime_type:null,
                     is_stream:false,
                     meta:{"_type":"gradio.FileData"}
                  }
               ]
            }
         ]
            // ? end of test code
      }
      catch (error) {
         console.error("\x1b[31m[artworkService] server failed to create stencils for the new artwork object\x1b[0m\n", error);
         throw new HttpException("Internal server error", 500);
      }

      // save the artwork in the database
      try {
         const savedArtwork = await new this.databaseArtworkModel({
            title: title,
            ownerId: userId,
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

   async saveArtwork ({userId, artwork}: {userId: number, artwork: ArtworkDto}): Promise<void> {

      let databaseArtwork: ArtworkEntity | null;
      try {
         databaseArtwork = await this.databaseArtworkModel.findOne({_id: artwork.id});
      }
      catch(error) {
         console.error("\x1b[31m[artworkService] server failed to fetch artwork from the database\x1b[0m\n", error);
         throw new InternalServerErrorException('Internal server error');
      }

      if (databaseArtwork == null) { throw new NotFoundException("The database does not contain an artwork with the provided id"); }
      if (databaseArtwork.ownerId != userId) { throw new UnauthorizedException("Client does not have write access to the requested artwork"); }
      
      try {
         await this.databaseArtworkModel.findOneAndUpdate(
            { id: artwork.id, ownerId: userId },
            { $set: artwork },
         );
      }
      catch(error) {
         console.error("\x1b[31m[artworkService] server failed to save artwork inside the database\x1b[0m\n", error);
         throw new InternalServerErrorException('Internal server error');
      }

   }

   async deleteArtwork ({userId, id}: {userId: number, id: string}): Promise<void> {
      let databaseArtwork: ArtworkEntity | null;
      try {
         databaseArtwork = await this.databaseArtworkModel.findOne({_id: id}).lean();
      }
      catch(error) {
         console.error("\x1b[31m[artworkService] server failed to fetch artwork from the database\x1b[0m\n", error);
         throw new InternalServerErrorException('Internal server error');
      }

      if (databaseArtwork == null) { throw new NotFoundException("The database does not contain an artwork with the provided id"); }
      if (databaseArtwork.ownerId != userId) { throw new UnauthorizedException("Client does not have write access to the requested artwork"); }

      try {
         await this.databaseArtworkModel.deleteOne({ownerId: userId, _id: id});
      }
      catch(error) {
         console.error("\x1b[31m[artworkService] server failed  to delete the artwork from the database\x1b[0m\n", error);
         throw new InternalServerErrorException('Internal server error');
      }
   }
}
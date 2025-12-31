import { Body, Controller, Get, Param, Post } from "@nestjs/common";
import { RouteCreateArtworkDto } from "./dto/createArtwork.dto";
import { ArtworkService } from "./artwork.service";
import { ArtworkDto } from "src/server.types";
import { RouteSaveArtworkDto } from "./dto/saveArtwork.dto";
import { RouteFetchArtworkDto } from "./dto/fetchArtwork.dto";
import { RouteDeleteArtworkDto } from "./dto/deleteArtwork.dto";

@Controller('artwork')
export class ArtworkController {
   private readonly artworkService: ArtworkService;

   constructor(artworkService: ArtworkService) {
      this.artworkService = artworkService;
   }



   /*
   route GET artwork/fetchAll

   get a list of all artworks associated with the current user

   returns: ArtworkDto[]
   */
   @Get('fetchAll')
   async fetchAll() {
      const artworkList: ArtworkDto[] = [{
         id: "test id",
         title: "",
         prompt: "",
         stencilList: [],
         strokeList: [],
         updatedAt: new Date(),
      }];
      return artworkList;
   }



   /*
   route GET artwork/fetch/:artworkId

   expects: {
      artworkId: string;
   }

   gets an artwork object from the database based on the artwork id provided

   returns: ArtworkDto
   */
   @Get('fetch/:artworkId')
   async fetch(@Param() params: RouteFetchArtworkDto) {
      const artwork: ArtworkDto = {
         id: params.artworkId,
         title: "",
         prompt: "",
         stencilList: [],
         strokeList: [],
         updatedAt: new Date(),
      }
      return artwork;
   }



   /*
   route POST artwork/create

   expects: {
      title: string;
      prompt: string;       
   }

   creates a new Artwork object based on the values provided, and creates stencils to go along with the artwork

   returns: ArtworkDto
   */
   @Post('create')
   async create(@Body() payload: RouteCreateArtworkDto) {
      const newArtwork: ArtworkDto = await this.artworkService.createArtwork(payload);
      return newArtwork;
   }



   /*
   route POST artwork/save

   expects: {
      artwork: ArtworkDto
   }

   updates the artwork inside the database to match the current artwork

   return: bool (true = saved, false = save failed)
   */
   @Post('save')
   async save(@Body() payload: RouteSaveArtworkDto) {
      return true
   }



   /*
   route POST artwork/delete

   expects: {
      artworkId: string
   }

   deletes an artwork with the given id from the server

   return bool (true = deleted, false = delete failed)
   */
   @Post('delete')
   async delete(@Body() payload: RouteDeleteArtworkDto) {
      return true
   }
};
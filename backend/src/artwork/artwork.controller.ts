import { Body, Controller, Get, HttpCode, Param, Post, UseGuards } from "@nestjs/common";
import { ArtworkService } from "./artwork.service";
import { JwtAuthGuard } from "src/auth/guards/jwt.guard";
import { FetchArtworkParamsDto } from "./dto/fetchArtworkParams.dto";
import { ArtworkDto } from "./dto/artwork.dto";
import { ArtworkEntity } from "./entities/artwork.entity";
import { CurrentUser } from "src/auth/decorators/authenticatedUser.decorator";
import type { AuthenticatedUser } from "src/auth/strategies/jwt.strategy";
import { CreateArtworkBodyDto } from "./dto/createArtworkBody.dto";
import { SaveArtworkBodyDto } from "./dto/saveArtwork.dto";
import { DeleteArtworkParamsDto } from "./dto/deleteArtworkParams.dto";

@Controller('artwork')
export class ArtworkController {
   private readonly artworkService: ArtworkService;

   constructor(artworkService: ArtworkService) {
      this.artworkService = artworkService;
   }



   /*
   route GET artwork/fetch/:artworkId

   expects: {
      artworkId: string;
   }

   gets an artwork object from the database based on the artwork id provided

   returns: ClientArtworkDto
   */
   @Get('fetch/:id')
   @HttpCode(200)
   @UseGuards(JwtAuthGuard)
   async fetch(@CurrentUser() currentUser: AuthenticatedUser, @Param() params: FetchArtworkParamsDto) {
      const artworkList: ArtworkEntity[] = await this.artworkService.fetchArtworkList({ userId: currentUser.id, id: params.id, limit: 1 });
      const normalizedArtworkList: ArtworkDto[] =  await this.artworkService.createDtoList(artworkList);
      return normalizedArtworkList[0];
   }

   

   /*
   route GET artwork/fetchAll

   get a list of all artworks associated with the current user

   returns: ArtworkDto[]
   */
   @Get('fetchAll')
   @HttpCode(200)
   @UseGuards(JwtAuthGuard)
   async fetchAll(@CurrentUser() currentUser: AuthenticatedUser) {
      const artworkList: ArtworkDto[] = await this.artworkService.fetchArtworkList({ userId: currentUser.id });
      return artworkList;
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
   @HttpCode(201)
   @UseGuards(JwtAuthGuard)
   async create(@CurrentUser() currentUser: AuthenticatedUser, @Body() payload: CreateArtworkBodyDto) {
      const newArtwork: ArtworkDto = await this.artworkService.createArtwork({userId: currentUser.id, ...payload});
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
   @HttpCode(204)
   @UseGuards(JwtAuthGuard)
   async save(@CurrentUser() currentUser: AuthenticatedUser, @Body() payload: SaveArtworkBodyDto) {
      await this.artworkService.saveArtwork({userId: currentUser.id, ...payload});
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
   @HttpCode(204)
   @UseGuards(JwtAuthGuard)
   async delete(@CurrentUser() currentUser: AuthenticatedUser, @Body() payload: DeleteArtworkParamsDto) {
      await this.artworkService.deleteArtwork({userId: currentUser.id, ...payload});
   }
};
import { Controller, Get, HttpException, Param, Res } from "@nestjs/common";
import type { Response } from "express";
import { VolumeService } from "./volume.service";

// get access to any saved images using the public directory
@Controller("public")
export class VolumeController {
   private readonly volumeService: VolumeService;

   constructor(volumeService: VolumeService) {
      this.volumeService = volumeService;
   }

   @Get(':folder/:filename')
   async downloadFile(
      @Param('folder') folder: string,
      @Param('filename') filename: string,
      @Res() response: Response,
   ) {
      try {
         return await this.volumeService.getImage(folder, filename, response);
      }
      catch (error) {
         if (error instanceof HttpException) { throw error; }
         else { 
            console.error(error);
            throw new HttpException("Internal server error", 500);
         }
      }
   }
}
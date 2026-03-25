import { IsNotEmpty, IsString } from "class-validator";

export class CreateArtworkBodyDto {
   
   @IsString()
   @IsNotEmpty()
   title: string;

   @IsString()
   @IsNotEmpty()
   prompt: string;
}
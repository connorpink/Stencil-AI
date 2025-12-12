import { IsNotEmpty, IsString } from "class-validator";

export class CreateArtworkDto {
   @IsString()
   @IsNotEmpty()
   title: string;

   @IsString()
   @IsNotEmpty()
   prompt: string;
}
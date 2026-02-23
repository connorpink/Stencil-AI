import { IsNotEmpty, IsString } from "class-validator";

export class RouteDeleteArtworkDto {
   @IsString()
   @IsNotEmpty()
   id: string;
}
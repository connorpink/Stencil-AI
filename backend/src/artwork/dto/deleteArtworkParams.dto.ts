import { IsMongoId, IsNotEmpty } from "class-validator";

export class DeleteArtworkParamsDto {

   @IsMongoId()
   @IsNotEmpty()
   id: string;
}
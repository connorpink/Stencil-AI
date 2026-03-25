import { IsMongoId, IsNotEmpty } from 'class-validator';

export class FetchArtworkParamsDto {
  
  @IsMongoId()
  @IsNotEmpty()
  id: string;
}
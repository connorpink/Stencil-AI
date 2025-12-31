import { IsMongoId, IsNotEmpty } from 'class-validator';

export class RouteFetchArtworkDto {
  @IsMongoId()
  @IsNotEmpty()
  artworkId: string;
}
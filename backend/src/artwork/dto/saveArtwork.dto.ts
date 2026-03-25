import { IsNotEmpty, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { ArtworkDto } from './artwork.dto';

export class SaveArtworkBodyDto {

  @IsNotEmpty()
  @ValidateNested()
  @Type(() => ArtworkDto)
  artwork: ArtworkDto;
}
import { IsString, IsNotEmpty, IsArray, ValidateNested, IsNumber, IsDate, IsMongoId } from 'class-validator';
import { Type } from 'class-transformer';


// basically payload = { artwork: artworkDto }

class RouteArtworkDto {
  @IsMongoId()
  id: string;

  @IsString()
  @IsNotEmpty()
  title: string;

  @IsString()
  @IsNotEmpty()
  prompt: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => RouteStencilDto)
  stencilList: RouteStencilDto[];

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => RouteStrokeDto)
  strokeList: RouteStrokeDto[];

  @IsDate()
  @Type(() => Date)
  updatedAt: Date;
}

class RouteOffsetDto {
  @IsNumber()
  dx: number;

  @IsNumber()
  dy: number;
}

class RouteStencilDto {
  @IsString()
  @IsNotEmpty()
  prompt: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => RouteImageDto)
  imageList: RouteImageDto[];
}

class RouteImageDto {
  @IsString()
  @IsNotEmpty()
  url: string;

  // Add other image properties as needed
}

class RouteStrokeDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => RouteOffsetDto)
  points: RouteOffsetDto[];

  @IsNumber()
  color: number;

  @IsNumber()
  brushSize: number;
}

export class RouteSaveArtworkDto {
  @ValidateNested()
  @Type(() => RouteArtworkDto)
  artwork: RouteArtworkDto;
}
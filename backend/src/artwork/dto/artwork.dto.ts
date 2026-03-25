import { IsArray, IsDate, IsMongoId, IsNotEmpty, IsString, ValidateNested } from "class-validator";
import { StencilDto } from "./stencil.dto";
import { StrokeDto } from "./stroke.dto";
import { Type } from "class-transformer";

export class ArtworkDto {
   
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
   @Type(() => StencilDto)
   stencilList: StencilDto[];

   @IsArray()
   @ValidateNested({ each: true })
   @Type(() => StrokeDto)
   strokeList: StrokeDto[];

   @IsDate()
   @Type(() => Date)
   updatedAt: Date;
}
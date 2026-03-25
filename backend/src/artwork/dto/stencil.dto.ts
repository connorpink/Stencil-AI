import { Type } from "class-transformer";
import { IsArray, IsNotEmpty, IsNumber, IsOptional, IsString, ValidateNested } from "class-validator";
import { ImageDto } from "src/oeno/dto/image.dto";
import { IsPointTuple } from "./extraDtoValidator";

export class StencilDto {

   @IsString()
   @IsNotEmpty()
   prompt: string;

   @IsNumber()
   @IsNotEmpty()
   preferredImageIndex: number;

   @IsArray()
   @ValidateNested({ each: true })
   @Type(() => ImageDto)
   imageList: ImageDto[];

   @IsOptional()
   @IsPointTuple()
   position?: [number, number];

   @IsOptional()
   @IsNumber()
   rotation?: number;

   @IsOptional()
   @IsNumber()
   scale?: number;
}
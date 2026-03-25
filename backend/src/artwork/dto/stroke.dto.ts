import { IsArray, IsNumber } from "class-validator";
import { IsPointTuple } from "./extraDtoValidator";

export class StrokeDto {

   @IsArray()
   @IsPointTuple({ each: true })
   pointList: [number, number][];

   @IsNumber()
   color: number;

   @IsNumber()
   brushSize: number;
}
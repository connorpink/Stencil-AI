import { IsString } from "class-validator";


export class oenoPromptDto {
   @IsString()
   prompt: string;
}
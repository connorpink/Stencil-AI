import { IsString } from "class-validator";

export class RequestLoginDto {
   @IsString()
   username: string;

   @IsString()
   password: string;
}
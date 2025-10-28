import { IsEmail, IsString } from "class-validator";

export class RequestRegisterDto {
   @IsString() 
   username: string;

   @IsEmail() 
   email: string;

   @IsString() 
   password: string;
}
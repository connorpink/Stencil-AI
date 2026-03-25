import { IsNotEmpty, IsString } from "class-validator"

export class ImageDto {

   @IsString()
   @IsNotEmpty()
   path: string;


   url: string;
   size?: number | null;
   orig_name?: string | null;
   mime_type?: string | null;
   is_stream: boolean;
   meta: Record<string, unknown>;
}
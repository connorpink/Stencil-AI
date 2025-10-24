import { Controller } from '@nestjs/common';
import { AuthPayloadDto } from './dto/auth.dto';

@Controller('auth')
export class AuthController {

   @Post('login')
   login(@Body() payload: AuthPayloadDto) {

   }
}
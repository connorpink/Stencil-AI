import { Body, Controller, Post, Get, HttpException, UseGuards, Req } from '@nestjs/common';
import { AuthPayloadDto } from './dto/auth.dto';
import { AuthService } from './auth.service';
import type { Request } from 'express';
import { JwtAuthGuard } from './guards/jwt.guard';
import { LocalGuard } from './guards/local.guard';

@Controller('auth')
export class AuthController {
   private readonly authService: AuthService;

   constructor(authService: AuthService) {
      this.authService = authService;
   }

   @Post('login')
   @UseGuards(LocalGuard)
   login(@Body() payload: AuthPayloadDto) {
      const user = this.authService.validateUser(payload)
      if (!user) { throw new HttpException('Invalid credentials', 401); }
      return user;
   }

   @Get('status')
   @UseGuards(JwtAuthGuard)
   status(@Req() req: Request) {
      return req.user;
   }
}
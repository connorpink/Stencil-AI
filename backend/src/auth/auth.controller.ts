import { Body, Controller, Post, Get, HttpException, UseGuards, Req } from '@nestjs/common';
import { LoginDto } from './dto/login.dto';
import { AuthService } from './auth.service';
import type { Request } from 'express';
import { JwtAuthGuard } from './guards/jwt.guard';
import { LocalGuard } from './guards/local.guard';
import { RegisterDto } from './dto/register.dto';

@Controller('auth')
export class AuthController {
   private readonly authService: AuthService;

   constructor(authService: AuthService) {
      this.authService = authService;
   }

   @Post('register')
   async register(@Body() payload: RegisterDto) {
      const createdUser = await this.authService.registerUser(payload)
      if (!createdUser) { throw new HttpException('AuthService failed to create new user', 500) }
      const createdTokens = await this.authService.createTokens(createdUser)
      if (!createdTokens) { throw new HttpException('AuthService failed to created refresh tokens', 500) }
      return createdTokens
   }

   @Post('login')
   @UseGuards(LocalGuard)
   async login(@Body() payload: LoginDto) {
      const validUser = await this.authService.validateUser(payload)
      if (!validUser) { throw new HttpException('AuthService failed to validate user', 500)}
      const jwtToken = await this.authService.createTokens(validUser)
      if (!jwtToken) { throw new HttpException('AuthService failed to create tokens', 500); }
      return jwtToken;
   }

   @Get('status')
   @UseGuards(JwtAuthGuard)
   async status(@Req() req: Request) {
      return req.user;
   }
}
import { Body, Controller, Post, Get, HttpException, UseGuards, Req, Res } from '@nestjs/common';
import { AuthService } from './auth.service';
import type { Request, Response } from 'express';
import { JwtAuthGuard } from './guards/jwt.guard';
import { LocalGuard } from './guards/local.guard';

import { RequestRegisterDto } from './dto/register.dto';
import { RequestLoginDto } from './dto/login.dto';

@Controller('auth')
export class AuthController {
   private readonly authService: AuthService;

   constructor(authService: AuthService) {
      this.authService = authService;
   }

   @Post('register')
   async register(@Body() payload: RequestRegisterDto) {
      const createdUser = await this.authService.registerUser(payload)
      if (!createdUser) { throw new HttpException('AuthService failed to create new user', 500) }
      const createdTokens = await this.authService.createTokens(createdUser)
      if (!createdTokens) { throw new HttpException('AuthService failed to created refresh tokens', 500) }
      return createdTokens
   }

   @Post('login')
   @UseGuards(LocalGuard)
   async login(@Body() payload: RequestLoginDto, @Res({passthrough: true}) res: Response) {
      const validUser = await this.authService.validateUser(payload)
      if (!validUser) { throw new HttpException('AuthService failed to validate user', 500)}
      const { accessToken, refreshToken } = await this.authService.createTokens(validUser)
      if (!accessToken || !refreshToken) { throw new HttpException('AuthService failed to create tokens', 500); }

      // send tokens back to client in the form of cookies
      res.cookie('access_token', accessToken);
      res.cookie('refresh_token', refreshToken, { maxAge: 30 * 24 * 60 * 60 * 1000 /* 30 days */ });

      return { message: 'Login successful', validUser };
   }

   @Get('status')
   @UseGuards(JwtAuthGuard)
   async status(@Req() req: Request) {
      return req.user;
   }

   @Get('refresh')
   async refresh(@Req() request: Request, @Res({passthrough: true}) res: Response) {
      const refreshToken = request.cookies['refresh_token'];
      if (!refreshToken) { throw new HttpException('No refresh token provided', 401) }
      const updatedToken = await this.authService.refresh(refreshToken);
      res.cookie('access_token', updatedToken);
      return { message: 'Token refresh successful', updatedToken}
   }
}
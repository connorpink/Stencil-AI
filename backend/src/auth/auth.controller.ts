import { Body, Controller, Post, Get, HttpException, UseGuards, Req, Res } from '@nestjs/common';
import { AuthService } from './auth.service';
import type { Request, Response } from 'express';
import { JwtAuthGuard } from './guards/jwt.guard';

import { UserDto } from 'src/server.types';
import { RequestRegisterDto } from './dto/register.dto';
import { RequestLoginDto } from './dto/login.dto';

@Controller('auth')
export class AuthController {
   private readonly authService: AuthService;

   constructor(authService: AuthService) {
      this.authService = authService;
   }

   @Get('status')
   @UseGuards(JwtAuthGuard)
   async status(@Req() req: Request) {
      return req.user;
   }

   @Post('register')
   async register(@Body() payload: RequestRegisterDto, @Res({passthrough: true}) res: Response) {

      // create user inside the database
      const createdUser = await this.authService.registerUser(payload);
      if (!createdUser) { throw new HttpException('AuthService failed to create new user', 500); }

      // create authentication tokens
      const {accessToken, refreshToken} = await this.authService.createTokens(createdUser);
      if (!accessToken || !refreshToken) { throw new HttpException('AuthService failed to create tokens', 500); }

      // save tokens client side as cookies
      res.cookie('access_token', accessToken);
      res.cookie('refreshToken', refreshToken, { maxAge: 30 * 24 * 60 * 60 * 1000 /* 30 days */ });

      return createdUser;
   }

   @Post('login')
   async login(@Body() payload: RequestLoginDto, @Res({passthrough: true}) res: Response) {

      // verify users credentials
      const validUser = await this.authService.validateUser(payload);
      if (!validUser) { throw new HttpException('AuthService failed to validate user', 500); }

      // create authentication tokens
      const { accessToken, refreshToken } = await this.authService.createTokens(validUser);
      if (!accessToken || !refreshToken) { throw new HttpException('AuthService failed to create tokens', 500); }

      // save tokens client side as cookies
      res.cookie('access_token', accessToken);
      res.cookie('refresh_token', refreshToken, { maxAge: 30 * 24 * 60 * 60 * 1000 /* 30 days */ });

      return validUser;
   }

   @Post('deleteAccount')
   @UseGuards(JwtAuthGuard)
   async deleteAccount(@Req() req: Request) {

      const currentUser: UserDto | undefined = req.user;
      if (!currentUser) { throw new HttpException('user must be signed in to delete account', 401) }
      await this.authService.deleteAccount(currentUser);

      return { message: 'Account deleted' }
   }

   @Post('refresh')
   async refresh(@Req() req: Request, @Res({passthrough: true}) res: Response) {

      // make sure refresh token was provided
      const refreshToken = req.cookies['refresh_token'];
      if (!refreshToken) { throw new HttpException('No valid refresh token provided', 401) }

      // use the refresh token to obtain a new access token
      const updatedToken = await this.authService.refresh(refreshToken);
      res.cookie('access_token', updatedToken);

      return { message: 'Token refresh successful' }
   }

   @Post('logout')
   async logout(@Res() res: Response) {
      res.clearCookie('access_token');
      res.clearCookie('refresh_token');
      return { message: 'Logout successful' }; 
   }
}
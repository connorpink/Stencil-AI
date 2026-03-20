import { Body, Controller, Post, Get, HttpException, UseGuards, Req, Res, HttpCode, Delete } from '@nestjs/common';
import { AuthService } from './auth.service';
import type { Request, Response } from 'express';
import { JwtAuthGuard } from './guards/jwt.guard';

import { UserDto } from 'src/server.types';
import { RequestRegisterDto } from './dto/register.dto';
import { RequestLoginDto } from './dto/login.dto';
import { RefreshDto } from './dto/refresh.dto';

@Controller('auth')
export class AuthController {
   private readonly authService: AuthService;

   constructor(authService: AuthService) {
      this.authService = authService;
   }

   @Get('status')
   @HttpCode(200)
   @UseGuards(JwtAuthGuard)
   async status(@Req() req: Request) {

      return req.user;
   }

   @Post('register')
   @HttpCode(201)
   async register(@Body() payload: RequestRegisterDto) {

      const createdUser = await this.authService.registerUser(payload); // create user inside the database
      const {accessToken, refreshToken} = await this.authService.createTokens(createdUser); // create authentication tokens

      return {
         accessToken: accessToken,
         refreshToken: refreshToken,
         user: createdUser
      };
   }

   @Post('login')
   @HttpCode(200)
   async login(@Body() payload: RequestLoginDto) {

      const validUser = await this.authService.validateUser(payload); // verify users credentials
      const { accessToken, refreshToken } = await this.authService.createTokens(validUser); // create authentication tokens

      return {
         accessToken: accessToken,
         refreshToken: refreshToken,
         user: validUser
      };
   }

   @Delete()
   @HttpCode(201)
   @UseGuards(JwtAuthGuard)
   async deleteAccount(@Req() req: Request) {

      const currentUser: UserDto = req.user!;
      await this.authService.deleteAccount(currentUser);

      return { message: 'Account deleted' }
   }

   @Post('refresh')
   async refresh(@Body() payload: RefreshDto ) {

      const updatedAccessToken = await this.authService.refresh(payload.refreshToken); // use the refresh token to obtain a new access token

      return { accessToken: updatedAccessToken }
   }
}
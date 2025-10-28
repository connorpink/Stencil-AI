import { HttpException, Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt'
import lodash from 'lodash';
import bcrypt from 'bcrypt';

import { DatabaseService } from '../database/database.service'

import { UserDto } from '../server.types';
import { DatabaseUserDto } from '../database/database.types'
import { RequestLoginDto } from './dto/login.dto';
import { RequestRegisterDto } from './dto/register.dto';

@Injectable()
export class AuthService {
   private readonly jwtService: JwtService;
   private readonly database: DatabaseService;

   constructor(jwtService: JwtService, database: DatabaseService) {
      this.jwtService = jwtService; 
      this.database = database;
   }

   async registerUser({username, email, password}: RequestRegisterDto) {
      
      //check if username or email already exists inside the database
      try {
         const fetchedUsername = await this.database.query<DatabaseUserDto>("SELECT * FROM users_public WHERE username = $1", [username])
         if (fetchedUsername.rows.length >= 1) { throw new HttpException('Username already taken', 401) }

         const fetchedEmail = await this.database.query<DatabaseUserDto>("SELECT * FROM users_public WHERE email = $1", [email])
         if (fetchedEmail.rows.length >= 1) { throw new HttpException('Email already in use', 401) }
      }
      catch (error) {
         if (error instanceof HttpException) { throw error }
         console.error("\x1b[31m[AuthService] Server failed to check availability of the username and email\x1b[0m\n", error);
         throw new HttpException('Internal server error', 500);
      }

      // hash the users password
      let hashedPassword: string;
      try {
         const saltRounds = 10
         hashedPassword = await bcrypt.hash(password, saltRounds)
      }
      catch (error) {
         console.error("\x1b[31m[AuthService] Server failed hash the users password\x1b[0m\n", error);
         throw new HttpException('Internal server error', 500);
      }

      // add user to the database
      let createdUser: DatabaseUserDto;
      try {
         const createdUserData = await this.database.query<DatabaseUserDto>(
            "INSERT INTO Users (username, email, password) VALUES ($1, $2, $3) RETURNING id, username", 
            [username, email, hashedPassword]
         );
         createdUser = createdUserData.rows[0];
      }
      catch (error) {
         console.error("\x1b[31m[AuthService] Server failed to add user to the database\x1b[0m\n", error);
         throw new HttpException('Internal server error', 500);
      }
      
      return createdUser;
   }

   async validateUser({username, password}: RequestLoginDto) {

      // grab user from the database
      let fetchedUser: DatabaseUserDto | null = null;
      try {
         const fetchedData = await this.database.query<DatabaseUserDto>("SELECT * FROM users_private WHERE username = $1", [username])
         fetchedUser = fetchedData.rows[0] ?? null;
      }
      catch (error) {
         console.error("\x1b[31m[AuthService] Server failed to fetch username from the database\x1b[0m\n", error);
         throw new HttpException('Internal server error', 500);
      }

      if (!fetchedUser) { throw new HttpException('Invalid credentials', 401); }

      // check if the client provided the correct password
      let correctPassword: boolean = false;
      try {
         correctPassword = await bcrypt.compare(password, fetchedUser.password);
      }
      catch (error) {
         console.error("\x1b[31m[AuthService] Server failed to verify if the clients password was correct\x1b[0m\n", error);
         throw new HttpException("Internal server error", 500);
      }
      
      if (correctPassword) {
         const user = lodash.pick(fetchedUser, ['id', 'username']);
         return user;
      }
   }

   async createTokens({id, username}: UserDto) {
      const tokens = this.jwtService.sign({id, username});
      return tokens;
   }
}
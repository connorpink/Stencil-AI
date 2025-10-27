import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt'
import lodash from 'lodash';
import { DatabaseService } from '../database/database.service'
import { AuthPayloadDto } from './dto/auth.dto';
import { User } from '../database/database.types'

@Injectable()
export class AuthService {
   private readonly jwtService: JwtService;
   private readonly database: DatabaseService;

   constructor(jwtService: JwtService, database: DatabaseService) {
      this.jwtService = jwtService; 
      this.database = database;
   }

   async validateUser({username, password}: AuthPayloadDto) {
      let fetchedUser: User | null = null;

      try {
         const fetchedData = await this.database.query<User>("SELECT * FROM users WHERE username = $1", [username])
         fetchedUser = fetchedData.rows[0] ?? null;
      }
      catch (error) {
         console.error("\x1b[31m[AuthService] Server failed to fetch username from the database\x1b[0m\n", error);
      }

      if (!fetchedUser) { throw new UnauthorizedException('Invalid credentials'); }

      if (password === fetchedUser?.password_hash) {
         const user = lodash.pick(fetchedUser, ['id', 'username']);
         const tokens = this.jwtService.sign(user);
         return tokens;
      }
   }
}
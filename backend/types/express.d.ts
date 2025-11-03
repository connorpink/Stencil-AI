export {}

import type { UserDto } from '../src/server.types'

declare global {
  namespace Express {
    interface User extends UserDto {}

    interface Request {
      user?: UserDto;
    }
  }
}
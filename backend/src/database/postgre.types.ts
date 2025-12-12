// to access the users table use users_public and users_private
// users_public should be used for fetching data
// users_private should be used for manipulating the users table, only use if for fetching if you NEED the private data, and make sure it's NEVER sent to the client
export type DatabaseUserDto = {
   id: number;
   username: string;
   email: string;
   password: string; // blocked in users_public
   created_at: Date;
}

export type DatabaseRefreshTokenDto = {
   user_id: number;
   token: string;
}
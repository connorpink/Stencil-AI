export type User = {
   id: number;
   username: string;
   password_hash: string;
   password_salt: string;
   created_at?: Date;
}
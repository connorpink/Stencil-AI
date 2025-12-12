import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { Pool, QueryResult, QueryResultRow } from 'pg';


@Injectable()
export class DatabaseService implements OnModuleDestroy {
	private pool: Pool
	
	async onModuleInit() {
		this.pool = new Pool({
			host: process.env.POSTGRES_HOST,
			user: process.env.POSTGRES_USER,
			database: process.env.POSTGRES_DATABASE,
			password: process.env.POSTGRES_PASSWORD,
			port: Number(process.env.POSTGRES_PORT),
		});

		try {
			const client = await this.pool.connect();
			console.log('Connected to PostgreSQL')
			client.release();
		}
		catch (error) {
			console.error("\x1b[31m[AuthService] Server failed to establish a connection with the database\x1b[0m\n", error);
		}
	}

	// this function is deliberately rigid so someone doesn't use it wrong an introduce possible injection
	async query<T extends QueryResultRow = QueryResultRow>(query: string, params: any[]): Promise<QueryResult<T>> {
		return this.pool.query<T>(query, params);
	}

	async onModuleDestroy() {
		await this.pool.end();
		console.warn('PostgreSQL connection closed')
	}

	
}

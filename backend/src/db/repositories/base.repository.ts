/**
 * Base repository with common database operations
 */

import { Pool, PoolClient, QueryResult, QueryResultRow } from 'pg';
import { getDbPool, createDbPool } from '../client';

export abstract class BaseRepository {
  protected getPool(): Pool {
    let pool = getDbPool();
    if (!pool) {
      pool = createDbPool();
    }
    return pool;
  }

  protected async query<T extends QueryResultRow>(sql: string, params?: unknown[], client?: PoolClient): Promise<QueryResult<T>> {
    if (client) {
      return client.query<T>(sql, params);
    }
    const pool = this.getPool();
    return pool.query<T>(sql, params);
  }

  protected async queryOne<T extends QueryResultRow>(sql: string, params?: unknown[], client?: PoolClient): Promise<T | null> {
    const result = await this.query<T>(sql, params, client);
    return result.rows[0] || null;
  }

  protected async queryMany<T extends QueryResultRow>(sql: string, params?: unknown[], client?: PoolClient): Promise<T[]> {
    const result = await this.query<T>(sql, params, client);
    return result.rows;
  }

  public async transaction<T>(callback: (client: PoolClient) => Promise<T>): Promise<T> {
    const pool = this.getPool();
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const result = await callback(client);
      await client.query('COMMIT');
      return result;
    } catch (e) {
      await client.query('ROLLBACK');
      throw e;
    } finally {
      client.release();
    }
  }
}

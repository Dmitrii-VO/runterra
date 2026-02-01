/**
 * Base repository with common database operations
 */

import { Pool, QueryResult, QueryResultRow } from 'pg';
import { getDbPool, createDbPool } from '../client';

export abstract class BaseRepository {
  protected getPool(): Pool {
    let pool = getDbPool();
    if (!pool) {
      pool = createDbPool();
    }
    return pool;
  }

  protected async query<T extends QueryResultRow>(sql: string, params?: unknown[]): Promise<QueryResult<T>> {
    const pool = this.getPool();
    return pool.query<T>(sql, params);
  }

  protected async queryOne<T extends QueryResultRow>(sql: string, params?: unknown[]): Promise<T | null> {
    const result = await this.query<T>(sql, params);
    return result.rows[0] || null;
  }

  protected async queryMany<T extends QueryResultRow>(sql: string, params?: unknown[]): Promise<T[]> {
    const result = await this.query<T>(sql, params);
    return result.rows;
  }
}

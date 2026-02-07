/**
 * One-off: set club "Лупкины" status to active and verify.
 * Usage: from backend: npx ts-node scripts/fix-lupkiny-club.ts
 * Requires: .env with DB_* or env vars (same as migrate).
 */

import 'dotenv/config';
import { Pool } from 'pg';
import { getDbConfig } from '../src/config/db';

const CLUB_NAME = 'Лупкины';

async function main(): Promise<void> {
  const config = getDbConfig();
  const pool = new Pool(config);

  console.log(`Connecting to ${config.database}@${config.host}:${config.port}...`);

  try {
    await pool.query('SELECT 1');
    console.log('Connected.\n');

    const before = await pool.query<{ id: string; name: string; status: string; city_id: string }>(
      `SELECT id, name, status, city_id FROM clubs WHERE name = $1`,
      [CLUB_NAME]
    );

    if (before.rows.length === 0) {
      console.log(`Club "${CLUB_NAME}" not found in DB. Nothing to update.`);
      const allClubs = await pool.query<{ id: string; name: string; status: string }>(
        'SELECT id, name, status FROM clubs ORDER BY created_at DESC LIMIT 10'
      );
      console.log('Recent clubs:', allClubs.rows);
      return;
    }

    console.log('Before:', before.rows);

    const updated = await pool.query(
      `UPDATE clubs SET status = $1, updated_at = NOW() WHERE name = $2 RETURNING id, name, status`,
      ['active', CLUB_NAME]
    );

    console.log('After update:', updated.rows);

    const after = await pool.query<{ id: string; name: string; status: string }>(
      `SELECT id, name, status FROM clubs WHERE name = $1`,
      [CLUB_NAME]
    );

    if (after.rows[0]?.status === 'active') {
      console.log('\nOK: club status is now "active".');
    } else {
      console.log('\nUnexpected state after update:', after.rows);
    }
  } catch (e) {
    console.error('Error:', e);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

main();

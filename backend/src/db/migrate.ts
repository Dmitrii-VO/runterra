/**
 * Simple migration runner for PostgreSQL
 * 
 * Usage: npx ts-node src/db/migrate.ts
 * Or after build: node dist/db/migrate.js
 */

import { Pool } from 'pg';
import * as fs from 'fs';
import * as path from 'path';
import { getDbConfig } from '../config/db';

async function runMigrations(): Promise<void> {
  const config = getDbConfig();
  const pool = new Pool(config);

  console.log(`Connecting to database ${config.database}@${config.host}:${config.port}...`);

  try {
    // Test connection
    await pool.query('SELECT 1');
    console.log('Connected successfully.');

    // Get migrations directory (always use src, not dist)
    // __dirname in compiled code is dist/db, so we go up to project root
    const projectRoot = path.resolve(__dirname, '..', '..');
    const migrationsDir = path.join(projectRoot, 'src', 'db', 'migrations');
    
    if (!fs.existsSync(migrationsDir)) {
      console.log('No migrations directory found.');
      return;
    }

    // Get all SQL files sorted by name
    const files = fs.readdirSync(migrationsDir)
      .filter(f => f.endsWith('.sql'))
      .sort();

    if (files.length === 0) {
      console.log('No migration files found.');
      return;
    }

    console.log(`Found ${files.length} migration file(s).`);

    // Check which migrations are already applied
    const appliedResult = await pool.query(`
      SELECT name FROM migrations ORDER BY name
    `).catch(() => ({ rows: [] })); // Table might not exist yet

    const applied = new Set(appliedResult.rows.map((r: { name: string }) => r.name));

    // Run pending migrations
    for (const file of files) {
      const migrationName = file.replace('.sql', '');
      
      if (applied.has(migrationName)) {
        console.log(`  ✓ ${migrationName} (already applied)`);
        continue;
      }

      console.log(`  → Running ${migrationName}...`);
      
      const filePath = path.join(migrationsDir, file);
      const sql = fs.readFileSync(filePath, 'utf-8');

      await pool.query(sql);
      console.log(`  ✓ ${migrationName} applied successfully.`);
    }

    console.log('All migrations completed.');

  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

runMigrations();

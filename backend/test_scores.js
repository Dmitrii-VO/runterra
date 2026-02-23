const { Pool } = require('pg');
const pool = new Pool({ connectionString: 'postgres://postgres:postgres@localhost:5432/runterra' });
async function check() {
  const seasonStart = new Date(Date.UTC(new Date().getUTCFullYear(), new Date().getUTCMonth(), 1));
  const scores = await pool.query(`SELECT * FROM territory_club_scores WHERE season_start = $1 ORDER BY territory_id, total_meters DESC`, [seasonStart]);
  console.log(scores.rows);
  pool.end();
}
check();
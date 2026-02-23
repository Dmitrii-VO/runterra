const { Pool } = require('pg');
const pool = new Pool({ connectionString: 'postgres://postgres:postgres@localhost:5432/runterra' });
async function check() {
  const res = await pool.query(`SELECT r.id, r.distance, r.scoring_club_id, r.status, u.name as user_name FROM runs r JOIN users u ON u.id = r.user_id WHERE u.name ILIKE '%Lucky%' OR u.first_name ILIKE '%Lucky%'`);
  console.log(res.rows);
  pool.end();
}
check();
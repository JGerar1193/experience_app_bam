import 'dotenv/config';
import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { pool } from '../src/db/pool';

async function setupDatabase(): Promise<void> {
  try {
    const sql = await readFile(resolve(process.cwd(), 'database', 'init.sql'), 'utf8');
    await pool.query(sql);
    console.log('Esquema y datos de ejemplo listos.');
  } finally {
    await pool.end();
  }
}

void setupDatabase().catch((error: unknown) => {
  console.error('No se pudo preparar la base de datos.', error);
  process.exitCode = 1;
});

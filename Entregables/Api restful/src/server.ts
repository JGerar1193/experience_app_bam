import 'dotenv/config';
import { app } from './app';
import { pool } from './db/pool';

const port = Number(process.env.PORT ?? 3000);

async function start(): Promise<void> {
  await pool.query('SELECT 1');
  const server = app.listen(port, () => {
    console.log(`API disponible en http://localhost:${port}`);
  });

  const shutdown = (): void => {
    server.close(() => {
      void pool.end().then(() => process.exit(0));
    });
  };

  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}

void start().catch((error: unknown) => {
  console.error('No se pudo iniciar la API. Verifica la conexion a PostgreSQL.', error);
  process.exit(1);
});

import type { ClientConfig } from 'pg';

export function getTestDatabaseConfig(
  environment: NodeJS.ProcessEnv = process.env,
): ClientConfig {
  const database = environment.TEST_PGDATABASE;
  if (!database || !/^(?:test_[a-z0-9_]+|[a-z0-9_]+_test)$/.test(database)) {
    throw new Error('TEST_PGDATABASE must start with test_ or end with _test.');
  }

  const host = environment.TEST_PGHOST ?? '127.0.0.1';
  if (!['127.0.0.1', 'localhost', '::1'].includes(host)) {
    throw new Error('Only local PostgreSQL is allowed in this test harness.');
  }

  const portText = environment.TEST_PGPORT ?? '5432';
  const port = Number(portText);
  if (!/^\d+$/.test(portText) || !Number.isInteger(port) || port < 1 || port > 65535) {
    throw new Error('TEST_PGPORT must be a valid TCP port.');
  }

  const user = environment.TEST_PGUSER;
  if (!user?.trim()) {
    throw new Error('TEST_PGUSER must be configured explicitly.');
  }
  if (environment.TEST_PGPASSWORD === undefined) {
    throw new Error('TEST_PGPASSWORD must be configured explicitly.');
  }

  return {
    host,
    port,
    database,
    user,
    password: environment.TEST_PGPASSWORD,
    ssl: false,
    connectionTimeoutMillis: 3000,
    query_timeout: 3000,
    options: '-c default_transaction_read_only=on -c statement_timeout=3000',
  };
}
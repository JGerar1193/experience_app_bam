import { describe, expect, it } from '@jest/globals';
import { getTestDatabaseConfig } from '../support/database-config';

describe('TEST-008 isolated PostgreSQL configuration', () => {
  const environment: NodeJS.ProcessEnv = {
    TEST_PGHOST: '127.0.0.1',
    TEST_PGPORT: '5432',
    TEST_PGDATABASE: 'transfer_test',
    TEST_PGUSER: 'test_user',
    TEST_PGPASSWORD: 'synthetic-unit-fixture',
  };

  it('requires explicit test configuration instead of using pg defaults', () => {
    expect(() => getTestDatabaseConfig({})).toThrow('TEST_PGDATABASE');
  });

  it('accepts a dedicated local test database with bounded read-only queries', () => {
    expect(getTestDatabaseConfig(environment)).toMatchObject({
      host: '127.0.0.1',
      port: 5432,
      database: 'transfer_test',
      user: 'test_user',
      connectionTimeoutMillis: 3000,
      query_timeout: 3000,
      options: '-c default_transaction_read_only=on -c statement_timeout=3000',
    });
  });

  it('rejects databases that are not explicitly named for tests', () => {
    expect(() =>
      getTestDatabaseConfig({ ...environment, TEST_PGDATABASE: 'postgres' }),
    ).toThrow('test_ or end with _test');
  });

  it('rejects remote hosts in the local test harness', () => {
    expect(() =>
      getTestDatabaseConfig({ ...environment, TEST_PGHOST: 'bank.example' }),
    ).toThrow('local PostgreSQL');
  });

  it.each(['0', '65536', 'not-a-port'])('rejects invalid port %s', (port) => {
    expect(() =>
      getTestDatabaseConfig({ ...environment, TEST_PGPORT: port }),
    ).toThrow('TEST_PGPORT');
  });

  it('requires an explicit user and password setting', () => {
    expect(() =>
      getTestDatabaseConfig({ ...environment, TEST_PGUSER: undefined }),
    ).toThrow('TEST_PGUSER');
    expect(() =>
      getTestDatabaseConfig({ ...environment, TEST_PGPASSWORD: undefined }),
    ).toThrow('TEST_PGPASSWORD');
  });

  it('never includes supplied credentials in validation errors', () => {
    const secretMarker = 'synthetic-secret-never-print';
    try {
      getTestDatabaseConfig({
        ...environment,
        TEST_PGHOST: secretMarker,
        TEST_PGPASSWORD: secretMarker,
      });
      throw new Error('Expected validation to reject the configuration.');
    } catch (error) {
      expect(String(error)).not.toContain(secretMarker);
      expect(String(error)).toContain('local PostgreSQL');
    }
  });
});
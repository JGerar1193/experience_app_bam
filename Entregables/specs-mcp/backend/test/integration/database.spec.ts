import { describe, expect, it } from '@jest/globals';
import { Client } from 'pg';
import { getTestDatabaseConfig } from '../support/database-config';

describe('TEST-008 PostgreSQL 18 integration', () => {
  it('connects to the isolated database and runs a read-only query', async () => {
    const client = new Client(getTestDatabaseConfig());

    try {
      await client.connect();
      const version = await client.query<{ server_version_num: string }>(
        'SHOW server_version_num',
      );
      const serverVersion = Number(version.rows[0]?.server_version_num);
      expect(serverVersion).toBeGreaterThanOrEqual(180000);
      expect(serverVersion).toBeLessThan(190000);

      const result = await client.query<{ value: number; read_only: string }>(
        "SELECT 1::integer AS value, current_setting('transaction_read_only') AS read_only",
      );
      expect(result.rows).toEqual([{ value: 1, read_only: 'on' }]);
    } catch (error) {
      if (error instanceof Error && error.name === 'Error') {
        throw new Error(
          'PostgreSQL test connection/query failed. Check the local TEST_PG configuration and server availability.',
        );
      }
      throw error;
    } finally {
      await client.end().catch(() => undefined);
    }
  });
});
/**
 * Jest global teardown.
 * Closes DB pool if it was created during tests to avoid "worker failed to exit gracefully".
 */
import { closeDbPool } from './src/db/client';

afterAll(async () => {
  await closeDbPool();
});

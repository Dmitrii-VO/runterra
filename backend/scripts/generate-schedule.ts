import 'dotenv/config';
import { createDbPool, closeDbPool } from '../src/db/client';
import { scheduleGeneratorService } from '../src/modules/schedule/schedule-generator.service';
import { logger } from '../src/shared/logger';

async function main() {
  logger.info('Starting schedule generation script...');
  
  // Initialize DB pool
  createDbPool();

  try {
    await scheduleGeneratorService.generateNextMonth();
    logger.info('Schedule generation completed successfully.');
  } catch (error) {
    logger.error('Schedule generation failed', { error });
    process.exit(1);
  } finally {
    await closeDbPool();
  }
}

main();

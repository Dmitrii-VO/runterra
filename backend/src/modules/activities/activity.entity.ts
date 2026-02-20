import { ActivityType } from './activity.type';
import { ActivityStatus } from './activity.status';

/**
 * Сущность активности (Факт выполнения)
 */
export interface Activity {
  id: string;
  userId: string;
  type: ActivityType;
  status: ActivityStatus;
  name?: string;
  description?: string;
  scheduledItemId?: string; // Привязка к заданию из календаря (event_id или personal_note_id)
  createdAt: Date;
  updatedAt: Date;
}

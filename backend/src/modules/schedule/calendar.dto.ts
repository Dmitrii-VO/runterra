import { z } from 'zod';

/**
 * Элемент календаря (объединенный тип для событий и заметок)
 */
export interface CalendarItemDto {
  id: string;
  type: 'event' | 'note';
  date: string; // ISO date YYYY-MM-DD
  startTime?: string; // HH:mm
  name: string;
  description?: string;
  activityType: string;
  workoutId?: string;
  trainerId?: string;
  status?: string;
  isPersonal: boolean;
  // Поля для связи с фактом (Stage 7)
  isCompleted?: boolean;
  activityId?: string;
}

export const GetCalendarQuerySchema = z.object({
  month: z.string().regex(/^\d{4}-\d{2}$/, 'Format must be YYYY-MM'),
});

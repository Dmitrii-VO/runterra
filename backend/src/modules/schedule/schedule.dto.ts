import { z } from 'zod';

/**
 * DTO для элемента недельного расписания (шаблон)
 */
export interface WeeklyScheduleItemDto {
  id: string;
  clubId: string;
  dayOfWeek: number; // 0-6 (Sunday-Saturday)
  startTime: string; // HH:mm
  activityType: string;
  name: string;
  description?: string;
  workoutId?: string;
  trainerId?: string;
}

/**
 * Схема валидации для создания/обновления элемента расписания
 */
export const CreateWeeklyScheduleItemSchema = z.object({
  dayOfWeek: z.number().min(0).max(6),
  startTime: z.string().regex(/^([01]\d|2[0-3]):([0-5]\d)$/, 'Invalid time format (HH:mm)'),
  activityType: z.string().min(1),
  name: z.string().min(1).max(255),
  description: z.string().optional(),
  workoutId: z.string().uuid().optional(),
  trainerId: z.string().uuid().optional(),
});

export type CreateWeeklyScheduleItemDto = z.infer<typeof CreateWeeklyScheduleItemSchema>;

/**
 * DTO для элемента личного расписания (шаблон)
 */
export interface PersonalScheduleItemDto {
  id: string;
  userId: string;
  dayOfWeek: number;
  name: string;
  description?: string;
  workoutId?: string;
  trainerId?: string;
}

export const CreatePersonalScheduleItemSchema = z.object({
  dayOfWeek: z.number().min(0).max(6),
  name: z.string().min(1).max(255),
  description: z.string().optional(),
  workoutId: z.string().uuid().optional(),
  trainerId: z.string().uuid().optional(),
});

export type CreatePersonalScheduleItemDto = z.infer<typeof CreatePersonalScheduleItemSchema>;

export const SetupPersonalPlanSchema = z.object({
  items: z.array(CreatePersonalScheduleItemSchema),
});

export type SetupPersonalPlanDto = z.infer<typeof SetupPersonalPlanSchema>;

/**
 * DTO для конкретной записи в личном плане (инстанс)
 */
export interface PersonalNoteDto {
  id: string;
  userId: string;
  templateId?: string;
  date: string; // ISO YYYY-MM-DD
  name: string;
  description?: string;
  workoutId?: string;
  trainerId?: string;
  isManuallyEdited: boolean;
  createdAt: Date;
  updatedAt: Date;
}

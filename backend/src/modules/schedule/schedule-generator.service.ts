import {
  getScheduleRepository,
  getEventsRepository,
  getClubsRepository,
} from '../../db/repositories';
import { logger } from '../../shared/logger';
import { EventType } from '../events/event.type';

export class ScheduleGeneratorService {
  /**
   * @deprecated Not called anywhere. Replaced by the Blueprint approach:
   * leaders/trainers use the "Conduct" button in the schedule screen to
   * manually create an Event from a template with a real location.
   * Kept for reference — remove when personal schedule feature is fully designed.
   *
   * Генерация событий и заметок на 31 день вперед
   */
  async generateNextMonth(): Promise<void> {
    const scheduleRepo = getScheduleRepository();
    const eventsRepo = getEventsRepository();
    const clubsRepo = getClubsRepository();

    const today = new Date();

    // 1. Обработка клубных шаблонов
    const weeklyTemplates = await scheduleRepo.getAllWeeklyTemplates();
    for (const template of weeklyTemplates) {
      const club = await clubsRepo.findById(template.clubId);
      if (!club) continue;

      for (let dayOffset = 0; dayOffset <= 31; dayOffset++) {
        const targetDate = new Date(today);
        targetDate.setDate(today.getDate() + dayOffset);

        if (targetDate.getDay() === template.dayOfWeek) {
          const dateStr = targetDate.toISOString().split('T')[0];

          // Проверяем, нет ли уже события
          const existing = await eventsRepo.findByTemplateAndDate(template.id, dateStr);
          if (!existing) {
            const [hours, minutes] = template.startTime.split(':').map(Number);
            const startDateTime = new Date(targetDate);
            startDateTime.setHours(hours, minutes, 0, 0);

            try {
              await eventsRepo.create({
                name: template.name,
                type: template.activityType as EventType,
                startDateTime,
                startLocation: { longitude: 0, latitude: 0 }, // TODO: Default club location
                organizerId: template.clubId,
                organizerType: 'club',
                description: template.description,
                workoutId: template.workoutId,
                trainerId: template.trainerId,
                cityId: club.cityId,
                templateId: template.id,
                generatedForDate: dateStr,
              });

              logger.info(`Generated event for club ${template.clubId} on ${dateStr}`);
            } catch (error) {
              logger.error(`Failed to generate event for template ${template.id}`, { error });
            }
          }
        }
      }
    }

    // 2. Обработка личных шаблонов
    const personalTemplates = await scheduleRepo.getAllPersonalTemplates();
    for (const template of personalTemplates) {
      for (let dayOffset = 0; dayOffset <= 31; dayOffset++) {
        const targetDate = new Date(today);
        targetDate.setDate(today.getDate() + dayOffset);

        if (targetDate.getDay() === template.dayOfWeek) {
          const dateStr = targetDate.toISOString().split('T')[0];

          const existing = await scheduleRepo.findNoteByTemplateAndDate(template.id, dateStr);
          if (!existing) {
            try {
              await scheduleRepo.createPersonalNote({
                userId: template.userId,
                templateId: template.id,
                date: dateStr,
                name: template.name,
                description: template.description,
                workoutId: template.workoutId,
                trainerId: template.trainerId,
              });
              logger.info(`Generated personal note for user ${template.userId} on ${dateStr}`);
            } catch (error) {
              logger.error(`Failed to generate personal note for template ${template.id}`, {
                error,
              });
            }
          }
        }
      }
    }
  }

  /**
   * Синхронизация изменений шаблона с будущими событиями/заметками.
   * Вызывается при обновлении (PATCH) или удалении (DELETE) шаблона.
   *
   * Если templateId передан, но template равен null — значит шаблон удален.
   */
  async syncTemplateChanges(templateId: string, type: 'club' | 'personal'): Promise<void> {
    const eventsRepo = getEventsRepository();
    const scheduleRepo = getScheduleRepository();

    if (type === 'club') {
      const template = await scheduleRepo.findWeeklyItemById(templateId);
      const futureEvents = await eventsRepo.findFutureByTemplate(templateId);

      for (const event of futureEvents) {
        if (event.isManuallyEdited) continue;

        if (!template) {
          // Шаблон удален — мягко удаляем событие
          await eventsRepo.update(event.id, { deletedAt: new Date() });
          logger.info(`Soft-deleted future event ${event.id} (template deleted)`);
        } else {
          // Шаблон обновлен — обновляем событие
          const [hours, minutes] = template.startTime.split(':').map(Number);
          const newStart = new Date(event.startDateTime);
          newStart.setHours(hours, minutes, 0, 0);

          await eventsRepo.update(event.id, {
            name: template.name,
            type: template.activityType as EventType,
            startDateTime: newStart,
            description: template.description,
            workoutId: template.workoutId,
            trainerId: template.trainerId,
          });
          logger.info(`Updated future event ${event.id} from template`);
        }
      }
    } else {
      // Для личных планов в MVP мы пока просто перезаписываем весь шаблон через replacePersonalSchedule,
      // что не требует сложной синхронизации через этот метод, так как старые записи (Notes)
      // могут оставаться как история, а новые сгенерируются кроном.
      // В будущем можно добавить логику удаления будущих Notes.
    }
  }
}

export const scheduleGeneratorService = new ScheduleGeneratorService();

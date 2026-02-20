import { logger } from '../../shared/logger';

export class NotificationsService {
  /**
   * Отправить пуш-уведомление пользователю
   */
  async sendPush(userId: string, title: string, body: string, data?: Record<string, string>): Promise<void> {
    // В реальной реализации здесь будет вызов Firebase Cloud Messaging (FCM)
    logger.info('Sending PUSH notification', { userId, title, body, data });
  }

  /**
   * Отправить пуш-уведомление всем участникам клуба
   */
  async notifyClubMembers(clubId: string, title: string, body: string, data?: Record<string, string>): Promise<void> {
    // В реальной реализации: 
    // 1. Получить всех участников клуба из БД
    // 2. Отправить каждому пуш
    logger.info('Notifying CLUB members via PUSH', { clubId, title, body, data });
  }
}

export const notificationsService = new NotificationsService();

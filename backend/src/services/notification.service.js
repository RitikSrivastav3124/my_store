const NotificationRepository = require('../repositories/notification.repository');
const UserRepository = require('../repositories/user.repository');
const { getMessaging } = require('../config/firebase');
const { buildMeta, buildPagination } = require('../helpers/pagination.helper');
const AppError = require('../utils/appError');
const logger = require('../utils/logger');

class NotificationService {
  static create({ userId, title, body, data = {} }, options = {}) {
    return NotificationRepository.create({ userId, title, body, data }, options);
  }

  static async push({ userId, title, body, data = {} }) {
    try {
      const user = await UserRepository.findById(userId);
      const tokens = user?.fcmTokens || [];
      const messaging = getMessaging();

      if (messaging && tokens.length) {
        const response = await messaging.sendEachForMulticast({
          tokens,
          notification: {
            title,
            body
          },
          data: Object.fromEntries(Object.entries(data).map(([key, value]) => [key, String(value)]))
        });
        const invalidTokens = [];
        response.responses.forEach((item, index) => {
          const code = item.error?.code || '';
          if (
            code.includes('registration-token-not-registered') ||
            code.includes('invalid-registration-token')
          ) {
            invalidTokens.push(tokens[index]);
          }
        });
        if (invalidTokens.length) await UserRepository.removeFcmTokens(userId, invalidTokens);
      }
    } catch (error) {
      logger.warn('Failed to deliver push notification', {
        userId: userId.toString(),
        error: error.message
      });
    }
  }

  static async createAndPush(payload, options = {}) {
    const notification = await this.create(payload, options);
    await this.push(payload);
    return notification;
  }

  static async list(userId, query) {
    const pagination = buildPagination(query);
    const { notifications, total } = await NotificationRepository.listForUser(userId, query, pagination);

    return {
      notifications,
      meta: buildMeta({ ...pagination, total })
    };
  }

  static async markRead(userId, notificationId) {
    const notification = await NotificationRepository.markRead(userId, notificationId);
    if (!notification) throw new AppError('Notification not found', 404);
    return notification;
  }

  static registerFcmToken(userId, token) {
    return UserRepository.addFcmToken(userId, token);
  }
}

module.exports = NotificationService;

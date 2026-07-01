const NotificationRepository = require('../repositories/notification.repository');
const UserRepository = require('../repositories/user.repository');
const { getMessaging } = require('../config/firebase');
const { buildMeta, buildPagination } = require('../helpers/pagination.helper');
const AppError = require('../utils/appError');
const logger = require('../utils/logger');

class NotificationService {
  static async createAndPush({ userId, title, body, data = {} }, options = {}) {
    const notification = await NotificationRepository.create({ userId, title, body, data }, options);

    const user = await UserRepository.findById(userId);
    const tokens = user?.fcmTokens || [];
    const messaging = getMessaging();

    if (messaging && tokens.length) {
      try {
        await messaging.sendEachForMulticast({
          tokens,
          notification: {
            title,
            body
          },
          data: Object.fromEntries(Object.entries(data).map(([key, value]) => [key, String(value)]))
        });
      } catch (error) {
        logger.warn('Failed to deliver push notification', {
          userId: userId.toString(),
          error: error.message
        });
      }
    }

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

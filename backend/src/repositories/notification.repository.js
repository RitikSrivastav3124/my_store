const Notification = require('../models/notification.model');

class NotificationRepository {
  static create(data, options = {}) {
    return Notification.create([data], options).then(([notification]) => notification);
  }

  static async listForUser(userId, filters, pagination) {
    const query = { userId };
    if (filters.read !== undefined) query.read = filters.read === 'true';

    const [notifications, total] = await Promise.all([
      Notification.find(query).sort(pagination.sort).skip(pagination.skip).limit(pagination.limit),
      Notification.countDocuments(query)
    ]);

    return {
      notifications,
      total
    };
  }

  static markRead(userId, notificationId) {
    return Notification.findOneAndUpdate(
      { _id: notificationId, userId },
      { read: true },
      { new: true, runValidators: true }
    );
  }
}

module.exports = NotificationRepository;

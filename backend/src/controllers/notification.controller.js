const NotificationService = require('../services/notification.service');
const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess } = require('../helpers/response.helper');

exports.list = asyncHandler(async (req, res) => {
  const result = await NotificationService.list(req.user._id, req.query);
  sendSuccess(res, 200, 'Notifications fetched successfully', result.notifications, result.meta);
});

exports.markRead = asyncHandler(async (req, res) => {
  const notification = await NotificationService.markRead(req.user._id, req.params.id);
  sendSuccess(res, 200, 'Notification marked as read', notification);
});

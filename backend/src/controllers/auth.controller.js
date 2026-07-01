const AuthService = require('../services/auth.service');
const NotificationService = require('../services/notification.service');
const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess } = require('../helpers/response.helper');

const requestContext = (req) => ({
  userAgent: req.get('user-agent'),
  ipAddress: req.ip
});

exports.register = asyncHandler(async (req, res) => {
  const data = await AuthService.registerOwner(req.body, requestContext(req));
  sendSuccess(res, 201, 'Owner registered successfully', data);
});

exports.login = asyncHandler(async (req, res) => {
  const data = await AuthService.login(req.body, requestContext(req));
  sendSuccess(res, 200, 'Login successful', data);
});

exports.refresh = asyncHandler(async (req, res) => {
  const data = await AuthService.refresh(req.body.refreshToken, requestContext(req));
  sendSuccess(res, 200, 'Token refreshed successfully', data);
});

exports.logout = asyncHandler(async (req, res) => {
  await AuthService.logout(req.body.refreshToken);
  sendSuccess(res, 200, 'Logout successful');
});

exports.changePassword = asyncHandler(async (req, res) => {
  await AuthService.changePassword(req.user._id, req.body);
  sendSuccess(res, 200, 'Password changed successfully');
});

exports.registerFcmToken = asyncHandler(async (req, res) => {
  const user = await NotificationService.registerFcmToken(req.user._id, req.body.fcmToken);
  sendSuccess(res, 200, 'FCM token registered successfully', user);
});

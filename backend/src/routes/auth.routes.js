const express = require('express');
const authController = require('../controllers/auth.controller');
const authenticate = require('../middleware/auth.middleware');
const validate = require('../middleware/validate.middleware');
const { authRateLimiter } = require('../middleware/rateLimiter.middleware');
const {
  changePasswordRules,
  fcmTokenRules,
  loginRules,
  logoutRules,
  refreshRules,
  registerRules
} = require('../validators/auth.validator');

const router = express.Router();

router.post('/register', authRateLimiter, registerRules, validate, authController.register);
router.post('/login', authRateLimiter, loginRules, validate, authController.login);
router.post('/logout', logoutRules, validate, authController.logout);
router.post('/refresh', authRateLimiter, refreshRules, validate, authController.refresh);
router.post('/change-password', authenticate, changePasswordRules, validate, authController.changePassword);
router.post('/fcm-token', authenticate, fcmTokenRules, validate, authController.registerFcmToken);

module.exports = router;

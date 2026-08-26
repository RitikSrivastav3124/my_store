const { body } = require('express-validator');

const passwordRule = body('password')
  .isString()
  .isLength({ min: 8, max: 72 })
  .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z\d]).{8,72}$/)
  .withMessage('Password must be 8 to 72 characters and include uppercase, lowercase, number, and special character');

const registerRules = [
  body('name').isString().trim().isLength({ min: 2, max: 100 }).withMessage('Name is required'),
  body('phone')
    .isString()
    .trim()
    .matches(/^[0-9+\-\s()]{7,20}$/)
    .withMessage('A valid phone number is required'),
  body('email').optional({ nullable: true, checkFalsy: true }).isEmail().normalizeEmail(),
  passwordRule
];

const loginRules = [
  body('identifier').isString().trim().notEmpty().withMessage('Phone or email is required'),
  body('password').isString().notEmpty().withMessage('Password is required'),
  body('fcmToken').optional().isString().trim().isLength({ min: 10, max: 4096 })
];

const refreshRules = [
  body('refreshToken').isString().trim().notEmpty().withMessage('Refresh token is required')
];

const logoutRules = [
  body('refreshToken').optional().isString().trim().notEmpty().withMessage('Refresh token cannot be empty')
];

const changePasswordRules = [
  body('currentPassword').isString().notEmpty().withMessage('Current password is required'),
  body('newPassword')
    .isString()
    .isLength({ min: 8, max: 72 })
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z\d]).{8,72}$/)
    .withMessage('New password must be 8 to 72 characters and include uppercase, lowercase, number, and special character')
];

const fcmTokenRules = [
  body('fcmToken').isString().trim().isLength({ min: 10, max: 4096 }).withMessage('Valid FCM token is required')
];

module.exports = {
  registerRules,
  loginRules,
  refreshRules,
  logoutRules,
  changePasswordRules,
  fcmTokenRules
};

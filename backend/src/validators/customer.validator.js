const { body, param, query } = require('express-validator');
const { USER_STATUS } = require('../constants/statusCodes');
const { paginationRules } = require('./common.validator');

const customerIdRule = [param('id').isMongoId().withMessage('Valid customer id is required')];

const createCustomerRules = [
  body('name').isString().trim().isLength({ min: 2, max: 100 }).withMessage('Name is required'),
  body('phone')
    .isString()
    .trim()
    .matches(/^[0-9+\-\s()]{7,20}$/)
    .withMessage('A valid phone number is required'),
  body('email').optional({ nullable: true, checkFalsy: true }).isEmail().normalizeEmail(),
  body('password')
    .isString()
    .isLength({ min: 8, max: 72 })
    .withMessage('Password must be 8 to 72 characters long'),
  body('creditLimit').optional().isFloat({ min: 0 }).withMessage('Credit limit must be zero or greater'),
  body('openingDue').optional().isFloat({ min: 0 }).withMessage('Opening due must be zero or greater'),
  body('notes').optional({ nullable: true }).isString().trim().isLength({ max: 1000 })
];

const updateCustomerRules = [
  ...customerIdRule,
  body('name').optional().isString().trim().isLength({ min: 2, max: 100 }),
  body('phone')
    .optional()
    .isString()
    .trim()
    .matches(/^[0-9+\-\s()]{7,20}$/)
    .withMessage('A valid phone number is required'),
  body('email').optional({ nullable: true, checkFalsy: true }).isEmail().normalizeEmail(),
  body('creditLimit').optional().isFloat({ min: 0 }).withMessage('Credit limit must be zero or greater'),
  body('notes').optional({ nullable: true }).isString().trim().isLength({ max: 1000 })
];

const listCustomerRules = [
  ...paginationRules,
  query('search').optional().isString().trim().isLength({ max: 100 }),
  query('status').optional().isIn(Object.values(USER_STATUS)),
  query('minDue').optional().isFloat({ min: 0 }),
  query('maxDue').optional().isFloat({ min: 0 })
];

module.exports = {
  customerIdRule,
  createCustomerRules,
  updateCustomerRules,
  listCustomerRules
};

const { body, query } = require('express-validator');
const { PAYMENT_METHODS, TRANSACTION_TYPES } = require('../constants/transactionTypes');
const { paginationRules } = require('./common.validator');

const ledgerMutationRules = [
  body('amount').isFloat({ min: 0.01, max: 100000000 }).withMessage('Amount must be between 0.01 and 100000000'),
  body('description').optional({ nullable: true }).isString().trim().isLength({ max: 500 }),
  body('paymentMethod').optional().isIn(Object.values(PAYMENT_METHODS)).withMessage('Invalid payment method'),
  body('requestId').optional().isString().trim().isLength({ min: 8, max: 120 }).withMessage('Request id must be 8 to 120 characters')
];

const transactionHistoryRules = [
  ...paginationRules,
  query('type').optional().isIn(Object.values(TRANSACTION_TYPES)).withMessage('Invalid transaction type')
];

module.exports = {
  ledgerMutationRules,
  transactionHistoryRules
};

const { body, query } = require('express-validator');
const { PAYMENT_METHODS, TRANSACTION_TYPES } = require('../constants/transactionTypes');
const { paginationRules } = require('./common.validator');

const ledgerMutationRules = [
  body('amount').isFloat({ min: 0.01 }).withMessage('Amount must be greater than zero'),
  body('description').optional({ nullable: true }).isString().trim().isLength({ max: 500 }),
  body('paymentMethod').optional().isIn(Object.values(PAYMENT_METHODS)).withMessage('Invalid payment method')
];

const transactionHistoryRules = [
  ...paginationRules,
  query('type').optional().isIn(Object.values(TRANSACTION_TYPES)).withMessage('Invalid transaction type')
];

module.exports = {
  ledgerMutationRules,
  transactionHistoryRules
};

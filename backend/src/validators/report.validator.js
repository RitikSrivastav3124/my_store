const { query } = require('express-validator');
const { TRANSACTION_TYPES } = require('../constants/transactionTypes');
const { paginationRules } = require('./common.validator');

const dateRangeRules = [
  query('startDate').optional().isISO8601().withMessage('Start date must be ISO-8601'),
  query('endDate').optional().isISO8601().withMessage('End date must be ISO-8601')
];

const outstandingRules = [
  ...paginationRules,
  query('search').optional().isString().trim().isLength({ max: 100 })
];

const transactionReportRules = [
  ...paginationRules,
  ...dateRangeRules,
  query('type').optional().isIn(Object.values(TRANSACTION_TYPES)).withMessage('Invalid transaction type')
];

module.exports = {
  dateRangeRules,
  outstandingRules,
  transactionReportRules
};

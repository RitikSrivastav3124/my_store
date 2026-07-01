const { query } = require('express-validator');

const paginationRules = [
  query('page').optional().isInt({ min: 1 }).withMessage('Page must be a positive integer'),
  query('limit').optional().isInt({ min: 1, max: 100 }).withMessage('Limit must be between 1 and 100'),
  query('sortOrder').optional().isIn(['asc', 'desc']).withMessage('Sort order must be asc or desc'),
  query('sortBy').optional().isString().trim().isLength({ min: 1, max: 50 })
];

module.exports = {
  paginationRules
};

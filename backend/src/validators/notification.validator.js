const { param, query } = require('express-validator');
const { paginationRules } = require('./common.validator');

const listNotificationRules = [
  ...paginationRules,
  query('read').optional().isIn(['true', 'false']).withMessage('Read filter must be true or false')
];

const notificationIdRule = [param('id').isMongoId().withMessage('Valid notification id is required')];

module.exports = {
  listNotificationRules,
  notificationIdRule
};

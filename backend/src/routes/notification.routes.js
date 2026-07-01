const express = require('express');
const notificationController = require('../controllers/notification.controller');
const authenticate = require('../middleware/auth.middleware');
const validate = require('../middleware/validate.middleware');
const {
  listNotificationRules,
  notificationIdRule
} = require('../validators/notification.validator');

const router = express.Router();

router.use(authenticate);

router.get('/', listNotificationRules, validate, notificationController.list);
router.put('/:id/read', notificationIdRule, validate, notificationController.markRead);

module.exports = router;

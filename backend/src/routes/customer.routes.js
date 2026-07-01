const express = require('express');
const customerController = require('../controllers/customer.controller');
const authenticate = require('../middleware/auth.middleware');
const authorize = require('../middleware/role.middleware');
const validate = require('../middleware/validate.middleware');
const ROLES = require('../constants/roles');
const { transactionHistoryRules } = require('../validators/ledger.validator');

const router = express.Router();

router.use(authenticate, authorize(ROLES.CUSTOMER));

router.get('/profile', customerController.profile);
router.get('/due', customerController.due);
router.get('/history', transactionHistoryRules, validate, customerController.history);

module.exports = router;

const express = require('express');
const reportController = require('../controllers/report.controller');
const authenticate = require('../middleware/auth.middleware');
const authorize = require('../middleware/role.middleware');
const validate = require('../middleware/validate.middleware');
const ROLES = require('../constants/roles');
const {
  dateRangeRules,
  outstandingRules,
  transactionReportRules
} = require('../validators/report.validator');

const router = express.Router();

router.use(authenticate, authorize(ROLES.OWNER));

router.get('/dashboard', reportController.dashboard);
router.get('/monthly', dateRangeRules, validate, reportController.monthly);
router.get('/outstanding', outstandingRules, validate, reportController.outstanding);
router.get('/transactions', transactionReportRules, validate, reportController.transactions);
router.get('/export/csv', outstandingRules, validate, reportController.exportOutstandingCsv);
router.get('/export/excel', outstandingRules, validate, reportController.exportOutstandingExcel);
router.get('/export/pdf', outstandingRules, validate, reportController.exportOutstandingPdf);

module.exports = router;

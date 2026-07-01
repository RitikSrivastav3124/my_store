const express = require('express');
const ownerCustomerController = require('../controllers/ownerCustomer.controller');
const authenticate = require('../middleware/auth.middleware');
const authorize = require('../middleware/role.middleware');
const validate = require('../middleware/validate.middleware');
const ROLES = require('../constants/roles');
const {
  createCustomerRules,
  customerIdRule,
  listCustomerRules,
  updateCustomerRules
} = require('../validators/customer.validator');
const { ledgerMutationRules, transactionHistoryRules } = require('../validators/ledger.validator');

const router = express.Router();

router.use(authenticate, authorize(ROLES.OWNER));

router.get('/', listCustomerRules, validate, ownerCustomerController.list);
router.post('/', createCustomerRules, validate, ownerCustomerController.create);
router.get('/:id', customerIdRule, validate, ownerCustomerController.get);
router.put('/:id', updateCustomerRules, validate, ownerCustomerController.update);
router.delete('/:id', customerIdRule, validate, ownerCustomerController.remove);
router.post('/:id/suspend', customerIdRule, validate, ownerCustomerController.suspend);
router.post('/:id/addDue', [...customerIdRule, ...ledgerMutationRules], validate, ownerCustomerController.addDue);
router.post('/:id/payment', [...customerIdRule, ...ledgerMutationRules], validate, ownerCustomerController.payment);
router.post('/:id/reduceDue', [...customerIdRule, ...ledgerMutationRules], validate, ownerCustomerController.reduceDue);
router.get('/:id/history', [...customerIdRule, ...transactionHistoryRules], validate, ownerCustomerController.history);

module.exports = router;

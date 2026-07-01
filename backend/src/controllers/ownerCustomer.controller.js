const CustomerService = require('../services/customer.service');
const LedgerService = require('../services/ledger.service');
const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess } = require('../helpers/response.helper');

exports.list = asyncHandler(async (req, res) => {
  const result = await CustomerService.list(req.user._id, req.query);
  sendSuccess(res, 200, 'Customers fetched successfully', result.customers, result.meta);
});

exports.create = asyncHandler(async (req, res) => {
  const customer = await CustomerService.create(req.user._id, req.body);
  sendSuccess(res, 201, 'Customer created successfully', customer);
});

exports.get = asyncHandler(async (req, res) => {
  const customer = await CustomerService.getOwned(req.user._id, req.params.id);
  sendSuccess(res, 200, 'Customer fetched successfully', customer);
});

exports.update = asyncHandler(async (req, res) => {
  const customer = await CustomerService.update(req.user._id, req.params.id, req.body);
  sendSuccess(res, 200, 'Customer updated successfully', customer);
});

exports.remove = asyncHandler(async (req, res) => {
  await CustomerService.softDelete(req.user._id, req.params.id);
  sendSuccess(res, 200, 'Customer deleted successfully');
});

exports.suspend = asyncHandler(async (req, res) => {
  const customer = await CustomerService.suspend(req.user._id, req.params.id);
  sendSuccess(res, 200, 'Customer status updated successfully', customer);
});

exports.addDue = asyncHandler(async (req, res) => {
  const result = await LedgerService.addDue(req.user._id, req.params.id, req.body);
  sendSuccess(res, 201, 'Due amount added successfully', result);
});

exports.payment = asyncHandler(async (req, res) => {
  const result = await LedgerService.recordPayment(req.user._id, req.params.id, req.body);
  sendSuccess(res, 201, 'Payment recorded successfully', result);
});

exports.reduceDue = asyncHandler(async (req, res) => {
  const result = await LedgerService.reduceDue(req.user._id, req.params.id, req.body);
  sendSuccess(res, 201, 'Due amount reduced successfully', result);
});

exports.history = asyncHandler(async (req, res) => {
  const result = await CustomerService.historyForOwner(req.user._id, req.params.id, req.query);
  sendSuccess(res, 200, 'Customer transaction history fetched successfully', result.transactions, result.meta);
});

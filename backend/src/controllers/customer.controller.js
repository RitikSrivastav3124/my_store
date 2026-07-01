const CustomerService = require('../services/customer.service');
const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess } = require('../helpers/response.helper');

exports.profile = asyncHandler(async (req, res) => {
  const customer = await CustomerService.profile(req.user._id);
  sendSuccess(res, 200, 'Profile fetched successfully', customer);
});

exports.due = asyncHandler(async (req, res) => {
  const customer = await CustomerService.profile(req.user._id);
  sendSuccess(res, 200, 'Due fetched successfully', {
    currentDue: customer.currentDue,
    creditLimit: customer.creditLimit
  });
});

exports.history = asyncHandler(async (req, res) => {
  const result = await CustomerService.historyForCustomer(req.user._id, req.query);
  sendSuccess(res, 200, 'Transaction history fetched successfully', result.transactions, result.meta);
});

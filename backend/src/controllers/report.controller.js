const ReportService = require('../services/report.service');
const ExportService = require('../services/export.service');
const asyncHandler = require('../utils/asyncHandler');
const { sendSuccess } = require('../helpers/response.helper');

exports.dashboard = asyncHandler(async (req, res) => {
  const dashboard = await ReportService.dashboard(req.user._id);
  sendSuccess(res, 200, 'Dashboard analytics fetched successfully', dashboard);
});

exports.monthly = asyncHandler(async (req, res) => {
  const report = await ReportService.monthly(req.user._id, req.query);
  sendSuccess(res, 200, 'Monthly report fetched successfully', report);
});

exports.outstanding = asyncHandler(async (req, res) => {
  const result = await ReportService.outstanding(req.user._id, req.query);
  sendSuccess(res, 200, 'Outstanding report fetched successfully', result.customers, result.meta);
});

exports.transactions = asyncHandler(async (req, res) => {
  const result = await ReportService.transactions(req.user._id, req.query);
  sendSuccess(res, 200, 'Transactions fetched successfully', result.transactions, result.meta);
});

exports.exportOutstandingCsv = asyncHandler(async (req, res) => {
  res.header('Content-Type', 'text/csv');
  res.attachment('outstanding-report.csv');
  await ExportService.outstandingCsv(req.user._id, req.query, res);
});

exports.exportOutstandingExcel = asyncHandler(async (req, res) => {
  res.header('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  res.attachment('outstanding-report.xlsx');
  await ExportService.outstandingExcel(req.user._id, req.query, res);
});

exports.exportOutstandingPdf = asyncHandler(async (req, res) => {
  res.header('Content-Type', 'application/pdf');
  res.attachment('outstanding-report.pdf');
  await ExportService.outstandingPdf(req.user._id, req.query, res);
});

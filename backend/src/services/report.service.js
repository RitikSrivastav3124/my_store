const mongoose = require('mongoose');
const Customer = require('../models/customer.model');
const Transaction = require('../models/transaction.model');
const { USER_STATUS } = require('../constants/statusCodes');
const { TRANSACTION_TYPES } = require('../constants/transactionTypes');
const TransactionRepository = require('../repositories/transaction.repository');
const { buildMeta, buildPagination } = require('../helpers/pagination.helper');
const { escapeRegex } = require('../utils/regex');

const startOfDay = (date = new Date()) => new Date(date.getFullYear(), date.getMonth(), date.getDate());
const endOfDay = (date = new Date()) =>
  new Date(date.getFullYear(), date.getMonth(), date.getDate(), 23, 59, 59, 999);
const startOfMonth = (date = new Date()) => new Date(date.getFullYear(), date.getMonth(), 1);
const endOfMonth = (date = new Date()) =>
  new Date(date.getFullYear(), date.getMonth() + 1, 0, 23, 59, 59, 999);

const OUTSTANDING_EXPORT_LIMIT = 10000;
const OUTSTANDING_EXPORT_BATCH_SIZE = 500;

const ownerObjectId = (ownerId) => new mongoose.Types.ObjectId(ownerId);

const buildOutstandingPipeline = (ownerId, query) => {
  const match = {
    ownerId: ownerObjectId(ownerId),
    currentDue: { $gt: 0 }
  };

  const pipeline = [
    { $match: match },
    {
      $lookup: {
        from: 'users',
        localField: 'userId',
        foreignField: '_id',
        as: 'user'
      }
    },
    { $unwind: '$user' },
    { $match: { 'user.status': { $ne: USER_STATUS.DELETED } } }
  ];

  if (query.search) {
    const regex = new RegExp(escapeRegex(query.search), 'i');
    pipeline.push({
      $match: {
        $or: [{ 'user.name': regex }, { 'user.phone': regex }, { 'user.email': regex }]
      }
    });
  }

  return pipeline;
};

const outstandingProjection = {
  _id: 1,
  name: '$user.name',
  phone: '$user.phone',
  email: '$user.email',
  status: '$user.status',
  currentDue: 1,
  creditLimit: 1,
  updatedAt: 1
};

class ReportService {
  static async dashboard(ownerId) {
    const owner = ownerObjectId(ownerId);
    const todayStart = startOfDay();
    const todayEnd = endOfDay();
    const monthStart = startOfMonth();
    const monthEnd = endOfMonth();

    const [customerStats, activeCustomers, todaysCollection, monthlyCollection] = await Promise.all([
      Customer.aggregate([
        { $match: { ownerId: owner } },
        {
          $lookup: {
            from: 'users',
            localField: 'userId',
            foreignField: '_id',
            as: 'user'
          }
        },
        { $unwind: '$user' },
        { $match: { 'user.status': { $ne: USER_STATUS.DELETED } } },
        {
          $group: {
            _id: null,
            totalCustomers: { $sum: 1 },
            totalOutstanding: { $sum: '$currentDue' }
          }
        }
      ]),
      Customer.aggregate([
        { $match: { ownerId: owner } },
        {
          $lookup: {
            from: 'users',
            localField: 'userId',
            foreignField: '_id',
            as: 'user'
          }
        },
        { $unwind: '$user' },
        { $match: { 'user.status': USER_STATUS.ACTIVE } },
        { $count: 'count' }
      ]),
      TransactionRepository.sum({
        ownerId: owner,
        type: TRANSACTION_TYPES.PAYMENT_RECEIVED,
        createdAt: { $gte: todayStart, $lte: todayEnd }
      }),
      TransactionRepository.sum({
        ownerId: owner,
        type: TRANSACTION_TYPES.PAYMENT_RECEIVED,
        createdAt: { $gte: monthStart, $lte: monthEnd }
      })
    ]);

    return {
      totalCustomers: customerStats[0]?.totalCustomers || 0,
      totalOutstanding: customerStats[0]?.totalOutstanding || 0,
      todaysCollection,
      monthlyCollection,
      activeCustomers: activeCustomers[0]?.count || 0
    };
  }

  static async monthly(ownerId, query) {
    const owner = ownerObjectId(ownerId);
    const now = new Date();
    const start = query.startDate ? new Date(query.startDate) : new Date(now.getFullYear(), 0, 1);
    const end = query.endDate ? new Date(query.endDate) : endOfMonth(now);
    return TransactionRepository.monthlyCollection(owner, start, end);
  }

  static async outstanding(ownerId, query) {
    const pagination = buildPagination(query);
    const pipeline = buildOutstandingPipeline(ownerId, query);

    const [countRows, customers] = await Promise.all([
      Customer.aggregate([...pipeline, { $count: 'total' }]),
      Customer.aggregate([
        ...pipeline,
        { $sort: pagination.sort },
        { $skip: pagination.skip },
        { $limit: pagination.limit },
        { $project: outstandingProjection }
      ])
    ]);

    return {
      customers,
      meta: buildMeta({ ...pagination, total: countRows[0]?.total || 0 })
    };
  }

static async *outstandingExportBatches(ownerId, query, batchSize = OUTSTANDING_EXPORT_BATCH_SIZE) {
    const pipeline = buildOutstandingPipeline(ownerId, query);
    const sortBy = query.sortBy || 'createdAt';
    const sortOrder = query.sortOrder === 'asc' ? 1 : -1;
    const sort = { [sortBy]: sortOrder };

    // A tie-breaker makes offset batches deterministic when multiple customers share a sort value.
    if (sortBy !== '_id') sort._id = sortOrder;

    let skip = 0;
    const exportLimit = OUTSTANDING_EXPORT_LIMIT;

    while (skip < exportLimit) {
      const customers = await Customer.aggregate([
        ...pipeline,
        { $sort: sort },
        { $skip: skip },
        { $limit: Math.min(batchSize, exportLimit - skip) },
        { $project: outstandingProjection }
      ]);

      if (!customers.length) return;

      yield customers;
      skip += customers.length;

      if (customers.length < batchSize) return;
    }
  }

  static async transactions(ownerId, query) {
    const pagination = buildPagination(query);
    const filter = {
      ownerId: ownerObjectId(ownerId)
    };

    if (query.type) filter.type = query.type;
    if (query.startDate || query.endDate) {
      filter.createdAt = {};
      if (query.startDate) filter.createdAt.$gte = new Date(query.startDate);
      if (query.endDate) filter.createdAt.$lte = new Date(query.endDate);
    }

    const { transactions, total } = await TransactionRepository.list(filter, pagination);

    return {
      transactions,
      meta: buildMeta({ ...pagination, total })
    };
  }
}

module.exports = ReportService;

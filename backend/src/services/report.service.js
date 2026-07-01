const mongoose = require('mongoose');
const Customer = require('../models/customer.model');
const Transaction = require('../models/transaction.model');
const { USER_STATUS } = require('../constants/statusCodes');
const { TRANSACTION_TYPES } = require('../constants/transactionTypes');
const TransactionRepository = require('../repositories/transaction.repository');
const { buildMeta, buildPagination } = require('../helpers/pagination.helper');

const startOfDay = (date = new Date()) => new Date(date.getFullYear(), date.getMonth(), date.getDate());
const endOfDay = (date = new Date()) =>
  new Date(date.getFullYear(), date.getMonth(), date.getDate(), 23, 59, 59, 999);
const startOfMonth = (date = new Date()) => new Date(date.getFullYear(), date.getMonth(), 1);
const endOfMonth = (date = new Date()) =>
  new Date(date.getFullYear(), date.getMonth() + 1, 0, 23, 59, 59, 999);

const ownerObjectId = (ownerId) => new mongoose.Types.ObjectId(ownerId);

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
    const owner = ownerObjectId(ownerId);
    const pagination = buildPagination(query);

    const match = {
      ownerId: owner,
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
      const regex = new RegExp(query.search, 'i');
      pipeline.push({
        $match: {
          $or: [{ 'user.name': regex }, { 'user.phone': regex }, { 'user.email': regex }]
        }
      });
    }

    const [countRows, customers] = await Promise.all([
      Customer.aggregate([...pipeline, { $count: 'total' }]),
      Customer.aggregate([
        ...pipeline,
        { $sort: pagination.sort },
        { $skip: pagination.skip },
        { $limit: pagination.limit },
        {
          $project: {
            _id: 1,
            name: '$user.name',
            phone: '$user.phone',
            email: '$user.email',
            status: '$user.status',
            currentDue: 1,
            creditLimit: 1,
            updatedAt: 1
          }
        }
      ])
    ]);

    return {
      customers,
      meta: buildMeta({ ...pagination, total: countRows[0]?.total || 0 })
    };
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

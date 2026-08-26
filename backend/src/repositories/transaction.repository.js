const Transaction = require('../models/transaction.model');

class TransactionRepository {
  static create(data, options = {}) {
    return Transaction.create([data], options).then(([transaction]) => transaction);
  }

  static findByRequestId(ownerId, requestId, options = {}) {
    if (!requestId) return null;
    return Transaction.findOne({ ownerId, requestId }, null, options);
  }

  static async list(filter, pagination) {
    const [transactions, total] = await Promise.all([
      Transaction.find(filter)
        .populate({
          path: 'customerId',
          populate: {
            path: 'userId',
            select: 'name phone email status'
          }
        })
        .sort(pagination.sort)
        .skip(pagination.skip)
        .limit(pagination.limit),
      Transaction.countDocuments(filter)
    ]);

    return {
      transactions,
      total
    };
  }

  static sum(filter) {
    return Transaction.aggregate([
      { $match: filter },
      {
        $group: {
          _id: null,
          total: { $sum: '$amount' }
        }
      }
    ]).then((rows) => rows[0]?.total || 0);
  }

  static monthlyCollection(ownerId, start, end) {
    return Transaction.aggregate([
      {
        $match: {
          ownerId,
          type: 'payment_received',
          createdAt: {
            $gte: start,
            $lte: end
          }
        }
      },
      {
        $group: {
          _id: {
            year: { $year: '$createdAt' },
            month: { $month: '$createdAt' }
          },
          total: { $sum: '$amount' },
          count: { $sum: 1 }
        }
      },
      {
        $sort: {
          '_id.year': 1,
          '_id.month': 1
        }
      }
    ]);
  }
}

module.exports = TransactionRepository;

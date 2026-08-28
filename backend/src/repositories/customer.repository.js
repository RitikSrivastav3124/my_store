const Customer = require('../models/customer.model');
const { USER_STATUS } = require('../constants/statusCodes');
const { escapeRegex } = require('../utils/regex');

class CustomerRepository {
  static create(data, options = {}) {
    return Customer.create([data], options).then(([customer]) => customer);
  }

  static findById(id, options = {}) {
    return Customer.findById(id, null, options).populate('userId', 'name phone email role status');
  }

  static findOwnedById(ownerId, customerId, options = {}) {
    return Customer.findOne({ _id: customerId, ownerId }, null, options).populate(
      'userId',
      'name phone email role status'
    );
  }

  static findByUserId(userId, options = {}) {
    return Customer.findOne({ userId }, null, options).populate('ownerId', 'name phone email');
  }

  static updateById(id, data, options = {}) {
    return Customer.findByIdAndUpdate(id, data, {
      new: true,
      runValidators: true,
      ...options
    }).populate('userId', 'name phone email role status');
  }

  static adjustDue(ownerId, customerId, amount, isIncrease, options = {}) {
    const filter = { _id: customerId, ownerId };
    if (!isIncrease) filter.currentDue = { $gte: amount };

    return Customer.findOneAndUpdate(
      filter,
      { $inc: { currentDue: isIncrease ? amount : -amount } },
      {
        new: true,
        runValidators: true,
        ...options
      }
    ).populate('userId', 'name phone email role status');
  }

  static async listForOwner(ownerId, filters, pagination) {
    const match = {
      ownerId
    };

    if (filters.minDue !== undefined || filters.maxDue !== undefined) {
      match.currentDue = {};
      if (filters.minDue !== undefined) match.currentDue.$gte = Number(filters.minDue);
      if (filters.maxDue !== undefined) match.currentDue.$lte = Number(filters.maxDue);
    }

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
      {
        $match: {
          'user.status': filters.status || { $ne: USER_STATUS.DELETED }
        }
      }
    ];

    if (filters.search) {
      const regex = new RegExp(escapeRegex(filters.search), 'i');
      pipeline.push({
        $match: {
          $or: [{ 'user.name': regex }, { 'user.phone': regex }, { 'user.email': regex }]
        }
      });
    }

    const countPipeline = [...pipeline, { $count: 'total' }];
    const dataPipeline = [
      ...pipeline,
      { $sort: pagination.sort },
      { $skip: pagination.skip },
      { $limit: pagination.limit },
      {
        $project: {
          ownerId: 1,
          userId: '$user',
          creditLimit: 1,
          notes: 1,
          currentDue: 1,
          createdAt: 1,
          updatedAt: 1
        }
      }
    ];

    const [countResult, customers] = await Promise.all([
      Customer.aggregate(countPipeline),
      Customer.aggregate(dataPipeline)
    ]);

    return {
      customers,
      total: countResult[0]?.total || 0
    };
  }
}

module.exports = CustomerRepository;

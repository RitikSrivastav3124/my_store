const mongoose = require('mongoose');
const ROLES = require('../constants/roles');
const { USER_STATUS } = require('../constants/statusCodes');
const UserRepository = require('../repositories/user.repository');
const CustomerRepository = require('../repositories/customer.repository');
const TransactionRepository = require('../repositories/transaction.repository');
const AuditService = require('./audit.service');
const NotificationService = require('./notification.service');
const { buildMeta, buildPagination } = require('../helpers/pagination.helper');
const { hashPassword } = require('../utils/password');
const AppError = require('../utils/appError');

const runWithOptionalTransaction = async (work) => {
  const session = await mongoose.startSession();
  try {
    let result;
    await session.withTransaction(async () => {
      result = await work(session);
    });
    return result;
  } catch (error) {
    if (/Transaction numbers are only allowed|replica set member/i.test(error.message)) {
      return work(undefined);
    }
    throw error;
  } finally {
    await session.endSession();
  }
};

class CustomerService {
  static async create(ownerId, payload) {
    const duplicate = await UserRepository.findDuplicate({
      email: payload.email,
      phone: payload.phone
    });

    if (duplicate) throw new AppError('A user with this phone or email already exists', 409);

    return runWithOptionalTransaction(async (session) => {
      const user = await UserRepository.create(
        {
          name: payload.name,
          phone: payload.phone,
          email: payload.email,
          password: await hashPassword(payload.password),
          role: ROLES.CUSTOMER,
          status: USER_STATUS.ACTIVE
        },
        { session }
      );

      const customer = await CustomerRepository.create(
        {
          ownerId,
          userId: user._id,
          creditLimit: payload.creditLimit || 0,
          notes: payload.notes || '',
          currentDue: payload.openingDue || 0
        },
        { session }
      );

      if (payload.openingDue > 0) {
        await TransactionRepository.create(
          {
            customerId: customer._id,
            ownerId,
            type: 'due_added',
            amount: payload.openingDue,
            description: 'Opening due balance',
            paymentMethod: 'other',
            balanceAfter: payload.openingDue
          },
          { session }
        );
      }

      await AuditService.record(
        {
          action: 'customer.created',
          performedBy: ownerId,
          targetCustomer: customer._id,
          newValue: {
            customer,
            user
          }
        },
        { session }
      );

      return CustomerRepository.findOwnedById(ownerId, customer._id, { session });
    });
  }

  static async list(ownerId, query) {
    const pagination = buildPagination(query);
    const filters = {
      search: query.search,
      status: query.status,
      minDue: query.minDue,
      maxDue: query.maxDue
    };

    const { customers, total } = await CustomerRepository.listForOwner(ownerId, filters, pagination);

    return {
      customers,
      meta: buildMeta({ ...pagination, total })
    };
  }

  static async getOwned(ownerId, customerId) {
    const customer = await CustomerRepository.findOwnedById(ownerId, customerId);
    if (!customer || customer.userId.status === USER_STATUS.DELETED) {
      throw new AppError('Customer not found', 404);
    }
    return customer;
  }

  static async update(ownerId, customerId, payload) {
    const existing = await this.getOwned(ownerId, customerId);

    const duplicate = await UserRepository.findDuplicate(
      {
        email: payload.email,
        phone: payload.phone
      },
      existing.userId._id
    );

    if (duplicate) throw new AppError('A user with this phone or email already exists', 409);

    return runWithOptionalTransaction(async (session) => {
      const userUpdate = {};
      ['name', 'phone', 'email'].forEach((field) => {
        if (payload[field] !== undefined) userUpdate[field] = payload[field];
      });

      if (Object.keys(userUpdate).length) {
        await UserRepository.updateById(existing.userId._id, userUpdate, { session });
      }

      const customerUpdate = {};
      ['creditLimit', 'notes'].forEach((field) => {
        if (payload[field] !== undefined) customerUpdate[field] = payload[field];
      });

      const updated = Object.keys(customerUpdate).length
        ? await CustomerRepository.updateById(customerId, customerUpdate, { session })
        : await CustomerRepository.findOwnedById(ownerId, customerId, { session });

      await AuditService.record(
        {
          action: 'customer.updated',
          performedBy: ownerId,
          targetCustomer: customerId,
          oldValue: existing,
          newValue: updated
        },
        { session }
      );

      return CustomerRepository.findOwnedById(ownerId, customerId, { session });
    });
  }

  static async softDelete(ownerId, customerId) {
    const existing = await this.getOwned(ownerId, customerId);

    await UserRepository.updateById(existing.userId._id, {
      status: USER_STATUS.DELETED
    });

    await AuditService.record({
      action: 'customer.deleted',
      performedBy: ownerId,
      targetCustomer: customerId,
      oldValue: existing,
      newValue: {
        status: USER_STATUS.DELETED
      }
    });
  }

  static async suspend(ownerId, customerId) {
    const existing = await this.getOwned(ownerId, customerId);
    const nextStatus =
      existing.userId.status === USER_STATUS.SUSPENDED ? USER_STATUS.ACTIVE : USER_STATUS.SUSPENDED;

    const updatedUser = await UserRepository.updateById(existing.userId._id, {
      status: nextStatus
    });

    await AuditService.record({
      action: nextStatus === USER_STATUS.SUSPENDED ? 'customer.suspended' : 'customer.activated',
      performedBy: ownerId,
      targetCustomer: customerId,
      oldValue: {
        status: existing.userId.status
      },
      newValue: {
        status: updatedUser.status
      }
    });

    return this.getOwned(ownerId, customerId);
  }

  static async profile(userId) {
    const customer = await CustomerRepository.findByUserId(userId);
    if (!customer) throw new AppError('Customer profile not found', 404);
    return customer;
  }

  static async historyForOwner(ownerId, customerId, query) {
    await this.getOwned(ownerId, customerId);
    const pagination = buildPagination(query);
    const filter = { ownerId, customerId };
    if (query.type) filter.type = query.type;

    const { transactions, total } = await TransactionRepository.list(filter, pagination);
    return {
      transactions,
      meta: buildMeta({ ...pagination, total })
    };
  }

  static async historyForCustomer(userId, query) {
    const customer = await this.profile(userId);
    const pagination = buildPagination(query);
    const filter = { customerId: customer._id };
    if (query.type) filter.type = query.type;

    const { transactions, total } = await TransactionRepository.list(filter, pagination);
    return {
      transactions,
      meta: buildMeta({ ...pagination, total })
    };
  }
}

module.exports = CustomerService;

const mongoose = require('mongoose');
const CustomerRepository = require('../repositories/customer.repository');
const TransactionRepository = require('../repositories/transaction.repository');
const AuditService = require('./audit.service');
const NotificationService = require('./notification.service');
const { TRANSACTION_TYPES } = require('../constants/transactionTypes');
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

class LedgerService {
  static async mutateDue(ownerId, customerId, payload, type, context = {}) {
    return runWithOptionalTransaction(async (session) => {
      const customer = await CustomerRepository.findOwnedById(ownerId, customerId, { session });
      if (!customer) throw new AppError('Customer not found', 404);

      const amount = Number(payload.amount);
      const requestId = payload.requestId || context.requestId || null;
      const existingTransaction = requestId
        ? await TransactionRepository.findByRequestId(ownerId, requestId, { session })
        : null;
      if (existingTransaction) {
        return {
          customer,
          transaction: existingTransaction,
          idempotentReplay: true
        };
      }

      const isIncrease = type === TRANSACTION_TYPES.DUE_ADDED;
      const nextDue = isIncrease ? customer.currentDue + amount : customer.currentDue - amount;

      if (nextDue < 0) throw new AppError('Payment or reduction cannot exceed current due', 400);

      const updatedCustomer = await CustomerRepository.updateById(
        customerId,
        {
          currentDue: nextDue
        },
        { session }
      );

      const transaction = await TransactionRepository.create(
        {
          customerId,
          ownerId,
          type,
          amount,
          description: payload.description || '',
          paymentMethod: payload.paymentMethod || 'cash',
          balanceAfter: nextDue,
          requestId
        },
        { session }
      );

      await AuditService.record(
        {
          action: `ledger.${type}`,
          performedBy: ownerId,
          targetCustomer: customerId,
          oldValue: {
            currentDue: customer.currentDue
          },
          newValue: {
            currentDue: nextDue,
            transactionId: transaction._id
          }
        },
        {
          session,
          actorRole: 'owner',
          ipAddress: context.ipAddress,
          userAgent: context.userAgent,
          requestId: requestId || ''
        }
      );

      const title = isIncrease ? 'Due amount updated' : 'Payment recorded';
      const body = isIncrease
        ? `Your due increased by ${amount}. Current due is ${nextDue}.`
        : `A payment/reduction of ${amount} was recorded. Current due is ${nextDue}.`;

      await NotificationService.createAndPush(
        {
          userId: customer.userId._id,
          title,
          body,
          data: {
            customerId,
            transactionId: transaction._id,
            type
          }
        },
        { session }
      );

      return {
        customer: updatedCustomer,
        transaction
      };
    });
  }

  static addDue(ownerId, customerId, payload, context = {}) {
    return this.mutateDue(ownerId, customerId, payload, TRANSACTION_TYPES.DUE_ADDED, context);
  }

  static recordPayment(ownerId, customerId, payload, context = {}) {
    return this.mutateDue(ownerId, customerId, payload, TRANSACTION_TYPES.PAYMENT_RECEIVED, context);
  }

  static reduceDue(ownerId, customerId, payload, context = {}) {
    return this.mutateDue(ownerId, customerId, payload, TRANSACTION_TYPES.DUE_REDUCED, context);
  }
}

module.exports = LedgerService;

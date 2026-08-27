jest.mock('mongoose', () => ({
  startSession: jest.fn()
}));
jest.mock('../src/repositories/customer.repository', () => ({
  findOwnedById: jest.fn(),
  adjustDue: jest.fn()
}));
jest.mock('../src/repositories/transaction.repository', () => ({
  create: jest.fn(),
  findByRequestId: jest.fn()
}));
jest.mock('../src/services/audit.service', () => ({
  record: jest.fn()
}));
jest.mock('../src/services/notification.service', () => ({
  create: jest.fn(),
  push: jest.fn()
}));

const mongoose = require('mongoose');
const CustomerRepository = require('../src/repositories/customer.repository');
const TransactionRepository = require('../src/repositories/transaction.repository');
const AuditService = require('../src/services/audit.service');
const NotificationService = require('../src/services/notification.service');
const LedgerService = require('../src/services/ledger.service');

const ownerId = 'owner-id';
const customerId = 'customer-id';

const setSuccessfulLedgerMocks = () => {
  CustomerRepository.findOwnedById.mockResolvedValue({
    currentDue: 100,
    userId: { _id: 'user-id' }
  });
  CustomerRepository.adjustDue.mockResolvedValue({ currentDue: 125 });
  TransactionRepository.findByRequestId.mockResolvedValue(null);
  TransactionRepository.create.mockResolvedValue({ _id: 'transaction-id' });
  AuditService.record.mockResolvedValue({});
  NotificationService.create.mockResolvedValue({ _id: 'notification-id' });
  NotificationService.push.mockResolvedValue();
};

describe('Ledger notification delivery', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    setSuccessfulLedgerMocks();
  });

  it('creates the notification in the transaction and pushes only after commit', async () => {
    const events = [];
    const session = {
      withTransaction: jest.fn(async (work) => {
        await work(session);
        events.push('committed');
      }),
      endSession: jest.fn()
    };
    mongoose.startSession.mockResolvedValue(session);
    NotificationService.create.mockImplementation(async () => {
      events.push('notification-created');
    });
    NotificationService.push.mockImplementation(async () => {
      events.push('pushed');
    });

    const result = await LedgerService.addDue(ownerId, customerId, { amount: 25 });

    expect(events).toEqual(['notification-created', 'committed', 'pushed']);
    expect(NotificationService.create).toHaveBeenCalledWith(
      expect.objectContaining({ userId: 'user-id' }),
      { session }
    );
    expect(NotificationService.push).toHaveBeenCalledWith(expect.objectContaining({ userId: 'user-id' }));
    expect(result.notification).toBeUndefined();
  });

  it('does not push when the MongoDB transaction rolls back', async () => {
    const session = {
      withTransaction: jest.fn(async (work) => {
        await work(session);
        throw new Error('transaction failed');
      }),
      endSession: jest.fn()
    };
    mongoose.startSession.mockResolvedValue(session);

    await expect(LedgerService.addDue(ownerId, customerId, { amount: 25 })).rejects.toThrow(
      'transaction failed'
    );

    expect(NotificationService.create).toHaveBeenCalledWith(expect.any(Object), { session });
    expect(NotificationService.push).not.toHaveBeenCalled();
  });

  it('does not create or push a notification for an idempotent replay', async () => {
    const session = {
      withTransaction: jest.fn(async (work) => work(session)),
      endSession: jest.fn()
    };
    mongoose.startSession.mockResolvedValue(session);
    TransactionRepository.findByRequestId.mockResolvedValue({ _id: 'existing-transaction' });

    const result = await LedgerService.addDue(ownerId, customerId, {
      amount: 25,
      requestId: 'idempotent-request'
    });

    expect(result.idempotentReplay).toBe(true);
    expect(NotificationService.create).not.toHaveBeenCalled();
    expect(NotificationService.push).not.toHaveBeenCalled();
  });
});

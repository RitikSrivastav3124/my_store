jest.mock('../src/repositories/notification.repository', () => ({
  create: jest.fn()
}));
jest.mock('../src/repositories/user.repository', () => ({
  findById: jest.fn(),
  removeFcmTokens: jest.fn()
}));
jest.mock('../src/config/firebase', () => ({
  getMessaging: jest.fn()
}));
jest.mock('../src/utils/logger', () => ({
  warn: jest.fn()
}));

const UserRepository = require('../src/repositories/user.repository');
const { getMessaging } = require('../src/config/firebase');
const logger = require('../src/utils/logger');
const NotificationService = require('../src/services/notification.service');

const notification = {
  userId: 'user-id',
  title: 'Payment recorded',
  body: 'A payment was recorded.',
  data: { customerId: 'customer-id' }
};

describe('NotificationService.push', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('contains FCM delivery failures so committed ledger operations remain successful', async () => {
    const sendEachForMulticast = jest.fn().mockRejectedValue(new Error('FCM unavailable'));
    UserRepository.findById.mockResolvedValue({ fcmTokens: ['valid-token'] });
    getMessaging.mockReturnValue({ sendEachForMulticast });

    await expect(NotificationService.push(notification)).resolves.toBeUndefined();

    expect(sendEachForMulticast).toHaveBeenCalled();
    expect(UserRepository.removeFcmTokens).not.toHaveBeenCalled();
    expect(logger.warn).toHaveBeenCalledWith('Failed to deliver push notification', {
      userId: 'user-id',
      error: 'FCM unavailable'
    });
  });

  it('removes invalid FCM tokens after delivery', async () => {
    const sendEachForMulticast = jest.fn().mockResolvedValue({
      responses: [
        { success: true },
        { error: { code: 'messaging/registration-token-not-registered' } },
        { error: { code: 'messaging/invalid-registration-token' } }
      ]
    });
    UserRepository.findById.mockResolvedValue({ fcmTokens: ['valid-token', 'removed-token', 'invalid-token'] });
    getMessaging.mockReturnValue({ sendEachForMulticast });

    await NotificationService.push(notification);

    expect(UserRepository.removeFcmTokens).toHaveBeenCalledWith('user-id', ['removed-token', 'invalid-token']);
  });
});

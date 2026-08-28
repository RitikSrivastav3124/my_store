const mongoose = require('mongoose');
const ROLES = require('../constants/roles');
const { USER_STATUS } = require('../constants/statusCodes');
const UserRepository = require('../repositories/user.repository');
const RefreshTokenRepository = require('../repositories/refreshToken.repository');
const AuditService = require('./audit.service');
const AppError = require('../utils/appError');
const { comparePassword, hashPassword } = require('../utils/password');
const {
  generateRefreshToken,
  getRefreshTokenExpiry,
  hashToken,
  signAccessToken
} = require('../utils/jwt');

const buildTokenPayload = async (user, context = {}) => {
  const accessToken = signAccessToken(user);
  const refreshToken = generateRefreshToken();
  const tokenHash = hashToken(refreshToken);

  await RefreshTokenRepository.create({
    userId: user._id,
    tokenHash,
    expiresAt: getRefreshTokenExpiry(),
    userAgent: context.userAgent || '',
    ipAddress: context.ipAddress || ''
  });

  return {
    user,
    accessToken,
    refreshToken
  };
};

const MAX_FAILED_LOGINS = 5;
const LOCK_MINUTES = 15;

class AuthService {
  static async registerOwner(payload, context = {}) {
    const duplicate = await UserRepository.findDuplicate({
      email: payload.email,
      phone: payload.phone
    });

    if (duplicate) throw new AppError('A user with this phone or email already exists', 409);

    const user = await UserRepository.create({
      name: payload.name,
      phone: payload.phone,
      email: payload.email,
      password: await hashPassword(payload.password),
      role: ROLES.OWNER,
      status: USER_STATUS.ACTIVE
    });

    const session = await buildTokenPayload(user, context);
    await AuditService.record({
      action: 'auth.register',
      performedBy: user._id,
      newValue: { role: user.role, status: user.status }
    }, { ...context, actorRole: user.role });
    return session;
  }

  static async login({ identifier, password, fcmToken }, context = {}) {
    const user = await UserRepository.findByEmailOrPhone(identifier);

    if (!user) {
      throw new AppError('Invalid credentials', 401);
    }

    if (user.lockUntil && user.lockUntil > new Date()) {
      throw new AppError('Account is temporarily locked. Please try again later.', 423);
    }

    if (!(await comparePassword(password, user.password))) {
      await UserRepository.recordFailedLogin(user._id, MAX_FAILED_LOGINS, LOCK_MINUTES);
      await AuditService.record({
        action: 'auth.login_failed',
        performedBy: user._id,
        newValue: { reason: 'invalid_password' }
      }, { ...context, actorRole: user.role });
      throw new AppError('Invalid credentials', 401);
    }

    if (user.status !== USER_STATUS.ACTIVE) {
      throw new AppError('Your account is not active', 403);
    }

    await UserRepository.resetLoginFailures(user._id);
    if (fcmToken) await UserRepository.addFcmToken(user._id, fcmToken);

    const session = await buildTokenPayload(user, context);
    await AuditService.record({
      action: 'auth.login',
      performedBy: user._id,
      newValue: { role: user.role }
    }, { ...context, actorRole: user.role });
    return session;
  }

  static async refresh(refreshToken, context = {}) {
    if (!refreshToken) throw new AppError('Refresh token is required', 401);

    const oldHash = hashToken(refreshToken);
    const session = await mongoose.startSession();

    try {
      let result;
      await session.withTransaction(async () => {
        const nextRefreshToken = generateRefreshToken();
        const nextHash = hashToken(nextRefreshToken);
        const storedToken = await RefreshTokenRepository.claimActive(oldHash, nextHash, { session });
        if (!storedToken) throw new AppError('Invalid refresh token', 401);

        const user = await UserRepository.findById(storedToken.userId, undefined, { session });
        if (!user || user.status !== USER_STATUS.ACTIVE) {
          throw new AppError('User is not active or does not exist', 401);
        }

        await RefreshTokenRepository.create(
          {
            userId: user._id,
            tokenHash: nextHash,
            expiresAt: getRefreshTokenExpiry(),
            userAgent: context.userAgent || '',
            ipAddress: context.ipAddress || ''
          },
          { session }
        );

        result = {
          user,
          accessToken: signAccessToken(user),
          refreshToken: nextRefreshToken
        };
      });
      return result;
    } finally {
      await session.endSession();
    }
  }

  static async logout(refreshToken, context = {}) {
    if (!refreshToken) return;
    const tokenHash = hashToken(refreshToken);
    const storedToken = await RefreshTokenRepository.findActiveByHash(tokenHash);
    if (storedToken) {
      const user = await UserRepository.findById(storedToken.userId);
      await AuditService.record({
        action: 'auth.logout',
        performedBy: storedToken.userId,
        newValue: { tokenRevoked: true }
      }, { ...context, actorRole: user?.role || '' });
    }
    await RefreshTokenRepository.revoke(tokenHash);
  }

  static async changePassword(userId, { currentPassword, newPassword }, context = {}) {
    const user = await UserRepository.findByIdWithPassword(userId);
    if (!user || !(await comparePassword(currentPassword, user.password))) {
      throw new AppError('Current password is incorrect', 400);
    }

    const updated = await UserRepository.updateById(userId, {
      password: await hashPassword(newPassword),
      passwordChangedAt: new Date()
    });

    await RefreshTokenRepository.revokeAllForUser(userId);
    await AuditService.record({
      action: 'auth.password_changed',
      performedBy: userId,
      oldValue: { passwordChangedAt: user.passwordChangedAt || null },
      newValue: { passwordChangedAt: updated.passwordChangedAt || new Date() }
    }, { ...context, actorRole: user.role });
    return updated;
  }
}

module.exports = AuthService;

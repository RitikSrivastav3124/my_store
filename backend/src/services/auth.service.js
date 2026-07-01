const ROLES = require('../constants/roles');
const { USER_STATUS } = require('../constants/statusCodes');
const UserRepository = require('../repositories/user.repository');
const RefreshTokenRepository = require('../repositories/refreshToken.repository');
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

    return buildTokenPayload(user, context);
  }

  static async login({ identifier, password, fcmToken }, context = {}) {
    const user = await UserRepository.findByEmailOrPhone(identifier);

    if (!user || !(await comparePassword(password, user.password))) {
      throw new AppError('Invalid credentials', 401);
    }

    if (user.status !== USER_STATUS.ACTIVE) {
      throw new AppError('Your account is not active', 403);
    }

    if (fcmToken) await UserRepository.addFcmToken(user._id, fcmToken);

    return buildTokenPayload(user, context);
  }

  static async refresh(refreshToken, context = {}) {
    if (!refreshToken) throw new AppError('Refresh token is required', 401);

    const oldHash = hashToken(refreshToken);
    const storedToken = await RefreshTokenRepository.findActiveByHash(oldHash);
    if (!storedToken) throw new AppError('Invalid refresh token', 401);

    const user = await UserRepository.findById(storedToken.userId);
    if (!user || user.status !== USER_STATUS.ACTIVE) {
      throw new AppError('User is not active or does not exist', 401);
    }

    const nextRefreshToken = generateRefreshToken();
    const nextHash = hashToken(nextRefreshToken);

    await RefreshTokenRepository.create({
      userId: user._id,
      tokenHash: nextHash,
      expiresAt: getRefreshTokenExpiry(),
      userAgent: context.userAgent || '',
      ipAddress: context.ipAddress || ''
    });
    await RefreshTokenRepository.revoke(oldHash, nextHash);

    return {
      user,
      accessToken: signAccessToken(user),
      refreshToken: nextRefreshToken
    };
  }

  static async logout(refreshToken) {
    if (refreshToken) await RefreshTokenRepository.revoke(hashToken(refreshToken));
  }

  static async changePassword(userId, { currentPassword, newPassword }) {
    const user = await UserRepository.findByIdWithPassword(userId);
    if (!user || !(await comparePassword(currentPassword, user.password))) {
      throw new AppError('Current password is incorrect', 400);
    }

    const updated = await UserRepository.updateById(userId, {
      password: await hashPassword(newPassword)
    });

    await RefreshTokenRepository.revokeAllForUser(userId);
    return updated;
  }
}

module.exports = AuthService;

const User = require('../models/user.model');

const buildDuplicateQuery = ({ email, phone }) => {
  const conditions = [];
  if (email) conditions.push({ email: email.toLowerCase() });
  if (phone) conditions.push({ phone });
  return conditions.length ? { $or: conditions } : null;
};

class UserRepository {
  static create(data, options = {}) {
    return User.create([data], options).then(([user]) => user);
  }

  static findById(id, projection = undefined, options = {}) {
    return User.findById(id, projection, options);
  }

  static findByIdWithPassword(id) {
    return User.findById(id).select('+password');
  }

  static findByEmailOrPhone(identifier) {
    const normalized = identifier.toLowerCase();
    return User.findOne({
      $or: [{ email: normalized }, { phone: identifier }]
    }).select('+password +loginAttempts +lockUntil');
  }

  static findDuplicate({ email, phone }, excludeId = null) {
    const query = buildDuplicateQuery({ email, phone });
    if (!query) return null;
    if (excludeId) query._id = { $ne: excludeId };
    return User.findOne(query);
  }

  static updateById(id, data, options = {}) {
    return User.findByIdAndUpdate(id, data, {
      new: true,
      runValidators: true,
      ...options
    });
  }

  static recordFailedLogin(userId, maxAttempts, lockMinutes) {
    const lockUntil = new Date(Date.now() + lockMinutes * 60 * 1000);
    return User.findByIdAndUpdate(
      userId,
      [
        {
          $set: {
            loginAttempts: { $add: [{ $ifNull: ['$loginAttempts', 0] }, 1] }
          }
        },
        {
          $set: {
            lockUntil: {
              $cond: [{ $gte: ['$loginAttempts', maxAttempts] }, lockUntil, '$lockUntil']
            }
          }
        }
      ],
      { new: true }
    ).select('+loginAttempts +lockUntil');
  }

  static resetLoginFailures(userId) {
    return User.findByIdAndUpdate(userId, {
      loginAttempts: 0,
      lockUntil: null
    });
  }

  static addFcmToken(userId, token) {
    return User.findByIdAndUpdate(
      userId,
      { $addToSet: { fcmTokens: token } },
      { new: true, runValidators: true }
    );
  }

  static removeFcmTokens(userId, tokens) {
    if (!tokens.length) return null;
    return User.findByIdAndUpdate(
      userId,
      { $pull: { fcmTokens: { $in: tokens } } },
      { new: true, runValidators: true }
    );
  }
}

module.exports = UserRepository;

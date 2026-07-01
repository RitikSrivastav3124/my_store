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
    }).select('+password');
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

  static addFcmToken(userId, token) {
    return User.findByIdAndUpdate(
      userId,
      { $addToSet: { fcmTokens: token } },
      { new: true, runValidators: true }
    );
  }
}

module.exports = UserRepository;

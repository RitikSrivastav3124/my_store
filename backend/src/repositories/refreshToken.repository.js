const RefreshToken = require('../models/refreshToken.model');

class RefreshTokenRepository {
  static create(data) {
    return RefreshToken.create(data);
  }

  static findActiveByHash(tokenHash) {
    return RefreshToken.findOne({
      tokenHash,
      revokedAt: null,
      expiresAt: {
        $gt: new Date()
      }
    });
  }

  static revoke(tokenHash, replacementHash = null) {
    return RefreshToken.findOneAndUpdate(
      { tokenHash, revokedAt: null },
      {
        revokedAt: new Date(),
        replacedByTokenHash: replacementHash
      },
      { new: true }
    );
  }

  static revokeAllForUser(userId) {
    return RefreshToken.updateMany(
      { userId, revokedAt: null },
      {
        revokedAt: new Date()
      }
    );
  }
}

module.exports = RefreshTokenRepository;

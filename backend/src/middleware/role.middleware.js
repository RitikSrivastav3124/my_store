const AppError = require('../utils/appError');

const authorize = (...roles) => (req, _res, next) => {
  if (!req.user || !roles.includes(req.user.role)) {
    return next(new AppError('You are not authorized to access this resource', 403));
  }

  return next();
};

module.exports = authorize;

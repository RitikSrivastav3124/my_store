const mongoose = require('mongoose');
const AppError = require('../utils/appError');
const logger = require('../utils/logger');

const normalizeError = (error) => {
  if (error instanceof AppError) return error;

  if (error instanceof mongoose.Error.ValidationError) {
    return new AppError(
      'Validation failed',
      422,
      Object.values(error.errors).map((item) => ({
        field: item.path,
        message: item.message
      }))
    );
  }

  if (error instanceof mongoose.Error.CastError) {
    return new AppError('Invalid resource identifier', 400);
  }

  if (error.code === 11000) {
    const fields = Object.keys(error.keyValue || {});
    return new AppError(`${fields.join(', ')} already exists`, 409);
  }

  if (error.name === 'JsonWebTokenError' || error.name === 'TokenExpiredError') {
    return new AppError('Invalid or expired authentication token', 401);
  }

  return new AppError('Internal server error', 500);
};

const notFoundHandler = (req, _res, next) => {
  next(new AppError(`Route not found: ${req.method} ${req.originalUrl}`, 404));
};

const errorHandler = (error, _req, res, _next) => {
  const normalized = normalizeError(error);

  if (normalized.statusCode >= 500) {
    logger.error(normalized.message, {
      stack: error.stack
    });
  }

  const body = {
    success: false,
    message: normalized.message,
    errors: normalized.errors || []
  };

  res.status(normalized.statusCode).json(body);
};

module.exports = {
  notFoundHandler,
  errorHandler
};

const mongoose = require('mongoose');
const { PAYMENT_METHODS, TRANSACTION_TYPES } = require('../constants/transactionTypes');

const transactionSchema = new mongoose.Schema(
  {
    customerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Customer',
      required: true,
      index: true
    },
    ownerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true
    },
    type: {
      type: String,
      enum: Object.values(TRANSACTION_TYPES),
      required: true,
      index: true
    },
    amount: {
      type: Number,
      required: true,
      min: 0.01
    },
    description: {
      type: String,
      trim: true,
      maxlength: 500
    },
    paymentMethod: {
      type: String,
      enum: Object.values(PAYMENT_METHODS),
      default: PAYMENT_METHODS.CASH
    },
    balanceAfter: {
      type: Number,
      required: true,
      min: 0
    },
    requestId: {
      type: String,
      trim: true,
      maxlength: 120,
      default: null
    }
  },
  {
    timestamps: {
      createdAt: true,
      updatedAt: false
    }
  }
);

transactionSchema.index({ customerId: 1, createdAt: -1 });
transactionSchema.index({ ownerId: 1, createdAt: -1 });
transactionSchema.index({ ownerId: 1, type: 1 });
transactionSchema.index(
  { ownerId: 1, requestId: 1 },
  { unique: true, partialFilterExpression: { requestId: { $type: 'string' } } }
);

module.exports = mongoose.model('Transaction', transactionSchema);

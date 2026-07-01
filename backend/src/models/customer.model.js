const mongoose = require('mongoose');

const customerSchema = new mongoose.Schema(
  {
    ownerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
      index: true
    },
    creditLimit: {
      type: Number,
      default: 0,
      min: 0
    },
    notes: {
      type: String,
      trim: true,
      maxlength: 1000
    },
    currentDue: {
      type: Number,
      default: 0,
      min: 0,
      index: true
    }
  },
  {
    timestamps: true
  }
);

customerSchema.index({ ownerId: 1, currentDue: -1 });
customerSchema.index({ ownerId: 1, createdAt: -1 });

module.exports = mongoose.model('Customer', customerSchema);

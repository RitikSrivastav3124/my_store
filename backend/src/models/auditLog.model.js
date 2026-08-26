const mongoose = require('mongoose');

const auditLogSchema = new mongoose.Schema(
  {
    action: {
      type: String,
      required: true,
      trim: true,
      index: true
    },
    performedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true
    },
    performedByRole: {
      type: String,
      trim: true,
      index: true
    },
    targetCustomer: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Customer',
      index: true
    },
    ipAddress: {
      type: String,
      trim: true,
      default: ''
    },
    userAgent: {
      type: String,
      trim: true,
      default: ''
    },
    requestId: {
      type: String,
      trim: true,
      default: ''
    },
    oldValue: {
      type: mongoose.Schema.Types.Mixed,
      default: null
    },
    newValue: {
      type: mongoose.Schema.Types.Mixed,
      default: null
    },
    timestamp: {
      type: Date,
      default: Date.now,
      index: true
    }
  },
  {
    versionKey: false
  }
);

auditLogSchema.index({ performedBy: 1, timestamp: -1 });
auditLogSchema.index({ targetCustomer: 1, timestamp: -1 });

auditLogSchema.pre(['updateOne', 'findOneAndUpdate', 'deleteOne', 'deleteMany'], function blockAuditMutation(next) {
  next(new Error('Audit logs are immutable'));
});

module.exports = mongoose.model('AuditLog', auditLogSchema);

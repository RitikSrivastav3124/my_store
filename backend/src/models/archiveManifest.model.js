const mongoose = require('mongoose');
const { ARCHIVE_STATES } = require('../constants/archiveStates');

const archiveManifestSchema = new mongoose.Schema(
  {
    ownerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true
    },
    status: {
      type: String,
      enum: Object.values(ARCHIVE_STATES),
      required: true,
      default: ARCHIVE_STATES.PENDING,
      index: true
    },
    periodStart: {
      type: Date,
      required: true
    },
    periodEnd: {
      type: Date,
      required: true
    },
    transactionCount: {
      type: Number,
      required: true,
      min: 0
    },
    storageProvider: {
      type: String,
      trim: true,
      maxlength: 100
    },
    storageKey: {
      type: String,
      trim: true,
      maxlength: 1024
    },
    checksum: {
      type: String,
      trim: true,
      maxlength: 256
    },
    fileSize: {
      type: Number,
      min: 0
    },
    completedAt: {
      type: Date
    },
    errorMessage: {
      type: String,
      trim: true,
      maxlength: 1000
    }
  },
  {
    timestamps: true
  }
);

archiveManifestSchema.index({ ownerId: 1, status: 1 });
archiveManifestSchema.index({ ownerId: 1, periodStart: -1 });
archiveManifestSchema.index({ storageProvider: 1, storageKey: 1 });

module.exports = mongoose.model('ArchiveManifest', archiveManifestSchema);

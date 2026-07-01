const AuditLog = require('../models/auditLog.model');

class AuditLogRepository {
  static create(data, options = {}) {
    return AuditLog.create([data], options).then(([auditLog]) => auditLog);
  }
}

module.exports = AuditLogRepository;

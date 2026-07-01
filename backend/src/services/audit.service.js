const AuditLogRepository = require('../repositories/auditLog.repository');

class AuditService {
  static record({ action, performedBy, targetCustomer = null, oldValue = null, newValue = null }, options = {}) {
    return AuditLogRepository.create(
      {
        action,
        performedBy,
        targetCustomer,
        oldValue,
        newValue,
        timestamp: new Date()
      },
      options
    );
  }
}

module.exports = AuditService;

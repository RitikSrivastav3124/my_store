const AuditLogRepository = require('../repositories/auditLog.repository');

class AuditService {
  static record({ action, performedBy, targetCustomer = null, oldValue = null, newValue = null }, options = {}) {
    return AuditLogRepository.create(
      {
        action,
        performedBy,
        performedByRole: options.actorRole || '',
        targetCustomer,
        ipAddress: options.ipAddress || '',
        userAgent: options.userAgent || '',
        requestId: options.requestId || '',
        oldValue,
        newValue,
        timestamp: new Date()
      },
      { session: options.session }
    );
  }
}

module.exports = AuditService;

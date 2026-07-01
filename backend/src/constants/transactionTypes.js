const TRANSACTION_TYPES = Object.freeze({
  DUE_ADDED: 'due_added',
  DUE_REDUCED: 'due_reduced',
  PAYMENT_RECEIVED: 'payment_received'
});

const PAYMENT_METHODS = Object.freeze({
  CASH: 'cash',
  UPI: 'upi',
  CARD: 'card',
  BANK_TRANSFER: 'bank_transfer',
  OTHER: 'other'
});

module.exports = {
  TRANSACTION_TYPES,
  PAYMENT_METHODS
};

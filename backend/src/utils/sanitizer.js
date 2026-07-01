const sanitizeString = (value) => {
  if (typeof value !== 'string') return value;
  return value.trim().replace(/\s+/g, ' ');
};

const sanitizeObject = (payload) => {
  if (!payload || typeof payload !== 'object') return payload;

  return Object.entries(payload).reduce((acc, [key, value]) => {
    if (Array.isArray(value)) {
      acc[key] = value.map((item) => (typeof item === 'string' ? sanitizeString(item) : item));
      return acc;
    }

    if (value && typeof value === 'object' && !(value instanceof Date)) {
      acc[key] = sanitizeObject(value);
      return acc;
    }

    acc[key] = sanitizeString(value);
    return acc;
  }, {});
};

module.exports = {
  sanitizeString,
  sanitizeObject
};

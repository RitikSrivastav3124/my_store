const dotenv = require('dotenv');

dotenv.config();

const toNumber = (value, fallback) => {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
};

const toArray = (value, fallback = []) => {
  if (!value) return fallback;
  return value
    .split(',')
    .map((entry) => entry.trim())
    .filter(Boolean);
};

const env = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: toNumber(process.env.PORT, 5000),
  apiPrefix: process.env.API_PREFIX || '/api',
  mongoUri: process.env.MONGO_URI ,
  jwtAccessSecret: process.env.JWT_ACCESS_SECRET ,
  jwtRefreshSecret: process.env.JWT_REFRESH_SECRET ,
  jwtAccessExpiresIn: process.env.JWT_ACCESS_EXPIRES_IN || '15m',
  refreshTokenExpiresDays: toNumber(process.env.REFRESH_TOKEN_EXPIRES_DAYS, 30),
  bcryptSaltRounds: toNumber(process.env.BCRYPT_SALT_ROUNDS, 12),
  corsOrigin: toArray(process.env.CORS_ORIGIN, ['http://localhost:3000', 'http://localhost:5173']),
  rateLimitWindowMs: toNumber(process.env.RATE_LIMIT_WINDOW_MS, 15 * 60 * 1000),
  rateLimitMax: toNumber(process.env.RATE_LIMIT_MAX, 200),
  authRateLimitMax: toNumber(process.env.AUTH_RATE_LIMIT_MAX, 20),
  firebaseProjectId: process.env.FIREBASE_PROJECT_ID || '',
  firebaseClientEmail: process.env.FIREBASE_CLIENT_EMAIL || '',
  firebasePrivateKey: (process.env.FIREBASE_PRIVATE_KEY || '').replace(/\\n/g, '\n'),
  reportBrandName: process.env.REPORT_BRAND_NAME || 'Khata Ledger',
  logLevel: process.env.LOG_LEVEL || 'info'
};

module.exports = env;

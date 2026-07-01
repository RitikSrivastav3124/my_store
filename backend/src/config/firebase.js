const admin = require('firebase-admin');
const env = require('./env');
const logger = require('../utils/logger');

const hasFirebaseConfig = Boolean(
  env.firebaseProjectId && env.firebaseClientEmail && env.firebasePrivateKey
);

const initializeFirebase = () => {
  if (!hasFirebaseConfig) {
    logger.warn('Firebase Admin SDK is not configured; push notifications will be stored only.');
    return null;
  }

  if (admin.apps.length) return admin.app();

  return admin.initializeApp({
    credential: admin.credential.cert({
      projectId: env.firebaseProjectId,
      clientEmail: env.firebaseClientEmail,
      privateKey: env.firebasePrivateKey
    })
  });
};

const getMessaging = () => {
  const app = initializeFirebase();
  return app ? admin.messaging(app) : null;
};

module.exports = {
  initializeFirebase,
  getMessaging
};

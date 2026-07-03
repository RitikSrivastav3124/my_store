const mongoose = require('mongoose');
const env = require('./env');
const logger = require('../utils/logger');

const connectDatabase = async () => {
  mongoose.set('strictQuery', true);

  await mongoose.connect(env.mongoUri, {
    autoIndex: env.nodeEnv !== 'production'
  });

  logger.info(`MongoDB connected: ${mongoose.connection.host}`);
  console.log(`MongoDB connected: ${mongoose.connection.host}`);
};

const disconnectDatabase = async () => {
  await mongoose.disconnect();
};

module.exports = {
  connectDatabase,
  disconnectDatabase
};

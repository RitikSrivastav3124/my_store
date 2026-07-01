const app = require('./app');
const env = require('./config/env');
const { connectDatabase } = require('./config/db');
const { initializeFirebase } = require('./config/firebase');
const logger = require('./utils/logger');

let server;

const startServer = async () => {
  await connectDatabase();
  initializeFirebase();

  server = app.listen(env.port, () => {
    logger.info(`Server running on port ${env.port}`);
  });
};

const shutdown = async (signal) => {
  logger.info(`${signal} received. Shutting down gracefully.`);
  if (server) {
    server.close(() => {
      logger.info('HTTP server closed.');
      process.exit(0);
    });
    return;
  }

  process.exit(0);
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
process.on('unhandledRejection', (error) => {
  logger.error('Unhandled promise rejection', { error: error.message, stack: error.stack });
  shutdown('unhandledRejection');
});
process.on('uncaughtException', (error) => {
  logger.error('Uncaught exception', { error: error.message, stack: error.stack });
  process.exit(1);
});

startServer().catch((error) => {
  logger.error('Failed to start server', { error: error.message, stack: error.stack });
  process.exit(1);
});

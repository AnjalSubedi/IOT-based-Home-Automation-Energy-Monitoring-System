/**
 * server.js — Application entry point.
 *
 * Starts the HTTP server, initializes Socket.IO, MQTT, and cron scheduler.
 *
 * Run: node server.js  OR  npm run dev  (nodemon)
 */

const http = require('http');
const dotenv = require('dotenv');

// Load environment variables FIRST
dotenv.config();

const app = require('./app');
const connectDB = require('./src/config/db');
const { getMqttClient } = require('./src/config/mqtt');
const { initMqttSubscriptions } = require('./src/mqtt/mqttClient');
const { initSocket } = require('./src/sockets/socketManager');
const { loadAllSchedules } = require('./src/services/scheduleService');
const logger = require('./src/utils/logger');

const PORT = process.env.PORT || 5000;

// ── Create HTTP server (needed for Socket.IO) ─────────────────────────────────
const httpServer = http.createServer(app);

// ── Initialize Socket.IO ───────────────────────────────────────────────────────
initSocket(httpServer);

// ── Start server ───────────────────────────────────────────────────────────────
const startServer = async () => {
  try {
    // 1. Connect to MongoDB
    await connectDB();

    // 2. Initialize MQTT connection to HiveMQ
    getMqttClient(); // Creates the client and connects
    initMqttSubscriptions(); // Registers topic subscriptions

    // 3. Load and start all saved cron schedules
    await loadAllSchedules();

    // 4. Start listening
    httpServer.listen(PORT, () => {
      logger.success(`Server running on port ${PORT} [${process.env.NODE_ENV} mode]`);
      logger.info(`API: http://localhost:${PORT}`);
      logger.info(`Health: http://localhost:${PORT}/health`);
    });
  } catch (err) {
    logger.error(`Failed to start server: ${err.message}`);
    process.exit(1);
  }
};

// ── Graceful Shutdown ──────────────────────────────────────────────────────────
process.on('SIGTERM', () => {
  logger.info('SIGTERM received — shutting down gracefully');
  httpServer.close(() => {
    logger.info('HTTP server closed');
    process.exit(0);
  });
});

process.on('unhandledRejection', (err) => {
  logger.error(`Unhandled Promise Rejection: ${err.message}`);
  httpServer.close(() => process.exit(1));
});

startServer();

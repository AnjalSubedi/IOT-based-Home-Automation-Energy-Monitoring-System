/**
 * socketManager.js — Socket.IO initialization and helpers.
 *
 * Authenticates Socket.IO connections using JWT.
 * Rooms: each user gets a private room "user_{userId}".
 * Emitting to a user: getIO().to(`user_${userId}`).emit(event, data)
 *
 * Events emitted to Flutter:
 *   'live_reading'  — new telemetry reading
 *   'relay_state'   — relay state changed
 *   'new_alert'     — new alert triggered
 *   'device_status' — device online/offline
 */

const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');
const logger = require('../utils/logger');

let io = null;

/**
 * Initialize Socket.IO on the HTTP server.
 * @param {http.Server} httpServer
 */
const initSocket = (httpServer) => {
  io = new Server(httpServer, {
    cors: {
      origin: '*', // Restrict in production
      methods: ['GET', 'POST'],
    },
    pingTimeout: 60000,
  });

  // ── JWT Authentication Middleware ─────────────────────────────────────────
  io.use((socket, next) => {
    const token = socket.handshake.auth?.token || socket.handshake.query?.token;

    if (!token) {
      return next(new Error('Authentication required'));
    }

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      socket.userId = decoded.id; // Attach userId to socket
      next();
    } catch (err) {
      next(new Error('Invalid token'));
    }
  });

  // ── Connection Handler ────────────────────────────────────────────────────
  io.on('connection', (socket) => {
    const userId = socket.userId;

    // Join personal room
    socket.join(`user_${userId}`);
    logger.info(`Socket connected: user ${userId} (socketId: ${socket.id})`);

    socket.on('disconnect', (reason) => {
      logger.info(`Socket disconnected: user ${userId} — ${reason}`);
    });

    // Client can subscribe to a specific device's data
    socket.on('subscribe_device', (deviceId) => {
      socket.join(`device_${deviceId}`);
      logger.info(`User ${userId} subscribed to device ${deviceId}`);
    });

    socket.on('unsubscribe_device', (deviceId) => {
      socket.leave(`device_${deviceId}`);
    });
  });

  logger.success('Socket.IO initialized');
  return io;
};

/**
 * Get the Socket.IO instance (call after initSocket).
 */
const getIO = () => {
  if (!io) {
    logger.warn('Socket.IO not initialized yet');
  }
  return io;
};

/**
 * Emit an event to a specific user's room.
 * @param {string} userId
 * @param {string} event
 * @param {Object} data
 */
const emitToUser = (userId, event, data) => {
  if (!io) return;
  io.to(`user_${userId}`).emit(event, data);
};

/**
 * Emit to all subscribers of a specific device.
 * @param {string} deviceId
 * @param {string} event
 * @param {Object} data
 */
const emitToDevice = (deviceId, event, data) => {
  if (!io) return;
  io.to(`device_${deviceId}`).emit(event, data);
};

module.exports = { initSocket, getIO, emitToUser, emitToDevice };

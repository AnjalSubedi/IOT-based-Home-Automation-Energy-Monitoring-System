/**
 * statusHandler.js — Processes device online/offline status.
 *
 * Topic: home/{userId}/{deviceId}/status
 * Payload: "online" | "offline" (string or JSON { status: "online" })
 *
 * ESP32 publishes "online" on connect and has LWT set to "offline".
 */

const Device = require('../../models/Device');
const Alert = require('../../models/Alert');
const { emitToUser, emitToDevice } = require('../../sockets/socketManager');
const logger = require('../../utils/logger');

const handleStatus = async (userId, deviceId, payload) => {
  try {
    // Accept both raw string and JSON
    let status;
    if (typeof payload === 'string') {
      status = payload.toLowerCase();
    } else if (payload && payload.status) {
      status = payload.status.toLowerCase();
    } else {
      return;
    }

    const isOnline = status === 'online';

    const device = await Device.findOneAndUpdate(
      { deviceId, userId },
      { isOnline, lastSeenAt: isOnline ? new Date() : undefined },
      { new: true }
    );

    if (!device) {
      logger.warn(`Status update for unregistered device: ${deviceId}`);
      return;
    }

    const event = { deviceId, isOnline, lastSeenAt: device.lastSeenAt, timestamp: new Date() };
    emitToUser(userId.toString(), 'device_status', event);
    emitToDevice(deviceId, 'device_status', event);

    // Create offline alert so Flutter notifies user
    if (!isOnline) {
      const alert = await Alert.create({
        userId,
        deviceId,
        type: 'DEVICE_OFFLINE',
        message: `Device "${device.name}" went offline`,
      });
      emitToUser(userId.toString(), 'new_alert', alert);
    }

    logger.mqtt(`Device ${deviceId} → ${isOnline ? 'ONLINE' : 'OFFLINE'}`);
  } catch (err) {
    logger.error(`statusHandler error: ${err.message}`);
  }
};

module.exports = { handleStatus };

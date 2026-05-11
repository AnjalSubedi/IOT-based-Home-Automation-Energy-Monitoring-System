/**
 * stateHandler.js — Processes relay state confirmations from ESP32.
 *
 * Topic: home/{userId}/{deviceId}/relay/{relayId}/state
 * Payload: { relayId, state }
 *
 * ESP32 publishes this after executing a relay command.
 * Backend updates DB and notifies Flutter.
 */

const Relay = require('../../models/Relay');
const { emitToUser, emitToDevice } = require('../../sockets/socketManager');
const logger = require('../../utils/logger');

const handleRelayState = async (userId, deviceId, relayId, payload) => {
  try {
    const { state } = payload;
    const relayNum = parseInt(relayId, 10);

    if (isNaN(relayNum) || typeof state !== 'boolean') {
      logger.warn(`Invalid relay state payload from ${deviceId}: ${JSON.stringify(payload)}`);
      return;
    }

    // Update confirmed state in DB
    await Relay.findOneAndUpdate(
      { deviceId, relayId: relayNum },
      { state, lastChangedBy: 'esp32', lastChangedAt: new Date() },
      { upsert: true }
    );

    const event = { deviceId, relayId: relayNum, state, changedBy: 'esp32', timestamp: new Date() };
    emitToUser(userId.toString(), 'relay_state', event);
    emitToDevice(deviceId, 'relay_state', event);

    logger.mqtt(`Relay state confirmed: ${deviceId} relay${relayNum} → ${state ? 'ON' : 'OFF'}`);
  } catch (err) {
    logger.error(`stateHandler error: ${err.message}`);
  }
};

module.exports = { handleRelayState };

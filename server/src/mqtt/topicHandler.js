/**
 * topicHandler.js — MQTT topic router.
 *
 * Receives all MQTT messages and routes them to the appropriate handler
 * based on the topic pattern:
 *
 *   home/{userId}/{deviceId}/telemetry          → telemetryHandler
 *   home/{userId}/{deviceId}/relay/{n}/state    → stateHandler
 *   home/{userId}/{deviceId}/status             → statusHandler
 *
 * Wildcard subscriptions:
 *   home/+/+/telemetry
 *   home/+/+/relay/+/state
 *   home/+/+/status
 */

const { handleTelemetry } = require('./handlers/telemetryHandler');
const { handleRelayState } = require('./handlers/stateHandler');
const { handleStatus } = require('./handlers/statusHandler');
const logger = require('../utils/logger');

/**
 * Parse a topic string and route to the right handler.
 * @param {string} topic    - MQTT topic string
 * @param {string} message  - Raw message string
 */
const routeTopic = async (topic, message) => {
  // Parse JSON payload; fall back to raw string
  let payload;
  try {
    payload = JSON.parse(message);
  } catch {
    payload = message.toString();
  }

  // Split topic into parts: ['home', userId, deviceId, ...]
  const parts = topic.split('/');
  if (parts.length < 4 || parts[0] !== 'home') {
    logger.warn(`Unrecognized topic format: ${topic}`);
    return;
  }

  const userId = parts[1];
  const deviceId = parts[2];
  const type = parts[3];

  switch (type) {
    case 'telemetry':
      // home/{userId}/{deviceId}/telemetry
      await handleTelemetry(userId, deviceId, payload);
      break;

    case 'relay':
      // home/{userId}/{deviceId}/relay/{relayId}/state
      if (parts[5] === 'state') {
        const relayId = parts[4];
        await handleRelayState(userId, deviceId, relayId, payload);
      }
      break;

    case 'status':
      // home/{userId}/{deviceId}/status
      await handleStatus(userId, deviceId, payload);
      break;

    default:
      logger.warn(`Unhandled topic type "${type}" in: ${topic}`);
  }
};

module.exports = { routeTopic };

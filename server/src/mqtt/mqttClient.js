/**
 * mqttClient.js — MQTT subscription setup.
 *
 * Initializes the MQTT connection and registers subscriptions for all
 * device topics using wildcards.
 *
 * Call initMqttSubscriptions() once after server starts.
 */

const { getMqttClient } = require('../config/mqtt');
const { routeTopic } = require('./topicHandler');
const logger = require('../utils/logger');

// Wildcard topics the backend subscribes to
const SUBSCRIPTIONS = [
  'home/+/+/telemetry',       // Telemetry from any device
  'home/+/+/relay/+/state',   // Relay state confirmations
  'home/+/+/status',          // Device online/offline status
];

/**
 * Subscribe to all relevant MQTT topics and bind message handler.
 */
const initMqttSubscriptions = () => {
  const client = getMqttClient();
  if (!client) {
    logger.warn('MQTT client not available — skipping subscriptions');
    return;
  }

  // Subscribe once connected
  client.on('connect', () => {
    SUBSCRIPTIONS.forEach((topic) => {
      client.subscribe(topic, { qos: 1 }, (err) => {
        if (err) {
          logger.error(`Failed to subscribe to ${topic}: ${err.message}`);
        } else {
          logger.mqtt(`Subscribed to: ${topic}`);
        }
      });
    });
  });

  // Route all incoming messages
  // Skip retained relay state messages — these are old ESP32 snapshots that
  // would override user-controlled relay states in the app UI.
  client.on('message', (topic, message, packet) => {
    if (packet.retain && topic.includes('/relay/') && topic.includes('/state')) {
      logger.mqtt(`Skipping retained relay state: ${topic}`);
      return;
    }
    routeTopic(topic, message.toString());
  });
};

module.exports = { initMqttSubscriptions };

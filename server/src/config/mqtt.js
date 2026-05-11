/**
 * mqtt.js — HiveMQ Cloud MQTT client configuration.
 *
 * Connects securely over TLS (port 8883).
 * All credentials are read from environment variables — never hard-coded.
 *
 * Required env vars:
 *   MQTT_HOST       - e.g., abc123.s1.eu.hivemq.cloud
 *   MQTT_PORT       - 8883 (TLS)
 *   MQTT_USERNAME   - HiveMQ Cloud username
 *   MQTT_PASSWORD   - HiveMQ Cloud password
 *   MQTT_CLIENT_ID  - Unique ID for this backend (e.g., backend-server-001)
 */

const mqtt = require('mqtt');
const logger = require('../utils/logger');

let client = null;

/**
 * Initialize and return the MQTT client.
 * Call once at server startup. Returns the same instance on subsequent calls.
 */
const getMqttClient = () => {
  if (client) return client;

  const {
    MQTT_HOST,
    MQTT_PORT = '8883',
    MQTT_USERNAME,
    MQTT_PASSWORD,
    MQTT_CLIENT_ID = `backend-server-${Date.now()}`,
  } = process.env;

  if (!MQTT_HOST || !MQTT_USERNAME || !MQTT_PASSWORD) {
    logger.error('MQTT configuration missing. Set MQTT_HOST, MQTT_USERNAME, MQTT_PASSWORD in .env');
    // Do not crash — backend can run without MQTT in dev mode
    return null;
  }

  const brokerUrl = `mqtts://${MQTT_HOST}:${MQTT_PORT}`;

  client = mqtt.connect(brokerUrl, {
    clientId: MQTT_CLIENT_ID,
    username: MQTT_USERNAME,
    password: MQTT_PASSWORD,
    // TLS — HiveMQ Cloud uses a trusted CA, so we don't need to supply a cert
    // If using a custom broker, set: ca: fs.readFileSync('./certs/ca.crt')
    rejectUnauthorized: true,
    clean: true,
    reconnectPeriod: 5000,     // Retry every 5 seconds on disconnect
    connectTimeout: 30 * 1000, // 30 seconds
  });

  client.on('connect', () => {
    logger.mqtt(`Connected to HiveMQ Cloud at ${brokerUrl}`);
  });

  client.on('reconnect', () => {
    logger.mqtt('Reconnecting to MQTT broker...');
  });

  client.on('error', (err) => {
    logger.error(`MQTT error: ${err.message}`);
  });

  client.on('offline', () => {
    logger.warn('MQTT client offline');
  });

  return client;
};

/**
 * Publish a message to an MQTT topic.
 * @param {string} topic   - MQTT topic string
 * @param {Object} payload - JavaScript object (will be JSON-stringified)
 * @param {Object} opts    - Optional MQTT publish options (qos, retain)
 */
const mqttPublish = (topic, payload, opts = { qos: 1 }) => {
  const c = getMqttClient();
  if (!c) {
    logger.warn(`MQTT not connected. Cannot publish to ${topic}`);
    return;
  }
  const message = typeof payload === 'string' ? payload : JSON.stringify(payload);
  c.publish(topic, message, opts, (err) => {
    if (err) {
      logger.error(`Failed to publish to ${topic}: ${err.message}`);
    } else {
      logger.mqtt(`Published → ${topic}`);
    }
  });
};

module.exports = { getMqttClient, mqttPublish };

/**
 * mqtt_simulator.js — MQTT telemetry simulator for testing without ESP32.
 *
 * Publishes realistic sensor readings to HiveMQ Cloud so you can test
 * the backend and Flutter app before physical hardware is ready.
 *
 * Usage:
 *   node scripts/mqtt_simulator.js --userId <mongoUserId> --deviceId esp32-001
 *
 * Requirements:
 *   - Backend .env must have MQTT_HOST, MQTT_USERNAME, MQTT_PASSWORD
 *   - The userId and deviceId must already be registered via the API
 *
 * ⚠ Run from the server/ directory: node scripts/mqtt_simulator.js ...
 */

require('dotenv').config();
const mqtt = require('mqtt');
const logger = require('../src/utils/logger');

// ── Parse CLI args ─────────────────────────────────────────────────────────────
const args = process.argv.slice(2);
const getArg = (flag) => {
  const idx = args.indexOf(flag);
  return idx !== -1 ? args[idx + 1] : null;
};

const userId = getArg('--userId') || '000000000000000000000001'; // placeholder
const deviceId = getArg('--deviceId') || 'esp32-001';
const interval = parseInt(getArg('--interval') || '5000', 10); // ms

// ── MQTT Connection ────────────────────────────────────────────────────────────
const {
  MQTT_HOST,
  MQTT_PORT = '8883',
  MQTT_USERNAME,
  MQTT_PASSWORD,
} = process.env;

if (!MQTT_HOST || !MQTT_USERNAME || !MQTT_PASSWORD) {
  console.error('[SIMULATOR] Missing MQTT credentials in .env');
  process.exit(1);
}

const client = mqtt.connect(`mqtts://${MQTT_HOST}:${MQTT_PORT}`, {
  clientId: `simulator-${deviceId}-${Date.now()}`,
  username: MQTT_USERNAME,
  password: MQTT_PASSWORD,
  rejectUnauthorized: true,
  clean: true,
});

// ── Realistic sensor simulation ────────────────────────────────────────────────
let time = 0;
const randNoise = (base, pct) => base + base * (Math.random() - 0.5) * (pct / 100);

const generateTelemetry = () => {
  // Simulate AC voltage around 230V with slight fluctuation
  const voltage = randNoise(230, 2);
  // Simulate current that varies over time (0.2A–3A)
  const current = 0.5 + 1.5 * Math.abs(Math.sin(time / 20)) + randNoise(0.1, 20);
  const powerFactor = 0.9 + randNoise(0.05, 5);
  const power = voltage * current * Math.min(1, Math.max(0, powerFactor));
  const frequency = randNoise(50, 0.5);

  time++;

  return {
    deviceId,
    voltage: parseFloat(voltage.toFixed(2)),
    current: parseFloat(current.toFixed(3)),
    power: parseFloat(power.toFixed(2)),
    frequency: parseFloat(frequency.toFixed(1)),
    powerFactor: parseFloat(Math.min(1, powerFactor).toFixed(3)),
    timestamp: new Date().toISOString(),
  };
};

const relayStates = { 1: false, 2: false, 3: false, 4: false };

// ── Event Handlers ─────────────────────────────────────────────────────────────
client.on('connect', () => {
  logger.success(`[SIMULATOR] Connected to HiveMQ`);
  logger.info(`[SIMULATOR] Publishing telemetry every ${interval}ms`);
  logger.info(`[SIMULATOR] userId=${userId}, deviceId=${deviceId}`);

  // Publish online status
  client.publish(`home/${userId}/${deviceId}/status`, 'online', { retain: true });

  // Subscribe to relay commands (so simulator can echo state back)
  client.subscribe(`home/${userId}/${deviceId}/relay/+/set`, { qos: 1 });

  // Start publishing telemetry
  const telemetryInterval = setInterval(() => {
    const payload = generateTelemetry();
    const topic = `home/${userId}/${deviceId}/telemetry`;
    client.publish(topic, JSON.stringify(payload), { qos: 1 });
    logger.mqtt(`Telemetry → V:${payload.voltage}V I:${payload.current}A P:${payload.power}W`);
  }, interval);

  // Handle SIGINT to clean up
  process.on('SIGINT', () => {
    clearInterval(telemetryInterval);
    client.publish(`home/${userId}/${deviceId}/status`, 'offline', { retain: true });
    logger.info('[SIMULATOR] Shutting down...');
    client.end(() => process.exit(0));
  });
});

// Echo relay commands as state confirmations (simulates ESP32 behavior)
client.on('message', (topic, message) => {
  const parts = topic.split('/');
  if (parts[5] === 'set' || parts[4] === 'set') {
    try {
      const relayId = parseInt(parts[4], 10);
      const payload = JSON.parse(message.toString());
      relayStates[relayId] = payload.state;

      const stateTopic = `home/${userId}/${deviceId}/relay/${relayId}/state`;
      client.publish(stateTopic, JSON.stringify({ relayId, state: payload.state }), { qos: 1 });
      logger.mqtt(`[SIMULATOR] Relay ${relayId} → ${payload.state ? 'ON' : 'OFF'} (echoed)`);
    } catch (e) {
      logger.error(`[SIMULATOR] Failed to parse relay command: ${e.message}`);
    }
  }
});

client.on('error', (err) => {
  logger.error(`[SIMULATOR] MQTT error: ${err.message}`);
});

client.on('reconnect', () => {
  logger.warn('[SIMULATOR] Reconnecting...');
});

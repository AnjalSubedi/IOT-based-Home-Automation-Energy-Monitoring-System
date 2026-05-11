/**
 * telemetryHandler.js — Processes incoming telemetry from ESP32.
 *
 * Topic: home/{userId}/{deviceId}/telemetry
 * Payload: { deviceId, voltage, current, power, frequency, powerFactor, timestamp }
 *
 * Steps:
 *  1. Validate device exists and belongs to userId
 *  2. Store reading in MongoDB
 *  3. Check device power threshold → create alert if exceeded
 *  4. Run automation rules
 *  5. Emit live_reading event to Flutter via Socket.IO
 */

const Device = require('../../models/Device');
const EnergyReading = require('../../models/EnergyReading');
const Alert = require('../../models/Alert');
const { evaluateRules } = require('../../services/automationService');
const { emitToUser, emitToDevice } = require('../../sockets/socketManager');
const { calcPower } = require('../../utils/energyCalc');
const logger = require('../../utils/logger');

const handleTelemetry = async (userId, deviceId, payload) => {
  try {
    // ── 1. Parse payload ────────────────────────────────────────────────────
    const { voltage, current, power, frequency, powerFactor, timestamp } = payload;

    // Guard against NaN/missing values
    const safeNum = (val, fallback = 0) =>
      typeof val === 'number' && isFinite(val) ? val : fallback;

    const v = safeNum(voltage);
    const i = safeNum(current);
    const pf = safeNum(powerFactor, 1.0);
    // Use reported power if valid, else compute from V×I×PF
    const p = safeNum(power) || calcPower(v, i, pf);

    // ── 2. Verify device + mark online ──────────────────────────────────────
    const device = await Device.findOneAndUpdate(
      { deviceId, userId },
      { isOnline: true, lastSeenAt: new Date() },
      { new: true }
    );
    if (!device) {
      logger.warn(`Telemetry from unregistered device: ${deviceId} (userId: ${userId})`);
      return;
    }

    // Emit online status if device was previously offline
    if (!device.isOnline) {
      const statusEvent = { deviceId, isOnline: true, lastSeenAt: device.lastSeenAt, timestamp: new Date() };
      emitToUser(userId.toString(), 'device_status', statusEvent);
      emitToDevice(deviceId, 'device_status', statusEvent);
    }

    // ── 3. Store reading ────────────────────────────────────────────────────
    const reading = await EnergyReading.create({
      deviceId,
      userId,
      voltage: v,
      current: i,
      power: p,
      frequency: safeNum(frequency, 50),
      powerFactor: Math.min(1, Math.max(0, pf)),
      deviceTimestamp: timestamp ? new Date(timestamp) : null,
    });

    // ── 4. Check power threshold alert ──────────────────────────────────────
    if (device.powerThreshold && p > device.powerThreshold) {
      const alert = await Alert.create({
        userId,
        deviceId,
        type: 'HIGH_POWER',
        message: `Power usage ${p.toFixed(0)}W exceeded threshold of ${device.powerThreshold}W`,
        value: p,
        threshold: device.powerThreshold,
      });
      emitToUser(userId.toString(), 'new_alert', alert);
      logger.warn(`High power alert: ${deviceId} → ${p.toFixed(0)}W`);
    }

    // ── 5. Evaluate automation rules ────────────────────────────────────────
    await evaluateRules(reading, userId);

    // ── 6. Emit live data to Flutter ────────────────────────────────────────
    const liveData = {
      deviceId,
      voltage: v,
      current: i,
      power: p,
      frequency: safeNum(frequency, 50),
      powerFactor: pf,
      timestamp: reading.createdAt,
    };

    emitToUser(userId.toString(), 'live_reading', liveData);
    emitToDevice(deviceId, 'live_reading', liveData);

    logger.mqtt(
      `Telemetry stored: ${deviceId} → V:${v.toFixed(1)} I:${i.toFixed(2)} P:${p.toFixed(1)}W`
    );
  } catch (err) {
    logger.error(`telemetryHandler error: ${err.message}`);
  }
};

module.exports = { handleTelemetry };

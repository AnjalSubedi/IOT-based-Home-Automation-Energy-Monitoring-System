/**
 * automationService.js — Evaluate automation rules against new readings.
 *
 * Called by telemetryHandler.js on every new reading.
 * Checks device's active rules, fires relay commands or alerts if matched.
 * Respects cooldown period to avoid alert spam.
 */

const AutomationRule = require('../models/AutomationRule');
const Alert = require('../models/Alert');
const Relay = require('../models/Relay');
const { mqttPublish } = require('../config/mqtt');
const { emitToUser } = require('../sockets/socketManager');
const logger = require('../utils/logger');

/**
 * Evaluate a condition against a reading value.
 * @param {Object} condition - { field, operator, value }
 * @param {Object} reading   - EnergyReading document
 * @returns {boolean}
 */
const evaluateCondition = (condition, reading) => {
  const actual = reading[condition.field];
  if (actual === undefined || actual === null) return false;

  switch (condition.operator) {
    case 'gt':  return actual > condition.value;
    case 'lt':  return actual < condition.value;
    case 'gte': return actual >= condition.value;
    case 'lte': return actual <= condition.value;
    case 'eq':  return actual === condition.value;
    default:    return false;
  }
};

/**
 * Run all active rules for a device against the latest reading.
 * @param {Object} reading   - Saved EnergyReading document
 * @param {string} userId    - Owner's user ID
 */
const evaluateRules = async (reading, userId) => {
  try {
    const rules = await AutomationRule.find({
      deviceId: reading.deviceId,
      userId,
      isActive: true,
    });

    for (const rule of rules) {
      // Check cooldown
      if (rule.lastTriggeredAt) {
        const elapsedSec = (Date.now() - new Date(rule.lastTriggeredAt).getTime()) / 1000;
        if (elapsedSec < rule.cooldownSeconds) continue;
      }

      if (!evaluateCondition(rule.condition, reading)) continue;

      logger.info(`Rule triggered: "${rule.label}" for device ${reading.deviceId}`);

      // ── Fire action ────────────────────────────────────────────────────────
      if (rule.action.type === 'RELAY_CONTROL') {
        const topic = `home/${userId}/${reading.deviceId}/relay/${rule.action.relayId}/set`;
        mqttPublish(topic, { relayId: rule.action.relayId, state: rule.action.state });

        // Update relay state in DB
        await Relay.findOneAndUpdate(
          { deviceId: reading.deviceId, relayId: rule.action.relayId },
          { state: rule.action.state, lastChangedBy: 'automation', lastChangedAt: new Date() },
          { upsert: true }
        );

        emitToUser(userId.toString(), 'relay_state', {
          deviceId: reading.deviceId,
          relayId: rule.action.relayId,
          state: rule.action.state,
          changedBy: 'automation',
          rule: rule.label,
          timestamp: new Date(),
        });
      }

      if (rule.action.type === 'SEND_ALERT') {
        const alert = await Alert.create({
          userId,
          deviceId: reading.deviceId,
          type: rule.action.alertType || 'CUSTOM',
          message: rule.action.message || `Rule "${rule.label}" triggered`,
          value: reading[rule.condition.field],
          threshold: rule.condition.value,
        });

        emitToUser(userId.toString(), 'new_alert', alert);
      }

      // Update last triggered time
      rule.lastTriggeredAt = new Date();
      await rule.save();
    }
  } catch (err) {
    logger.error(`evaluateRules error: ${err.message}`);
  }
};

module.exports = { evaluateRules };

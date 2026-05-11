/**
 * AutomationRule.js — Automation rule model.
 *
 * Rules are evaluated on every incoming telemetry reading.
 * Example rules:
 *   - If power > 3000W → turn off relay 2
 *   - If voltage < 180V → send HIGH_POWER alert
 *   - If current > 15A → send alert
 */

const mongoose = require('mongoose');

const conditionSchema = new mongoose.Schema(
  {
    field: {
      type: String,
      enum: ['power', 'voltage', 'current', 'frequency', 'powerFactor'],
      required: true,
    },
    operator: {
      type: String,
      enum: ['gt', 'lt', 'gte', 'lte', 'eq'],
      required: true,
    },
    value: {
      type: Number,
      required: true,
    },
  },
  { _id: false }
);

const actionSchema = new mongoose.Schema(
  {
    type: {
      type: String,
      enum: ['RELAY_CONTROL', 'SEND_ALERT'],
      required: true,
    },
    // For RELAY_CONTROL
    relayId: { type: Number, min: 1, max: 4 },
    state: { type: Boolean }, // true = ON, false = OFF
    // For SEND_ALERT
    alertType: {
      type: String,
      enum: ['HIGH_POWER', 'VOLTAGE_SPIKE', 'LOW_VOLTAGE', 'CUSTOM'],
    },
    message: { type: String },
  },
  { _id: false }
);

const automationRuleSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    deviceId: {
      type: String,
      required: true,
    },
    label: {
      type: String,
      default: 'My Rule',
    },
    condition: {
      type: conditionSchema,
      required: true,
    },
    action: {
      type: actionSchema,
      required: true,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    // Prevent alert spam — cooldown period in seconds
    cooldownSeconds: {
      type: Number,
      default: 300, // 5 minutes
    },
    lastTriggeredAt: {
      type: Date,
      default: null,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('AutomationRule', automationRuleSchema);

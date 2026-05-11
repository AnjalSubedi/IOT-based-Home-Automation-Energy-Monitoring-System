/**
 * Alert.js — Alert model for high-usage and anomaly notifications.
 *
 * Alerts are created by:
 *  - automationService.js (rule-based triggers)
 *  - telemetryHandler.js (threshold exceeded)
 *  - statusHandler.js (device offline)
 *
 * Real-time delivery to Flutter is via Socket.IO.
 * Alerts are also stored here for the Alerts screen history.
 */

const mongoose = require('mongoose');

const alertSchema = new mongoose.Schema(
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
    type: {
      type: String,
      enum: ['HIGH_POWER', 'VOLTAGE_SPIKE', 'LOW_VOLTAGE', 'DEVICE_OFFLINE', 'CUSTOM'],
      required: true,
    },
    message: {
      type: String,
      required: true,
    },
    // The actual reading value that triggered the alert
    value: {
      type: Number,
      default: null,
    },
    // The threshold that was exceeded
    threshold: {
      type: Number,
      default: null,
    },
    isRead: {
      type: Boolean,
      default: false,
      index: true,
    },
  },
  { timestamps: true }
);

alertSchema.index({ userId: 1, createdAt: -1 });

module.exports = mongoose.model('Alert', alertSchema);

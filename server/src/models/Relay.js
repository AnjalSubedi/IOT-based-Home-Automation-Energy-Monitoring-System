/**
 * Relay.js — Per-relay current state model.
 *
 * Tracks the ON/OFF state of each relay channel (1-4) per device.
 * Updated when:
 *  - User sends control command (backend → MQTT → ESP32)
 *  - ESP32 publishes state confirmation (MQTT → backend)
 */

const mongoose = require('mongoose');

const relaySchema = new mongoose.Schema(
  {
    deviceId: {
      type: String,
      required: true,
      index: true,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    relayId: {
      type: Number,
      required: true,
      min: 1,
      max: 4,
    },
    state: {
      type: Boolean,
      default: false, // false = OFF, true = ON
    },
    applianceName: {
      type: String,
      default: 'Appliance',
    },
    // User-defined appliance label (shown in the app)
    label: {
      type: String,
      default: null,
    },
    // Track who last changed the state
    lastChangedBy: {
      type: String,
      enum: ['user', 'schedule', 'automation', 'device'],
      default: 'user',
    },
    lastChangedAt: {
      type: Date,
      default: Date.now,
    },
  },
  { timestamps: true }
);

// Compound index: one state record per relay per device
relaySchema.index({ deviceId: 1, relayId: 1 }, { unique: true });

module.exports = mongoose.model('Relay', relaySchema);

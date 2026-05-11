/**
 * EnergyReading.js — Telemetry reading model.
 *
 * Stores raw sensor readings from ESP32 per telemetry publish.
 * NOTE: energyKWh totals are NOT stored here per-reading.
 *       Backend's energyService.js computes cumulative kWh from
 *       consecutive readings using P × ΔT, so totals survive ESP32 reboots.
 */

const mongoose = require('mongoose');

const energyReadingSchema = new mongoose.Schema(
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
      index: true,
    },
    voltage: {
      type: Number,
      required: true,
      min: 0,
    },
    current: {
      type: Number,
      required: true,
      min: 0,
    },
    power: {
      type: Number,
      required: true,
      min: 0,
    },
    frequency: {
      type: Number,
      default: 50, // Nepal uses 50 Hz
    },
    powerFactor: {
      type: Number,
      default: 1.0,
      min: 0,
      max: 1,
    },
    // Raw timestamp from ESP32 (may differ from server time)
    deviceTimestamp: {
      type: Date,
      default: null,
    },
  },
  {
    // createdAt = server-side timestamp used for energy calculations
    timestamps: true,
  }
);

// Index for efficient time-range queries (history, graphs)
energyReadingSchema.index({ deviceId: 1, createdAt: -1 });
energyReadingSchema.index({ userId: 1, createdAt: -1 });

module.exports = mongoose.model('EnergyReading', energyReadingSchema);

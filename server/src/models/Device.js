/**
 * Device.js — ESP32 device registration model.
 *
 * Each device has a unique deviceId and deviceSecret used for:
 *  - MQTT client ID verification (ESP32 uses deviceId_deviceSecret as clientId)
 *  - Pairing validation on the backend
 *
 * deviceSecret is generated on registration and never exposed in MQTT topics.
 */

const mongoose = require('mongoose');

const relayInfoSchema = new mongoose.Schema(
  {
    relayId: { type: Number, required: true, min: 1, max: 4 },
    applianceName: { type: String, default: 'Appliance' },
    gpioPin: { type: Number }, // optional metadata
  },
  { _id: false }
);

const deviceSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    deviceId: {
      type: String,
      required: [true, 'deviceId is required'],
      trim: true,
      // e.g., "esp32-001" — unique per user, not globally
    },
    deviceSecret: {
      type: String,
      required: true,
      select: false, // Hidden from normal queries — returned only on initial registration
    },
    name: {
      type: String,
      default: 'My ESP32 Device',
      trim: true,
    },
    location: {
      type: String,
      default: 'Home',
      trim: true,
    },
    description: {
      type: String,
      default: '',
    },
    isOnline: {
      type: Boolean,
      default: false,
    },
    lastSeenAt: {
      type: Date,
      default: null,
    },
    // Relay metadata: which relays exist and what appliances they control
    relays: {
      type: [relayInfoSchema],
      default: [
        { relayId: 1, applianceName: 'Appliance 1' },
        { relayId: 2, applianceName: 'Appliance 2' },
        { relayId: 3, applianceName: 'Appliance 3' },
        { relayId: 4, applianceName: 'Appliance 4' },
      ],
    },
    // Alert threshold in watts — backend fires alert if power exceeds this
    powerThreshold: {
      type: Number,
      default: 2000, // 2000W default
    },
  },
  { timestamps: true }
);

// One user cannot register the same deviceId twice,
// but different users CAN use the same physical ESP32 ID
deviceSchema.index({ userId: 1, deviceId: 1 }, { unique: true });

module.exports = mongoose.model('Device', deviceSchema);

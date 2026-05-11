/**
 * deviceController.js — Device management (CRUD + pairing).
 *
 * Each device gets a unique deviceSecret (UUID) on creation.
 * The deviceSecret is returned ONLY on the initial POST /api/devices response.
 * ESP32 uses: clientId = "{deviceId}_{deviceSecret}" when connecting to MQTT.
 * Backend verifies incoming MQTT data is from a registered device.
 */

const { v4: uuidv4 } = require('uuid');
const { body } = require('express-validator');
const Device = require('../models/Device');
const Relay = require('../models/Relay');
const logger = require('../utils/logger');

// ─── Validation ────────────────────────────────────────────────────────────────
const deviceValidation = [
  body('deviceId')
    .trim()
    .notEmpty()
    .withMessage('deviceId is required')
    .matches(/^[a-zA-Z0-9-_]+$/)
    .withMessage('deviceId can only contain letters, numbers, hyphens, and underscores'),
  body('name').optional().trim().isLength({ max: 100 }),
  body('location').optional().trim().isLength({ max: 100 }),
];

// ─── List Devices ─────────────────────────────────────────────────────────────
// @route   GET /api/devices
// @access  Private
const getDevices = async (req, res) => {
  try {
    const devices = await Device.find({ userId: req.user._id }).sort({ createdAt: -1 });
    res.status(200).json({ success: true, count: devices.length, data: devices });
  } catch (err) {
    logger.error(`getDevices error: ${err.message}`);
    res.status(500).json({ success: false, message: 'Failed to fetch devices' });
  }
};

// ─── Get Single Device ────────────────────────────────────────────────────────
// @route   GET /api/devices/:deviceId
// @access  Private
const getDevice = async (req, res) => {
  try {
    const device = await Device.findOne({
      deviceId: req.params.deviceId,
      userId: req.user._id,
    });

    if (!device) {
      return res.status(404).json({ success: false, message: 'Device not found' });
    }

    // Fetch current relay states
    const relays = await Relay.find({ deviceId: req.params.deviceId });

    res.status(200).json({ success: true, data: { ...device.toObject(), relayStates: relays } });
  } catch (err) {
    logger.error(`getDevice error: ${err.message}`);
    res.status(500).json({ success: false, message: 'Failed to fetch device' });
  }
};

// ─── Add Device ───────────────────────────────────────────────────────────────
// @route   POST /api/devices
// @access  Private
const addDevice = async (req, res) => {
  try {
    const { deviceId, name, location, description, relays } = req.body;

    // Check duplicate
    const existing = await Device.findOne({ deviceId });
    if (existing) {
      return res.status(400).json({ success: false, message: 'deviceId already registered' });
    }

    const deviceSecret = uuidv4(); // This is the pairing secret

    const device = await Device.create({
      userId: req.user._id,
      deviceId,
      deviceSecret,
      name: name || `ESP32 (${deviceId})`,
      location: location || 'Home',
      description: description || '',
      relays: relays || undefined, // use schema defaults if not provided
    });

    // Initialize relay state documents (all OFF) for 4 relays
    const relayDocs = [1, 2, 3, 4].map((id) => ({
      deviceId,
      userId: req.user._id,
      relayId: id,
      state: false,
      applianceName:
        device.relays.find((r) => r.relayId === id)?.applianceName || `Appliance ${id}`,
    }));
    await Relay.insertMany(relayDocs);

    logger.success(`Device registered: ${deviceId} by user ${req.user.email}`);

    // Return deviceSecret ONLY on initial registration — used to configure ESP32 firmware
    res.status(201).json({
      success: true,
      message: 'Device registered. Copy the deviceSecret — it will not be shown again.',
      data: {
        ...device.toObject(),
        deviceSecret, // expose only here
      },
    });
  } catch (err) {
    logger.error(`addDevice error: ${err.message}`);
    res.status(500).json({ success: false, message: 'Failed to register device' });
  }
};

// ─── Update Device ────────────────────────────────────────────────────────────
// @route   PUT /api/devices/:deviceId
// @access  Private
const updateDevice = async (req, res) => {
  try {
    const allowedFields = ['name', 'location', 'description', 'powerThreshold', 'relays'];
    const updates = {};
    allowedFields.forEach((f) => {
      if (req.body[f] !== undefined) updates[f] = req.body[f];
    });

    const device = await Device.findOneAndUpdate(
      { deviceId: req.params.deviceId, userId: req.user._id },
      updates,
      { new: true, runValidators: true }
    );

    if (!device) {
      return res.status(404).json({ success: false, message: 'Device not found' });
    }

    res.status(200).json({ success: true, data: device });
  } catch (err) {
    logger.error(`updateDevice error: ${err.message}`);
    res.status(500).json({ success: false, message: 'Failed to update device' });
  }
};

// ─── Delete Device ────────────────────────────────────────────────────────────
// @route   DELETE /api/devices/:deviceId
// @access  Private
const deleteDevice = async (req, res) => {
  try {
    const device = await Device.findOneAndDelete({
      deviceId: req.params.deviceId,
      userId: req.user._id,
    });

    if (!device) {
      return res.status(404).json({ success: false, message: 'Device not found' });
    }

    // Clean up relay states
    await Relay.deleteMany({ deviceId: req.params.deviceId });

    logger.info(`Device deleted: ${req.params.deviceId}`);
    res.status(200).json({ success: true, message: 'Device removed' });
  } catch (err) {
    logger.error(`deleteDevice error: ${err.message}`);
    res.status(500).json({ success: false, message: 'Failed to delete device' });
  }
};

module.exports = {
  getDevices,
  getDevice,
  addDevice,
  updateDevice,
  deleteDevice,
  deviceValidation,
};

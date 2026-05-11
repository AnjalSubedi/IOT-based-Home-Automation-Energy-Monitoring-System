/**
 * relayController.js — Relay control via MQTT.
 *
 * When Flutter user taps ON/OFF:
 *  1. API receives request
 *  2. Backend publishes MQTT command to HiveMQ
 *  3. ESP32 receives command, switches GPIO, publishes state confirmation
 *  4. Backend receives state confirmation → updates DB → emits Socket.IO event
 *
 * Optimistic update: relay state in DB is set immediately on command,
 * then confirmed/corrected when ESP32 publishes state back.
 */

const Relay = require('../models/Relay');
const Device = require('../models/Device');
const { mqttPublish } = require('../config/mqtt');
const { getIO } = require('../sockets/socketManager');
const logger = require('../utils/logger');

// ─── Control Relay ────────────────────────────────────────────────────────────
// @route   POST /api/devices/:deviceId/relays/:relayId/control
// @access  Private
// @body    { state: true/false }
const controlRelay = async (req, res) => {
  try {
    const { deviceId, relayId } = req.params;
    const { state } = req.body;

    if (typeof state !== 'boolean') {
      return res.status(400).json({ success: false, message: '`state` must be a boolean (true/false)' });
    }

    const relayNum = parseInt(relayId, 10);
    if (isNaN(relayNum) || relayNum < 1 || relayNum > 4) {
      return res.status(400).json({ success: false, message: 'relayId must be 1–4' });
    }

    // ── 1. Publish MQTT command instantly (no DB wait) ─────────────────────
    const topic = `home/${req.user._id}/${deviceId}/relay/${relayNum}/set`;
    mqttPublish(topic, { relayId: relayNum, state });

    // ── 2. Emit socket event instantly so Flutter UI confirms ──────────────
    const io = getIO();
    if (io) {
      io.to(`user_${req.user._id}`).emit('relay_state', {
        deviceId,
        relayId: relayNum,
        state,
        changedBy: 'user',
        timestamp: new Date(),
      });
    }

    logger.info(`Relay ${relayNum} on ${deviceId} → ${state ? 'ON' : 'OFF'} (by user)`);

    // ── 3. Respond immediately ─────────────────────────────────────────────
    res.status(200).json({ success: true, message: `Relay ${relayNum} command sent` });

    // ── 4. Update DB in background (no await — doesn't block response) ─────
    Relay.findOneAndUpdate(
      { deviceId, relayId: relayNum },
      { state, lastChangedBy: 'user', lastChangedAt: new Date() },
      { new: true, upsert: true }
    ).catch((err) => logger.error(`Relay DB update failed: ${err.message}`));

  } catch (err) {
    logger.error(`controlRelay error: ${err.message}`);
    res.status(500).json({ success: false, message: 'Failed to control relay' });
  }
};

// ─── Get All Relay States for a Device ────────────────────────────────────────
// @route   GET /api/devices/:deviceId/relays
// @access  Private
const getRelayStates = async (req, res) => {
  try {
    const { deviceId } = req.params;

    const device = await Device.findOne({ deviceId, userId: req.user._id });
    if (!device) {
      return res.status(404).json({ success: false, message: 'Device not found' });
    }

    const relays = await Relay.find({ deviceId }).sort({ relayId: 1 });
    res.status(200).json({ success: true, data: relays });
  } catch (err) {
    logger.error(`getRelayStates error: ${err.message}`);
    res.status(500).json({ success: false, message: 'Failed to fetch relay states' });
  }
};

// ─── Update Relay Label (User-defined appliance name) ─────────────────────────
// @route   PUT /api/devices/:deviceId/relays/:relayId
// @access  Private
// @body    { label: 'Living Room Light' }
const updateRelayLabel = async (req, res) => {
  try {
    const { deviceId, relayId } = req.params;
    const { label } = req.body;

    const device = await Device.findOne({ deviceId, userId: req.user._id });
    if (!device) {
      return res.status(404).json({ success: false, message: 'Device not found' });
    }

    const relay = await Relay.findOneAndUpdate(
      { deviceId, relayId: parseInt(relayId, 10) },
      { label },
      { new: true, upsert: true }
    );

    res.status(200).json({ success: true, data: relay });
  } catch (err) {
    logger.error(`updateRelayLabel error: ${err.message}`);
    res.status(500).json({ success: false, message: 'Failed to update label' });
  }
};

module.exports = { controlRelay, getRelayStates, updateRelayLabel };

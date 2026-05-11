/**
 * energyController.js — Energy data API endpoints.
 *
 * Provides:
 *  - Latest reading for a device
 *  - Historical readings (with time filters)
 *  - Summary: daily / weekly / monthly energy (kWh) and cost
 *
 * Energy kWh is calculated by energyService.js from stored readings,
 * NOT from ESP32's in-memory accumulator (which resets on reboot).
 */

const EnergyReading = require('../models/EnergyReading');
const Device = require('../models/Device');
const energyService = require('../services/energyService');
const logger = require('../utils/logger');

// ─── Get Latest Reading ────────────────────────────────────────────────────────
// @route   GET /api/devices/:deviceId/latest
// @access  Private
const getLatest = async (req, res) => {
  try {
    const { deviceId } = req.params;

    // Ensure device belongs to this user
    const device = await Device.findOne({ deviceId, userId: req.user._id });
    if (!device) {
      return res.status(404).json({ success: false, message: 'Device not found' });
    }

    const reading = await EnergyReading.findOne({ deviceId }).sort({ createdAt: -1 });

    if (!reading) {
      return res.status(200).json({ success: true, data: null, message: 'No readings yet' });
    }

    res.status(200).json({ success: true, data: reading });
  } catch (err) {
    logger.error(`getLatest error: ${err.message}`);
    res.status(500).json({ success: false, message: 'Failed to fetch latest reading' });
  }
};

// ─── Get History ──────────────────────────────────────────────────────────────
// @route   GET /api/devices/:deviceId/history
// @access  Private
// @query   from (ISO date), to (ISO date), limit (default 100)
const getHistory = async (req, res) => {
  try {
    const { deviceId } = req.params;
    const { from, to, limit = 100 } = req.query;

    const device = await Device.findOne({ deviceId, userId: req.user._id });
    if (!device) {
      return res.status(404).json({ success: false, message: 'Device not found' });
    }

    const filter = { deviceId };
    if (from || to) {
      filter.createdAt = {};
      if (from) filter.createdAt.$gte = new Date(from);
      if (to) filter.createdAt.$lte = new Date(to);
    }

    const readings = await EnergyReading.find(filter)
      .sort({ createdAt: -1 })
      .limit(parseInt(limit));

    res.status(200).json({
      success: true,
      count: readings.length,
      data: readings,
    });
  } catch (err) {
    logger.error(`getHistory error: ${err.message}`);
    res.status(500).json({ success: false, message: 'Failed to fetch history' });
  }
};

// ─── Get Summary ──────────────────────────────────────────────────────────────
// @route   GET /api/devices/:deviceId/summary
// @access  Private
// @query   period: today | week | month (default: today)
const getSummary = async (req, res) => {
  try {
    const { deviceId } = req.params;
    const { period = 'today' } = req.query;

    const device = await Device.findOne({ deviceId, userId: req.user._id });
    if (!device) {
      return res.status(404).json({ success: false, message: 'Device not found' });
    }

    const summary = await energyService.getSummary(deviceId, req.user._id, period);

    res.status(200).json({ success: true, data: summary });
  } catch (err) {
    logger.error(`getSummary error: ${err.message}`);
    res.status(500).json({ success: false, message: 'Failed to generate summary' });
  }
};

// ─── Get Graph Data ───────────────────────────────────────────────────────────
// @route   GET /api/devices/:deviceId/graph
// @access  Private
// @query   period: day | week | month
const getGraphData = async (req, res) => {
  try {
    const { deviceId } = req.params;
    const { period = 'day' } = req.query;

    const device = await Device.findOne({ deviceId, userId: req.user._id });
    if (!device) {
      return res.status(404).json({ success: false, message: 'Device not found' });
    }

    const graphData = await energyService.getGraphData(deviceId, period);

    res.status(200).json({ success: true, data: graphData });
  } catch (err) {
    logger.error(`getGraphData error: ${err.message}`);
    res.status(500).json({ success: false, message: 'Failed to generate graph data' });
  }
};

module.exports = { getLatest, getHistory, getSummary, getGraphData };

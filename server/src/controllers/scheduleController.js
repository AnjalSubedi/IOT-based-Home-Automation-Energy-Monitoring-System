/**
 * scheduleController.js — Appliance scheduling CRUD.
 *
 * Schedules are stored in MongoDB. scheduleService.js loads them and
 * registers node-cron jobs at server startup and after each change.
 */

const { body } = require('express-validator');
const Schedule = require('../models/Schedule');
const scheduleService = require('../services/scheduleService');
const Device = require('../models/Device');
const logger = require('../utils/logger');

// ─── Validation ────────────────────────────────────────────────────────────────
const scheduleValidation = [
  body('relayId').isInt({ min: 1, max: 4 }).withMessage('relayId must be 1–4'),
  body('action').isIn(['ON', 'OFF']).withMessage('action must be ON or OFF'),
  body('cronExpression').notEmpty().withMessage('cronExpression is required'),
  body('label').optional().trim().isLength({ max: 100 }),
];

// @route   POST /api/devices/:deviceId/schedules
// @access  Private
const addSchedule = async (req, res) => {
  try {
    const { deviceId } = req.params;

    const device = await Device.findOne({ deviceId, userId: req.user._id });
    if (!device) return res.status(404).json({ success: false, message: 'Device not found' });

    const schedule = await Schedule.create({
      userId: req.user._id,
      deviceId,
      relayId: req.body.relayId,
      action: req.body.action,
      cronExpression: req.body.cronExpression,
      label: req.body.label || 'My Schedule',
      isActive: true,
    });

    // Register the new cron job immediately
    scheduleService.registerJob(schedule);

    logger.info(`Schedule added: ${schedule.label} for ${deviceId}`);
    res.status(201).json({ success: true, data: schedule });
  } catch (err) {
    logger.error(`addSchedule error: ${err.message}`);
    res.status(500).json({ success: false, message: 'Failed to add schedule' });
  }
};

// @route   GET /api/devices/:deviceId/schedules
// @access  Private
const getSchedules = async (req, res) => {
  try {
    const schedules = await Schedule.find({
      deviceId: req.params.deviceId,
      userId: req.user._id,
    }).sort({ createdAt: -1 });

    res.status(200).json({ success: true, count: schedules.length, data: schedules });
  } catch (err) {
    logger.error(`getSchedules error: ${err.message}`);
    res.status(500).json({ success: false, message: 'Failed to fetch schedules' });
  }
};

// @route   DELETE /api/schedules/:id
// @access  Private
const deleteSchedule = async (req, res) => {
  try {
    const schedule = await Schedule.findOneAndDelete({
      _id: req.params.id,
      userId: req.user._id,
    });

    if (!schedule) return res.status(404).json({ success: false, message: 'Schedule not found' });

    // Remove the cron job
    scheduleService.removeJob(schedule._id.toString());

    res.status(200).json({ success: true, message: 'Schedule deleted' });
  } catch (err) {
    logger.error(`deleteSchedule error: ${err.message}`);
    res.status(500).json({ success: false, message: 'Failed to delete schedule' });
  }
};

// @route   PUT /api/schedules/:id/toggle
// @access  Private
const toggleSchedule = async (req, res) => {
  try {
    const schedule = await Schedule.findOne({ _id: req.params.id, userId: req.user._id });
    if (!schedule) return res.status(404).json({ success: false, message: 'Schedule not found' });

    schedule.isActive = !schedule.isActive;
    await schedule.save();

    if (schedule.isActive) {
      scheduleService.registerJob(schedule);
    } else {
      scheduleService.removeJob(schedule._id.toString());
    }

    res.status(200).json({ success: true, data: schedule });
  } catch (err) {
    logger.error(`toggleSchedule error: ${err.message}`);
    res.status(500).json({ success: false, message: 'Failed to toggle schedule' });
  }
};

module.exports = { addSchedule, getSchedules, deleteSchedule, toggleSchedule, scheduleValidation };

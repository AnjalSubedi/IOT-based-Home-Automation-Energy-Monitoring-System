/**
 * ruleController.js — Automation rules CRUD.
 */

const { body } = require('express-validator');
const AutomationRule = require('../models/AutomationRule');
const Device = require('../models/Device');
const logger = require('../utils/logger');

const ruleValidation = [
  body('condition.field')
    .isIn(['power', 'voltage', 'current', 'frequency', 'powerFactor'])
    .withMessage('Invalid condition field'),
  body('condition.operator')
    .isIn(['gt', 'lt', 'gte', 'lte', 'eq'])
    .withMessage('Invalid operator'),
  body('condition.value').isNumeric().withMessage('Condition value must be a number'),
  body('action.type').isIn(['RELAY_CONTROL', 'SEND_ALERT']).withMessage('Invalid action type'),
];

// @route   POST /api/devices/:deviceId/rules
// @access  Private
const addRule = async (req, res) => {
  try {
    const { deviceId } = req.params;
    const device = await Device.findOne({ deviceId, userId: req.user._id });
    if (!device) return res.status(404).json({ success: false, message: 'Device not found' });

    const rule = await AutomationRule.create({
      userId: req.user._id,
      deviceId,
      label: req.body.label || 'My Rule',
      condition: req.body.condition,
      action: req.body.action,
      cooldownSeconds: req.body.cooldownSeconds || 300,
    });

    res.status(201).json({ success: true, data: rule });
  } catch (err) {
    logger.error(`addRule error: ${err.message}`);
    res.status(500).json({ success: false, message: 'Failed to add rule' });
  }
};

// @route   GET /api/devices/:deviceId/rules
// @access  Private
const getRules = async (req, res) => {
  try {
    const rules = await AutomationRule.find({
      deviceId: req.params.deviceId,
      userId: req.user._id,
    });
    res.status(200).json({ success: true, count: rules.length, data: rules });
  } catch (err) {
    logger.error(`getRules error: ${err.message}`);
    res.status(500).json({ success: false, message: 'Failed to fetch rules' });
  }
};

// @route   DELETE /api/rules/:id
// @access  Private
const deleteRule = async (req, res) => {
  try {
    const rule = await AutomationRule.findOneAndDelete({
      _id: req.params.id,
      userId: req.user._id,
    });
    if (!rule) return res.status(404).json({ success: false, message: 'Rule not found' });
    res.status(200).json({ success: true, message: 'Rule deleted' });
  } catch (err) {
    logger.error(`deleteRule error: ${err.message}`);
    res.status(500).json({ success: false, message: 'Failed to delete rule' });
  }
};

module.exports = { addRule, getRules, deleteRule, ruleValidation };

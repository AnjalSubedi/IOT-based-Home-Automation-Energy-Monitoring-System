/**
 * alertController.js — Alert management.
 */

const Alert = require('../models/Alert');
const logger = require('../utils/logger');

// @route   GET /api/devices/:deviceId/alerts
// @access  Private
const getAlerts = async (req, res) => {
  try {
    const { deviceId } = req.params;
    const { unreadOnly, limit = 50 } = req.query;

    const filter = { userId: req.user._id, deviceId };
    if (unreadOnly === 'true') filter.isRead = false;

    const alerts = await Alert.find(filter)
      .sort({ createdAt: -1 })
      .limit(parseInt(limit));

    res.status(200).json({ success: true, count: alerts.length, data: alerts });
  } catch (err) {
    logger.error(`getAlerts error: ${err.message}`);
    res.status(500).json({ success: false, message: 'Failed to fetch alerts' });
  }
};

// @route   GET /api/alerts  (all devices)
// @access  Private
const getAllAlerts = async (req, res) => {
  try {
    const { unreadOnly, limit = 50 } = req.query;
    const filter = { userId: req.user._id };
    if (unreadOnly === 'true') filter.isRead = false;

    const alerts = await Alert.find(filter).sort({ createdAt: -1 }).limit(parseInt(limit));
    res.status(200).json({ success: true, count: alerts.length, data: alerts });
  } catch (err) {
    logger.error(`getAllAlerts error: ${err.message}`);
    res.status(500).json({ success: false, message: 'Failed to fetch alerts' });
  }
};

// @route   PUT /api/alerts/:id/read
// @access  Private
const markRead = async (req, res) => {
  try {
    const alert = await Alert.findOneAndUpdate(
      { _id: req.params.id, userId: req.user._id },
      { isRead: true },
      { new: true }
    );
    if (!alert) return res.status(404).json({ success: false, message: 'Alert not found' });
    res.status(200).json({ success: true, data: alert });
  } catch (err) {
    logger.error(`markRead error: ${err.message}`);
    res.status(500).json({ success: false, message: 'Failed to update alert' });
  }
};

// @route   PUT /api/alerts/read-all
// @access  Private
const markAllRead = async (req, res) => {
  try {
    await Alert.updateMany({ userId: req.user._id, isRead: false }, { isRead: true });
    res.status(200).json({ success: true, message: 'All alerts marked as read' });
  } catch (err) {
    logger.error(`markAllRead error: ${err.message}`);
    res.status(500).json({ success: false, message: 'Failed to update alerts' });
  }
};

module.exports = { getAlerts, getAllAlerts, markRead, markAllRead };

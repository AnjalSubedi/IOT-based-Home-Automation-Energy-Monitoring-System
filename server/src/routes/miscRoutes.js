/**
 * tariffRoutes.js
 * alertRoutes.js (standalone — alerts across all devices + mark-read)
 */

const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const { getTariff, updateTariff } = require('../controllers/tariffController');
const { getAllAlerts, markRead, markAllRead } = require('../controllers/alertController');
const { deleteSchedule, toggleSchedule } = require('../controllers/scheduleController');
const { deleteRule } = require('../controllers/ruleController');

router.use(protect);

// Tariff
router.get('/tariff', getTariff);
router.put('/tariff', updateTariff);

// Analytics summary (cross-device, used by Cost screen)
router.get('/analytics/summary', async (req, res) => {
  try {
    const energyService = require('../services/energyService');
    const Device = require('../models/Device');
    const devices = await Device.find({ userId: req.user._id });
    if (!devices.length) {
      return res.status(200).json({ success: true, data: {} });
    }
    // Aggregate across all user devices
    const deviceId = devices[0].deviceId; // primary device
    const [day, month, year] = await Promise.all([
      energyService.getSummary(deviceId, req.user._id, 'today'),
      energyService.getSummary(deviceId, req.user._id, 'month'),
      energyService.getSummary(deviceId, req.user._id, 'year'),
    ]);
    res.status(200).json({
      success: true,
      data: {
        todayKWh:  day?.totalKWh   ?? 0,
        monthKWh:  month?.totalKWh ?? 0,
        yearKWh:   year?.totalKWh  ?? 0,
        peakPowerW: day?.peakPower  ?? 0,
        hourlyKWh: day?.graphData  ?? [],
        dailyKWh:  month?.graphData ?? [],
      },
    });
  } catch (err) {
    res.status(500).json({ success: false, message: 'Failed to load analytics' });
  }
});


// Alerts (cross-device)
router.get('/alerts', getAllAlerts);
router.put('/alerts/read-all', markAllRead);
router.put('/alerts/:id/read', markRead);

// Schedules (delete by ID across devices)
router.delete('/schedules/:id', deleteSchedule);
router.put('/schedules/:id/toggle', toggleSchedule);

// Rules (delete by ID across devices)
router.delete('/rules/:id', deleteRule);

module.exports = router;

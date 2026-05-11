/**
 * deviceRoutes.js — All device-related routes.
 *
 * Base: /api/devices
 */

const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const { validate } = require('../middleware/validate');

const {
  getDevices, getDevice, addDevice, updateDevice, deleteDevice, deviceValidation,
} = require('../controllers/deviceController');

const { controlRelay, getRelayStates } = require('../controllers/relayController');
const { getLatest, getHistory, getSummary, getGraphData } = require('../controllers/energyController');
const { getAlerts } = require('../controllers/alertController');
const {
  addSchedule, getSchedules, deleteSchedule, toggleSchedule, scheduleValidation,
} = require('../controllers/scheduleController');
const { addRule, getRules, deleteRule, ruleValidation } = require('../controllers/ruleController');

// All routes require authentication
router.use(protect);

// ── Device CRUD ───────────────────────────────────────────────────────────────
router.get('/', getDevices);
router.post('/', deviceValidation, validate, addDevice);
router.get('/:deviceId', getDevice);
router.put('/:deviceId', updateDevice);
router.delete('/:deviceId', deleteDevice);

// ── Relay Control ─────────────────────────────────────────────────────────────
router.get('/:deviceId/relays', getRelayStates);
router.post('/:deviceId/relays/:relayId/control', controlRelay);
router.put('/:deviceId/relays/:relayId', require('../controllers/relayController').updateRelayLabel);


// ── Energy ────────────────────────────────────────────────────────────────────
router.get('/:deviceId/latest', getLatest);
router.get('/:deviceId/history', getHistory);
router.get('/:deviceId/summary', getSummary);
router.get('/:deviceId/graph', getGraphData);

// ── Alerts ────────────────────────────────────────────────────────────────────
router.get('/:deviceId/alerts', getAlerts);

// ── Schedules ─────────────────────────────────────────────────────────────────
router.post('/:deviceId/schedules', scheduleValidation, validate, addSchedule);
router.get('/:deviceId/schedules', getSchedules);

// ── Automation Rules ──────────────────────────────────────────────────────────
router.post('/:deviceId/rules', ruleValidation, validate, addRule);
router.get('/:deviceId/rules', getRules);

module.exports = router;

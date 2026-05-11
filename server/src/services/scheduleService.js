/**
 * scheduleService.js — Dynamic cron-based appliance scheduler.
 *
 * Loads all active schedules from DB at startup.
 * Registers/unregisters node-cron jobs dynamically as schedules are added/removed.
 * On trigger: publishes MQTT command + updates relay state in DB.
 */

const cron = require('node-cron');
const Schedule = require('../models/Schedule');
const Relay = require('../models/Relay');
const { mqttPublish } = require('../config/mqtt');
const { emitToUser } = require('../sockets/socketManager');
const logger = require('../utils/logger');

// Map of scheduleId → cron.ScheduledTask
const jobs = new Map();

/**
 * Execute a schedule: publish MQTT + update DB.
 * @param {Object} schedule - Schedule document
 */
const executeSchedule = async (schedule) => {
  try {
    const state = schedule.action === 'ON';
    const topic = `home/${schedule.userId}/${schedule.deviceId}/relay/${schedule.relayId}/set`;

    mqttPublish(topic, { relayId: schedule.relayId, state });

    // Update relay state in DB
    await Relay.findOneAndUpdate(
      { deviceId: schedule.deviceId, relayId: schedule.relayId },
      { state, lastChangedBy: 'schedule', lastChangedAt: new Date() },
      { upsert: true }
    );

    // Update lastTriggeredAt on schedule
    await Schedule.findByIdAndUpdate(schedule._id, { lastTriggeredAt: new Date() });

    emitToUser(schedule.userId.toString(), 'relay_state', {
      deviceId: schedule.deviceId,
      relayId: schedule.relayId,
      state,
      changedBy: 'schedule',
      scheduleLabel: schedule.label,
      timestamp: new Date(),
    });

    logger.info(
      `Schedule "${schedule.label}" triggered → Relay ${schedule.relayId} ${schedule.action} on ${schedule.deviceId}`
    );
  } catch (err) {
    logger.error(`executeSchedule error: ${err.message}`);
  }
};

/**
 * Register a cron job for a single schedule document.
 * @param {Object} schedule - Schedule document from MongoDB
 */
const registerJob = (schedule) => {
  const id = schedule._id.toString();

  // Remove existing job if any (prevents duplicates on update)
  if (jobs.has(id)) {
    jobs.get(id).stop();
    jobs.delete(id);
  }

  if (!schedule.isActive) return;

  if (!cron.validate(schedule.cronExpression)) {
    logger.warn(`Invalid cron expression for schedule ${id}: "${schedule.cronExpression}"`);
    return;
  }

  const task = cron.schedule(schedule.cronExpression, () => executeSchedule(schedule), {
    timezone: 'Asia/Kathmandu', // Nepal Standard Time (UTC+5:45)
  });

  jobs.set(id, task);
  logger.info(`Cron job registered: "${schedule.label}" [${schedule.cronExpression}]`);
};

/**
 * Remove a cron job by schedule ID.
 * @param {string} scheduleId
 */
const removeJob = (scheduleId) => {
  if (jobs.has(scheduleId)) {
    jobs.get(scheduleId).stop();
    jobs.delete(scheduleId);
    logger.info(`Cron job removed: ${scheduleId}`);
  }
};

/**
 * Load all active schedules from DB and register their cron jobs.
 * Call once at server startup.
 */
const loadAllSchedules = async () => {
  try {
    const schedules = await Schedule.find({ isActive: true });
    schedules.forEach(registerJob);
    logger.success(`Loaded ${schedules.length} active schedules`);
  } catch (err) {
    logger.error(`loadAllSchedules error: ${err.message}`);
  }
};

module.exports = { loadAllSchedules, registerJob, removeJob };

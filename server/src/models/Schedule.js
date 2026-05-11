/**
 * Schedule.js — Appliance scheduling model.
 *
 * Users can schedule relay ON/OFF at specific times.
 * scheduleService.js reads active schedules and registers node-cron jobs.
 *
 * cronExpression examples:
 *   "0 7 * * *"   → every day at 7:00 AM
 *   "30 22 * * *" → every day at 10:30 PM
 *   "0 8 * * 1-5" → weekdays at 8:00 AM
 */

const mongoose = require('mongoose');

const scheduleSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      index: true,
    },
    deviceId: {
      type: String,
      required: true,
    },
    relayId: {
      type: Number,
      required: true,
      min: 1,
      max: 4,
    },
    action: {
      type: String,
      enum: ['ON', 'OFF'],
      required: true,
    },
    // Standard cron expression (5 fields: min hour dom month dow)
    cronExpression: {
      type: String,
      required: true,
    },
    label: {
      type: String,
      default: 'My Schedule',
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    lastTriggeredAt: {
      type: Date,
      default: null,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Schedule', scheduleSchema);

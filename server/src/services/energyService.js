/**
 * energyService.js — Backend energy aggregation (source of truth).
 *
 * Does NOT trust ESP32's in-memory energy accumulator.
 * Instead, integrates P × ΔT across stored readings to compute kWh.
 * This correctly handles ESP32 reboots, gaps in data, etc.
 */

const EnergyReading = require('../models/EnergyReading');
const TariffSetting = require('../models/TariffSetting');
const { calcEnergyKWh, calcCost } = require('../utils/energyCalc');
const logger = require('../utils/logger');

/**
 * Compute total kWh from a sorted array of readings using trapezoidal integration.
 * @param {Array} readings - sorted ascending by createdAt
 * @returns {number} Total energy in kWh
 */
const integrateEnergyKWh = (readings) => {
  let totalKWh = 0;
  for (let i = 1; i < readings.length; i++) {
    const prev = readings[i - 1];
    const curr = readings[i];
    const deltaMs = new Date(curr.createdAt) - new Date(prev.createdAt);

    // Skip if gap > 10 minutes (device was offline — don't count phantom energy)
    if (deltaMs > 10 * 60 * 1000) continue;

    const avgPower = (prev.power + curr.power) / 2;
    totalKWh += calcEnergyKWh(avgPower, deltaMs);
  }
  return parseFloat(totalKWh.toFixed(4));
};

/**
 * Get date range for a named period.
 * @param {string} period - 'today' | 'week' | 'month'
 * @returns {{ from: Date, to: Date }}
 */
const getPeriodRange = (period) => {
  const now = new Date();
  const to = now;
  let from;

  switch (period) {
    case 'week':
      from = new Date(now);
      from.setDate(now.getDate() - 7);
      break;
    case 'month':
      from = new Date(now.getFullYear(), now.getMonth(), 1); // Start of month
      break;
    case 'today':
    default:
      from = new Date(now);
      from.setHours(0, 0, 0, 0); // Midnight today
      break;
  }

  return { from, to };
};

/**
 * Generate energy summary for a device + period.
 * Returns: totalKWh, avgPower, peakPower, estimatedCost, currency, period
 */
const getSummary = async (deviceId, userId, period = 'today') => {
  const { from, to } = getPeriodRange(period);

  const readings = await EnergyReading.find({
    deviceId,
    createdAt: { $gte: from, $lte: to },
  }).sort({ createdAt: 1 });

  if (readings.length === 0) {
    return { totalKWh: 0, avgPower: 0, peakPower: 0, estimatedCost: 0, currency: 'NPR', period, readingCount: 0 };
  }

  const totalKWh = integrateEnergyKWh(readings);
  const avgPower = parseFloat(
    (readings.reduce((sum, r) => sum + r.power, 0) / readings.length).toFixed(2)
  );
  const peakPower = parseFloat(Math.max(...readings.map((r) => r.power)).toFixed(2));

  // Get tariff for cost calculation
  const tariff = await TariffSetting.findOne({ userId });
  const estimatedCost = calcCost(totalKWh, tariff);
  const currency = tariff?.currency || 'NPR';

  return { totalKWh, avgPower, peakPower, estimatedCost, currency, period, readingCount: readings.length };
};

/**
 * Generate graph-ready data points.
 * Groups readings into time buckets (hourly for day, daily for week/month).
 * Returns array of { label, avgPower, totalKWh }
 */
const getGraphData = async (deviceId, period = 'day') => {
  const { from, to } = getPeriodRange(period === 'day' ? 'today' : period);

  const readings = await EnergyReading.find({
    deviceId,
    createdAt: { $gte: from, $lte: to },
  }).sort({ createdAt: 1 });

  if (readings.length === 0) return [];

  // Bucket by hour (for day) or by date (for week/month)
  const buckets = {};
  readings.forEach((r) => {
    const date = new Date(r.createdAt);
    let key;
    if (period === 'day') {
      key = `${String(date.getHours()).padStart(2, '0')}:00`;
    } else {
      key = date.toISOString().slice(0, 10); // YYYY-MM-DD
    }
    if (!buckets[key]) buckets[key] = [];
    buckets[key].push(r);
  });

  return Object.entries(buckets).map(([label, bucket]) => {
    const avgPower = parseFloat(
      (bucket.reduce((s, r) => s + r.power, 0) / bucket.length).toFixed(2)
    );
    const totalKWh = integrateEnergyKWh(bucket);
    return { label, avgPower, totalKWh };
  });
};

module.exports = { getSummary, getGraphData, integrateEnergyKWh, getPeriodRange };

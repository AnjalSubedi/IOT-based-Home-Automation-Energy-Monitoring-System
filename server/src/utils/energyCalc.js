/**
 * energyCalc.js — Pure energy and cost calculation functions.
 *
 * The backend is the single source of truth for energy totals.
 * ESP32 sends raw V, I, PF — power and cumulative kWh are computed here.
 */

/**
 * Calculate real power in Watts.
 * @param {number} voltage  - RMS voltage (V)
 * @param {number} current  - RMS current (A)
 * @param {number} pf       - Power factor (0–1), default 1.0
 * @returns {number} Power in Watts
 */
const calcPower = (voltage, current, pf = 1.0) => {
  return parseFloat((voltage * current * pf).toFixed(4));
};

/**
 * Calculate energy increment in kWh for a time window.
 * @param {number} powerW     - Power in Watts
 * @param {number} deltaMs    - Time elapsed in milliseconds
 * @returns {number} Energy increment in kWh
 */
const calcEnergyKWh = (powerW, deltaMs) => {
  const hours = deltaMs / 3600000; // ms → hours
  return parseFloat(((powerW * hours) / 1000).toFixed(6));
};

/**
 * Calculate electricity cost using NEA-style slab pricing.
 * Slabs are cumulative: first N units at rate A, next M units at rate B, etc.
 *
 * @param {number} totalKWh - Total energy consumed (kWh)
 * @param {Array}  slabs    - Array of { fromKWh, toKWh, ratePerKWh }
 *                            toKWh: null means "and above"
 * @returns {number} Total cost in configured currency (e.g., NPR)
 *
 * Example NEA slabs (2025):
 *   [
 *     { fromKWh: 0,   toKWh: 30,  ratePerKWh: 4    },
 *     { fromKWh: 30,  toKWh: 100, ratePerKWh: 8.50 },
 *     { fromKWh: 100, toKWh: 250, ratePerKWh: 11   },
 *     { fromKWh: 250, toKWh: 400, ratePerKWh: 12   },
 *     { fromKWh: 400, toKWh: null, ratePerKWh: 13  },
 *   ]
 */
const calcCostSlab = (totalKWh, slabs) => {
  if (!slabs || slabs.length === 0) return 0;

  // Sort slabs by fromKWh ascending
  const sorted = [...slabs].sort((a, b) => a.fromKWh - b.fromKWh);
  let cost = 0;
  let remaining = totalKWh;

  for (const slab of sorted) {
    if (remaining <= 0) break;

    const slabStart = slab.fromKWh;
    const slabEnd = slab.toKWh !== null && slab.toKWh !== undefined ? slab.toKWh : Infinity;
    const slabSize = slabEnd - slabStart;

    // How many kWh fall into this slab
    const unitsInSlab = Math.min(remaining, slabSize);
    cost += unitsInSlab * slab.ratePerKWh;
    remaining -= unitsInSlab;
  }

  return parseFloat(cost.toFixed(2));
};

/**
 * Flat-rate cost calculation (fallback if no slabs defined).
 * @param {number} totalKWh   - Total energy consumed (kWh)
 * @param {number} flatRate   - Rate per kWh
 * @returns {number} Total cost
 */
const calcCostFlat = (totalKWh, flatRate) => {
  return parseFloat((totalKWh * flatRate).toFixed(2));
};

/**
 * Calculate cost using tariff settings (slab or flat).
 * @param {number} totalKWh       - Total energy consumed
 * @param {Object} tariffSetting  - TariffSetting document from DB
 * @returns {number} Cost in configured currency
 */
const calcCost = (totalKWh, tariffSetting) => {
  if (!tariffSetting) return 0;

  if (tariffSetting.slabs && tariffSetting.slabs.length > 0) {
    return calcCostSlab(totalKWh, tariffSetting.slabs);
  }

  return calcCostFlat(totalKWh, tariffSetting.flatRate || 0);
};

module.exports = { calcPower, calcEnergyKWh, calcCostSlab, calcCostFlat, calcCost };

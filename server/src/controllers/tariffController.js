/**
 * tariffController.js — Per-user tariff settings management.
 *
 * GET /api/tariff     → fetch current tariff for logged-in user
 * PUT /api/tariff     → update tariff (slabs and/or flat rate)
 *
 * Default NEA slabs are seeded on user registration (authController.js).
 */

const TariffSetting = require('../models/TariffSetting');
const logger = require('../utils/logger');

// @route   GET /api/tariff
// @access  Private
const getTariff = async (req, res) => {
  try {
    let tariff = await TariffSetting.findOne({ userId: req.user._id });

    // Should always exist (created on register), but create as fallback
    if (!tariff) {
      tariff = await TariffSetting.create({ userId: req.user._id });
    }

    res.status(200).json({ success: true, data: tariff });
  } catch (err) {
    logger.error(`getTariff error: ${err.message}`);
    res.status(500).json({ success: false, message: 'Failed to fetch tariff settings' });
  }
};

// @route   PUT /api/tariff
// @access  Private
// @body    { slabs: [...], flatRate: number, currency: string, fixedMonthlyCharge: number }
const updateTariff = async (req, res) => {
  try {
    const { slabs, flatRate, currency, fixedMonthlyCharge } = req.body;

    const updates = {};
    if (slabs !== undefined) updates.slabs = slabs;
    if (flatRate !== undefined) updates.flatRate = flatRate;
    if (currency !== undefined) updates.currency = currency;
    if (fixedMonthlyCharge !== undefined) updates.fixedMonthlyCharge = fixedMonthlyCharge;

    const tariff = await TariffSetting.findOneAndUpdate(
      { userId: req.user._id },
      updates,
      { new: true, upsert: true, runValidators: true }
    );

    logger.info(`Tariff updated for user ${req.user.email}`);
    res.status(200).json({ success: true, data: tariff });
  } catch (err) {
    logger.error(`updateTariff error: ${err.message}`);
    res.status(500).json({ success: false, message: 'Failed to update tariff settings' });
  }
};

module.exports = { getTariff, updateTariff };

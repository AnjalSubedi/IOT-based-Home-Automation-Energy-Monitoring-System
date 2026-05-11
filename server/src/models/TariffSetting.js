/**
 * TariffSetting.js — Per-user electricity tariff configuration.
 *
 * Supports slab-based pricing (NEA-style) and flat-rate fallback.
 * Editable from the Flutter Settings screen via PUT /api/tariff.
 *
 * Default slabs pre-seeded to approximate NEA 2025 rates (NPR):
 *   0–30 units:   NPR  4.00/kWh
 *   30–100 units: NPR  8.50/kWh
 *   100–250 units: NPR 11.00/kWh
 *   250–400 units: NPR 12.00/kWh
 *   400+  units:   NPR 13.00/kWh
 *
 * NOTE: These are approximate. Update from the app for accurate billing.
 */

const mongoose = require('mongoose');

const slabSchema = new mongoose.Schema(
  {
    fromKWh: { type: Number, required: true, min: 0 },
    toKWh: { type: Number, default: null }, // null = "and above"
    ratePerKWh: { type: Number, required: true, min: 0 },
    label: { type: String, default: '' }, // e.g., "0–30 units"
  },
  { _id: false }
);

const tariffSettingSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true, // One tariff setting per user
    },
    // Slab-based rates (NEA style)
    slabs: {
      type: [slabSchema],
      default: [
        { fromKWh: 0,   toKWh: 30,   ratePerKWh: 4.00,  label: '0–30 units'    },
        { fromKWh: 30,  toKWh: 100,  ratePerKWh: 8.50,  label: '30–100 units'  },
        { fromKWh: 100, toKWh: 250,  ratePerKWh: 11.00, label: '100–250 units' },
        { fromKWh: 250, toKWh: 400,  ratePerKWh: 12.00, label: '250–400 units' },
        { fromKWh: 400, toKWh: null, ratePerKWh: 13.00, label: '400+ units'    },
      ],
    },
    // Flat rate fallback — used if slabs array is empty
    flatRate: {
      type: Number,
      default: 10.0, // NPR 10/kWh
    },
    currency: {
      type: String,
      default: 'NPR',
    },
    // Monthly fixed charge (service charge, meter rent) — added to monthly bill
    fixedMonthlyCharge: {
      type: Number,
      default: 0,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('TariffSetting', tariffSettingSchema);

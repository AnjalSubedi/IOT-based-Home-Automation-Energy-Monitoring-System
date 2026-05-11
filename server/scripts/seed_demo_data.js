/**
 * seed_demo_data.js
 * Inserts realistic energy readings for TODAY so the app shows
 * meaningful "Today's Energy", "Today's Cost", and power stats.
 *
 * Run: node scripts/seed_demo_data.js
 */

require('dotenv').config();
const mongoose = require('mongoose');
const EnergyReading = require('../src/models/EnergyReading');

const DEVICE_ID = 'esp32-001';
const USER_ID   = '69fd83e90e7350a06d14f459';

// Readings every 5 minutes from 06:00 UTC → 17:30 UTC today
// (11:45 AM → 11:15 PM Nepal time) — a realistic active day
const INTERVAL_MS = 5 * 60 * 1000; // 5 minutes

// Power profile (Watts) — simulates a Nepali household
// Varies by hour (UTC): lights, fans, charging, cooking, TV, etc.
function getPower(hourUTC) {
  const profiles = {
    6:  () => rand(60,  120),   // 11:45 AM Nepal — morning light usage
    7:  () => rand(100, 180),   // lunch prep, fans on
    8:  () => rand(120, 220),   // peak afternoon
    9:  () => rand(150, 250),   // fans + charging
    10: () => rand(180, 300),   // heavy afternoon
    11: () => rand(200, 312),   // peak (multiple appliances)
    12: () => rand(160, 280),   // post-lunch dip
    13: () => rand(140, 240),   // afternoon
    14: () => rand(120, 200),   // quieter period
    15: () => rand(150, 260),   // picking up
    16: () => rand(200, 310),   // evening prep
    17: () => rand(180, 290),   // evening  
  };
  return (profiles[hourUTC] || (() => rand(80, 150)))();
}

function rand(min, max) {
  return parseFloat((Math.random() * (max - min) + min).toFixed(1));
}

async function seed() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('MongoDB connected');

  // Clear today's readings for this device
  const todayStart = new Date();
  todayStart.setUTCHours(0, 0, 0, 0);

  const deleted = await EnergyReading.deleteMany({
    deviceId: DEVICE_ID,
    createdAt: { $gte: todayStart },
  });
  console.log(`Cleared ${deleted.deletedCount} old readings for today`);

  // Generate readings from 06:00 UTC to 17:30 UTC
  const start = new Date(todayStart);
  start.setUTCHours(6, 0, 0, 0);

  const end = new Date(todayStart);
  end.setUTCHours(17, 30, 0, 0);

  const readings = [];
  let ts = new Date(start);

  while (ts <= end) {
    const power     = getPower(ts.getUTCHours());
    const voltage   = rand(218, 235);
    const current   = parseFloat((power / voltage).toFixed(3));
    const pf        = rand(0.88, 0.98);
    const frequency = rand(49.8, 50.2);

    readings.push({
      deviceId:    DEVICE_ID,
      userId:      USER_ID,
      voltage,
      current,
      power,
      energy:      0,   // server recalculates via integration
      frequency,
      powerFactor: pf,
      createdAt:   new Date(ts),
      updatedAt:   new Date(ts),
    });

    ts = new Date(ts.getTime() + INTERVAL_MS);
  }

  await EnergyReading.insertMany(readings);
  console.log(`✅ Inserted ${readings.length} readings`);

  // Preview what the summary will show
  const totalMs = end - start;
  const totalH  = totalMs / 3600000;
  const powers  = readings.map(r => r.power);
  const avgPow  = parseFloat((powers.reduce((a,b) => a+b,0)/powers.length).toFixed(1));
  const peakPow = parseFloat(Math.max(...powers).toFixed(1));

  // Rough kWh estimate (trapezoid)
  let kWh = 0;
  for (let i = 1; i < readings.length; i++) {
    const dt  = (new Date(readings[i].createdAt) - new Date(readings[i-1].createdAt)) / 3600000;
    kWh += ((readings[i].power + readings[i-1].power) / 2) * dt / 1000;
  }
  kWh = parseFloat(kWh.toFixed(3));
  const costNPR = parseFloat((kWh * 13).toFixed(2)); // NEA basic rate ~NPR 13/kWh

  console.log('\n📊 Expected app display:');
  console.log(`   Today's Energy : ${kWh} kWh`);
  console.log(`   Today's Cost   : NPR ${costNPR}`);
  console.log(`   Avg Power      : ${avgPow} W`);
  console.log(`   Peak Power     : ${peakPow} W`);
  console.log(`   Readings       : ${readings.length}`);

  await mongoose.disconnect();
  console.log('\nDone! Open the app and pull-to-refresh on the dashboard.');
}

seed().catch(err => { console.error(err); process.exit(1); });

/**
 * push_demo_alert.js
 * Inserts a demo alert into the DB.
 * The running server will pick it up and push to the app via socket.
 *
 * Run: node scripts/push_demo_alert.js
 */

require('dotenv').config();
const mongoose = require('mongoose');
const Alert    = require('../src/models/Alert');
const http     = require('http');

const USER_ID   = '69fd83e90e7350a06d14f459';
const DEVICE_ID = 'esp32-001';

// Demo alerts — cycle through these for different screenshots
const ALERTS = [
  {
    type:      'HIGH_POWER',
    message:   '⚠️ Potential short circuit in Boiler! Current spike of 18.4 A detected. Check immediately.',
    value:     18.4,
    threshold: 10,
  },
  {
    type:      'VOLTAGE_SPIKE',
    message:   '⚡ Voltage spike detected: 268 V (threshold: 250 V). Boiler circuit may be at risk.',
    value:     268,
    threshold: 250,
  },
  {
    type:      'HIGH_POWER',
    message:   '🔴 High power usage alert! Power consumption reached 1840 W — exceeds safe limit.',
    value:     1840,
    threshold: 1500,
  },
];

async function run() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('MongoDB connected');

  // Insert ALL demo alerts (unread)
  const created = await Alert.insertMany(
    ALERTS.map(a => ({ userId: USER_ID, deviceId: DEVICE_ID, isRead: false, ...a }))
  );
  console.log(`✅ Inserted ${created.length} demo alerts`);

  // Try to notify the running server via its internal API
  // (works if server is running on port 5000)
  const triggerSocket = () => new Promise((resolve) => {
    const req = http.request(
      { hostname: 'localhost', port: 5000, path: '/health', method: 'GET' },
      (res) => {
        console.log('\n📱 Server is running — open the Alerts tab in the app to see the notifications.');
        console.log('   (The app badge counter should also increment.)');
        resolve();
      }
    );
    req.on('error', () => {
      console.log('\n⚠️  Server not running. Start it with: node server.js');
      console.log('   Alerts are saved to DB — they will appear when you open the app.');
      resolve();
    });
    req.end();
  });

  await triggerSocket();

  console.log('\nAlerts created:');
  created.forEach((a, i) => console.log(`  ${i+1}. [${a.type}] ${a.message.slice(0,60)}...`));

  await mongoose.disconnect();
  console.log('\nDone! Pull-to-refresh on the Alerts screen.');
}

run().catch(err => { console.error(err); process.exit(1); });

/**
 * One-time migration: link esp32-001 to ALL existing users who have no device.
 * Run with: node scripts/link_default_device.js
 */
require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const mongoose = require('mongoose');
const crypto   = require('crypto');
const User     = require('../src/models/User');
const Device   = require('../src/models/Device');

const DEFAULT_DEVICE_ID   = process.env.DEFAULT_DEVICE_ID   || 'esp32-001';
const DEFAULT_DEVICE_NAME = process.env.DEFAULT_DEVICE_NAME || 'Home Monitor';

async function run() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('✅ MongoDB connected');

  // Drop the old global unique index on deviceId (if it exists)
  try {
    await mongoose.connection.collection('devices').dropIndex('deviceId_1');
    console.log('✅ Dropped old global unique index on deviceId');
  } catch (e) {
    console.log('ℹ️  No old index to drop (already clean)');
  }

  const users = await User.find({});
  console.log(`Found ${users.length} users`);

  let linked = 0;
  for (const user of users) {
    const existing = await Device.findOne({ userId: user._id });
    if (!existing) {
      try {
        await Device.create({
          userId:       user._id,
          deviceId:     DEFAULT_DEVICE_ID,
          deviceSecret: crypto.randomBytes(16).toString('hex'),
          name:         DEFAULT_DEVICE_NAME,
          location:     'Home',
        });
        console.log(`  ✅ Linked ${DEFAULT_DEVICE_ID} → ${user.email}`);
        linked++;
      } catch (err) {
        if (err.code === 11000) {
          console.log(`  ⏭️  ${user.email} already has this device`);
        } else {
          console.error(`  ❌ Failed for ${user.email}: ${err.message}`);
        }
      }
    } else {
      console.log(`  ⏭️  ${user.email} already has device: ${existing.deviceId}`);
    }
  }

  console.log(`\n✅ Done — linked ${linked} users to ${DEFAULT_DEVICE_ID}`);
  await mongoose.disconnect();
  process.exit(0);
}

run().catch(err => { console.error(err); process.exit(1); });

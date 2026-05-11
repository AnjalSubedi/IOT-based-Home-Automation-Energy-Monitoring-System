require('dotenv').config({ path: require('path').join(__dirname, '../.env') });
const mongoose = require('mongoose');
const User     = require('../src/models/User');
const Device   = require('../src/models/Device');

mongoose.connect(process.env.MONGO_URI).then(async () => {
  const users = await User.find({}, '_id name email');
  console.log('\n=== YOUR USERS ===');
  for (const u of users) {
    const device = await Device.findOne({ userId: u._id }, 'deviceId deviceSecret');
    console.log('Name       :', u.name);
    console.log('Email      :', u.email);
    console.log('USER_ID    :', u._id.toString());
    if (device) {
      console.log('DEVICE_ID  :', device.deviceId);
      console.log('DEVICE_SECRET:', device.deviceSecret);
    }
    console.log('---');
  }
  mongoose.disconnect();
}).catch(e => { console.error(e); process.exit(1); });

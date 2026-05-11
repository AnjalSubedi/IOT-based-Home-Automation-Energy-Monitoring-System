require('dotenv').config();
const mongoose = require('mongoose');
const Alert = require('../src/models/Alert');

mongoose.connect(process.env.MONGO_URI).then(async () => {
  // Keep only the 3 most recent (the demo ones)
  const keep = await Alert.find({ userId: '69fd83e90e7350a06d14f459' })
    .sort({ createdAt: -1 })
    .limit(3)
    .select('_id message');

  const keepIds = keep.map(a => a._id);
  console.log('Keeping:');
  keep.forEach(a => console.log(' -', a.message.slice(0, 70)));

  // Delete everything else
  const result = await Alert.deleteMany({
    userId: '69fd83e90e7350a06d14f459',
    _id: { $nin: keepIds },
  });

  console.log('\nDeleted', result.deletedCount, 'old alert(s)');
  console.log('Done! Pull-to-refresh on the Alerts tab.');
  await mongoose.disconnect();
}).catch(err => { console.error(err); process.exit(1); });

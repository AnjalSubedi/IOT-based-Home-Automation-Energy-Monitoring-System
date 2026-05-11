const mongoose = require('mongoose');

const readingSchema = mongoose.Schema({
    voltage: {
        type: Number,
        required: [true, 'Please add a voltage value'],
    },
    current: {
        type: Number,
        required: [true, 'Please add a current value'],
    },
    power: {
        type: Number,
        required: [true, 'Please add a power value'],
    },
    energy: {
        type: Number,
        required: [true, 'Please add an energy value'],
    },
    frequency: {
        type: Number,
        required: [true, 'Please add a frequency value'],
    },
    powerFactor: {
        type: Number,
        required: [true, 'Please add a power factor value'],
    },
    deviceId: {
        type: String,
        default: 'esp32-001',
    },
    createdAt: {
        type: Date,
        default: Date.now,
    },
});

module.exports = mongoose.model('Reading', readingSchema);

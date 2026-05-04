const mongoose = require('mongoose');

const relayEventSchema = new mongoose.Schema({
    device_id: {
        type: String,
        required: true
    },
    relay1: {
        type: Number,
        required: true,
        enum: [0, 1]
    },
    source: {
        type: String,
        required: true,
        enum: ['web', 'esp32', 'unknown'],
        default: 'unknown'
    },
    created_at: {
        type: Date,
        default: Date.now
    }
});

module.exports = mongoose.model('RelayEvent', relayEventSchema);

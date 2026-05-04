const mongoose = require('mongoose');

const relayCommandSchema = new mongoose.Schema({
    device_id: {
        type: String,
        required: true,
        unique: true
    },
    relay1: {
        type: Number,
        required: true,
        enum: [0, 1],
        default: 0
    },
    updated_at: {
        type: Date,
        default: Date.now
    }
});

// Update the updated_at timestamp on save
relayCommandSchema.pre('save', function () {
    this.updated_at = Date.now();
});

module.exports = mongoose.model('RelayCommand', relayCommandSchema);

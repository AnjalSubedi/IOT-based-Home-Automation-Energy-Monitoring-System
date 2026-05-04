const express = require('express');
const router = express.Router();
const RelayCommand = require('../models/RelayCommand');
const RelayEvent = require('../models/RelayEvent');

// @desc    Get relay command for a device
// @route   GET /api/relay/:deviceId
router.get('/:deviceId', async (req, res) => {
    try {
        const { deviceId } = req.params;
        let command = await RelayCommand.findOne({ device_id: deviceId });

        if (!command) {
            // Default to OFF if no command exists
            command = new RelayCommand({ device_id: deviceId, relay1: 0 });
            await command.save();
        }

        res.status(200).json(command);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error' });
    }
});

// @desc    Update relay command (switch ON/OFF)
// @route   POST /api/relay/:deviceId
router.post('/:deviceId', async (req, res) => {
    try {
        const { deviceId } = req.params;
        const { relay1, source } = req.body;

        // Validation
        if (relay1 !== 0 && relay1 !== 1) {
            return res.status(400).json({ error: 'Invalid relay state. Must be 0 or 1.' });
        }

        // Upsert command
        const command = await RelayCommand.findOneAndUpdate(
            { device_id: deviceId },
            { relay1, updated_at: Date.now() },
            { returnDocument: 'after', upsert: true }
        );

        // Log event
        await RelayEvent.create({
            device_id: deviceId,
            relay1,
            source: source || 'unknown'
        });

        res.status(201).json(command);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error' });
    }
});

// @desc    Get relay event logs
// @route   GET /api/relay/:deviceId/events
router.get('/:deviceId/events', async (req, res) => {
    try {
        const { deviceId } = req.params;
        const limit = parseInt(req.query.limit) || 50;

        const events = await RelayEvent.find({ device_id: deviceId })
            .sort({ created_at: -1 })
            .limit(limit);

        res.status(200).json(events);
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: 'Server error' });
    }
});

module.exports = router;

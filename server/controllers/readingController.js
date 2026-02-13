const Reading = require('../models/Reading');

// @desc    Get readings (default limit 50)
// @route   GET /api/readings
// @access  Public
const getReadings = async (req, res) => {
    try {
        const limit = parseInt(req.query.limit) || 50;
        const deviceId = req.query.deviceId;

        let query = {};
        if (deviceId) {
            query.deviceId = deviceId;
        }

        const readings = await Reading.find(query)
            .sort({ createdAt: -1 })
            .limit(limit);

        res.status(200).json({
            success: true,
            count: readings.length,
            data: readings,
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Server Error',
            error: error.message,
        });
    }
};

// @desc    Get latest reading
// @route   GET /api/readings/latest
// @access  Public
const getLatestReading = async (req, res) => {
    try {
        const deviceId = req.query.deviceId;
        let query = {};
        if (deviceId) {
            query.deviceId = deviceId;
        }

        const reading = await Reading.findOne(query).sort({ createdAt: -1 });

        if (!reading) {
            return res.status(404).json({
                success: false,
                message: 'No readings found',
            });
        }

        res.status(200).json({
            success: true,
            data: reading,
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Server Error',
            error: error.message,
        });
    }
};

// @desc    Add new reading
// @route   POST /api/readings
// @access  Public
const addReading = async (req, res) => {
    try {
        const { voltage, current, power, energy, frequency, powerFactor, deviceId } = req.body;

        // Simple validation handled by Mongoose required fields, but explicit check here if needed
        if (voltage === undefined || current === undefined || power === undefined || energy === undefined || frequency === undefined || powerFactor === undefined) {
            return res.status(400).json({
                success: false,
                message: 'Please provide all required fields (voltage, current, power, energy, frequency, powerFactor)',
            });
        }

        const reading = await Reading.create({
            voltage,
            current,
            power,
            energy,
            frequency,
            powerFactor,
            deviceId,
        });

        res.status(201).json({
            success: true,
            data: reading,
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            message: 'Server Error',
            error: error.message,
        });
    }
};

// @desc    Delete all readings
// @route   DELETE /api/readings
// @access  Public (Testing only)
const deleteReadings = async (req, res) => {
    try {
        await Reading.deleteMany();
        res.status(200).json({
            success: true,
            message: 'All readings deleted',
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Server Error',
            error: error.message,
        });
    }
};

module.exports = {
    getReadings,
    getLatestReading,
    addReading,
    deleteReadings,
};

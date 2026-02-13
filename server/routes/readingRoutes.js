const express = require('express');
const router = express.Router();
const {
    getReadings,
    getLatestReading,
    addReading,
    deleteReadings,
} = require('../controllers/readingController');

router.route('/')
    .get(getReadings)
    .post(addReading)
    .delete(deleteReadings);

router.route('/latest')
    .get(getLatestReading);

module.exports = router;

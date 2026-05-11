/**
 * db.js — MongoDB connection via Mongoose.
 * Reads MONGO_URI from environment variables.
 */

const mongoose = require('mongoose');
const logger = require('../utils/logger');

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGO_URI, {
      // Mongoose 7+ does not need these flags, but kept for clarity
    });
    logger.success(`MongoDB connected: ${conn.connection.host}`);
  } catch (err) {
    logger.error(`MongoDB connection failed: ${err.message}`);
    process.exit(1); // Exit process on DB failure
  }
};

module.exports = connectDB;

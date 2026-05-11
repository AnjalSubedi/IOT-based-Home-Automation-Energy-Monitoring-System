/**
 * logger.js — Simple timestamp-prefixed console logger
 * Provides consistent log formatting across the entire backend.
 */

const colors = {
  reset: '\x1b[0m',
  info: '\x1b[36m',    // cyan
  warn: '\x1b[33m',    // yellow
  error: '\x1b[31m',   // red
  success: '\x1b[32m', // green
  mqtt: '\x1b[35m',    // magenta
};

const timestamp = () => new Date().toISOString();

const logger = {
  info: (msg, ...args) =>
    console.log(`${colors.info}[INFO]${colors.reset} ${timestamp()} — ${msg}`, ...args),

  warn: (msg, ...args) =>
    console.warn(`${colors.warn}[WARN]${colors.reset} ${timestamp()} — ${msg}`, ...args),

  error: (msg, ...args) =>
    console.error(`${colors.error}[ERROR]${colors.reset} ${timestamp()} — ${msg}`, ...args),

  success: (msg, ...args) =>
    console.log(`${colors.success}[OK]${colors.reset} ${timestamp()} — ${msg}`, ...args),

  mqtt: (msg, ...args) =>
    console.log(`${colors.mqtt}[MQTT]${colors.reset} ${timestamp()} — ${msg}`, ...args),
};

module.exports = logger;

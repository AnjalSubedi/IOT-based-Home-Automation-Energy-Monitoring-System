/**
 * authController.js — Register and login handlers.
 *
 * POST /api/auth/register → create user + auto-create default TariffSetting
 * POST /api/auth/login    → verify credentials, return JWT
 */

const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { body } = require('express-validator');
const User = require('../models/User');
const Device = require('../models/Device');
const TariffSetting = require('../models/TariffSetting');
const logger = require('../utils/logger');

// ─── Generate JWT ──────────────────────────────────────────────────────────────
const generateToken = (userId) => {
  return jwt.sign({ id: userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRE || '30d',
  });
};

// ─── Validation Rules ──────────────────────────────────────────────────────────
const registerValidation = [
  body('name').trim().notEmpty().withMessage('Name is required'),
  body('email').isEmail().withMessage('Valid email is required').normalizeEmail(),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
];

const loginValidation = [
  body('email').isEmail().withMessage('Valid email is required').normalizeEmail(),
  body('password').notEmpty().withMessage('Password is required'),
];

// ─── Register ─────────────────────────────────────────────────────────────────
// @route   POST /api/auth/register
// @access  Public
const register = async (req, res) => {
  try {
    const { name, email, password } = req.body;

    // Create user — MongoDB unique index on email handles duplicates instantly
    const user = await User.create({ name, email, password });

    // Auto-create default tariff settings — fire and don't await (non-blocking)
    TariffSetting.create({ userId: user._id }).catch(err =>
      logger.warn(`Tariff auto-create failed for ${email}: ${err.message}`)
    );

    // Auto-link the default ESP32 device — every new user gets the house monitor
    const defaultDeviceId = process.env.DEFAULT_DEVICE_ID;
    if (defaultDeviceId) {
      Device.create({
        userId:       user._id,
        deviceId:     defaultDeviceId,
        deviceSecret: crypto.randomBytes(16).toString('hex'),
        name:         process.env.DEFAULT_DEVICE_NAME || 'Home Monitor',
        location:     'Home',
      }).catch(err => {
        // Code 11000 = duplicate (user already has this device) — safe to ignore
        if (err.code !== 11000) {
          logger.warn(`Device auto-link failed for ${email}: ${err.message}`);
        }
      });
    }

    logger.success(`New user registered: ${email}`);

    res.status(201).json({
      success: true,
      token: generateToken(user._id),
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
      },
    });
  } catch (err) {
    // MongoDB duplicate key error — email already registered
    if (err.code === 11000) {
      return res.status(400).json({ success: false, message: 'Email already registered' });
    }
    logger.error(`Register error: ${err.message}`);
    res.status(500).json({ success: false, message: 'Server error during registration' });
  }
};

// ─── Login ────────────────────────────────────────────────────────────────────
// @route   POST /api/auth/login
// @access  Public
const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find user and include password for comparison
    const user = await User.findOne({ email }).select('+password');
    if (!user) {
      return res.status(401).json({ success: false, message: 'Invalid email or password' });
    }

    const isMatch = await user.matchPassword(password);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Invalid email or password' });
    }

    logger.info(`User logged in: ${email}`);

    res.status(200).json({
      success: true,
      token: generateToken(user._id),
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
      },
    });
  } catch (err) {
    logger.error(`Login error: ${err.message}`);
    res.status(500).json({ success: false, message: 'Server error during login' });
  }
};

// ─── Get current user (me) ────────────────────────────────────────────────────
// @route   GET /api/auth/me
// @access  Private
const getMe = async (req, res) => {
  res.status(200).json({
    success: true,
    user: {
      id: req.user._id,
      name: req.user.name,
      email: req.user.email,
    },
  });
};

module.exports = { register, login, getMe, registerValidation, loginValidation };

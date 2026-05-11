/**
 * auth.js — JWT authentication middleware.
 *
 * Protects routes by verifying the Bearer token in Authorization header.
 * Attaches the decoded user payload to req.user.
 *
 * Usage: router.get('/protected', protect, controller)
 */

const jwt = require('jsonwebtoken');
const User = require('../models/User');
const logger = require('../utils/logger');

const protect = async (req, res, next) => {
  let token;

  // Extract token from Authorization: Bearer <token>
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer ')) {
    token = req.headers.authorization.split(' ')[1];
  }

  if (!token) {
    return res.status(401).json({ success: false, message: 'Not authorized — no token provided' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Use JWT claims directly — no DB lookup needed.
    // jwt.verify() already proves the token is authentic and unexpired.
    // Hitting MongoDB here was causing 10-15s latency on every request.
    req.user = {
      _id:   decoded.id,
      email: decoded.email,
      name:  decoded.name,
    };

    next();
  } catch (err) {
    logger.warn(`JWT verification failed: ${err.message}`);
    return res.status(401).json({ success: false, message: 'Not authorized — invalid token' });
  }
};

module.exports = { protect };

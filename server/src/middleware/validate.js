/**
 * validate.js — express-validator error handler middleware.
 *
 * Use after validation chains to catch and return validation errors.
 *
 * Usage:
 *   router.post('/', [body('email').isEmail(), validate], controller)
 */

const { validationResult } = require('express-validator');

const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: errors.array().map((e) => ({ field: e.path, message: e.msg })),
    });
  }
  next();
};

module.exports = { validate };

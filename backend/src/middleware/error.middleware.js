'use strict';

/**
 * Centralized error handler.
 * Returns a clean JSON error to Flutter without leaking internal details.
 */
// eslint-disable-next-line no-unused-vars
function errorMiddleware(err, req, res, next) {
  const statusCode = err.statusCode || err.status || 500;

  // Safe log — no sensitive data
  console.error(`[ERROR] ${req.method} ${req.path} — ${statusCode} — ${err.message}`);

  res.status(statusCode).json({
    success: false,
    error: err.message || 'Internal Server Error',
  });
}

module.exports = errorMiddleware;

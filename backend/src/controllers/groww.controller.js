'use strict';

const growwService = require('../services/groww.service');

/**
 * Helper: send Groww's response directly to Flutter.
 * Preserves Groww's original HTTP status code and body.
 */
function relay(res, growwResponse) {
  return res.status(growwResponse.status).json(growwResponse.data);
}

// ─── Token ────────────────────────────────────────────────────────────────────

/**
 * POST /v1/token/api/access
 *
 * Flutter sends:
 *   { "totp_token": "<GROWW_TOTP_TOKEN>", "totp_secret": "<GROWW_TOTP_SECRET>" }
 *
 * Backend generates the 6-digit TOTP internally, calls Groww, returns the access token.
 * Flutter does NOT need to compute any TOTP code.
 */
async function generateAccessToken(req, res, next) {
  try {
    const result = await growwService.generateAccessToken(req.headers, req.body);
    return relay(res, result);
  } catch (err) {
    next(err);
  }
}

// ─── Orders ───────────────────────────────────────────────────────────────────

/**
 * POST /v1/order/create
 * Bridges Groww order creation. Do NOT retry on failure.
 */
async function createOrder(req, res, next) {
  try {
    const result = await growwService.createOrder(req.headers, req.body);
    return relay(res, result);
  } catch (err) {
    next(err);
  }
}

/**
 * GET /v1/orders
 */
async function getOrders(req, res, next) {
  try {
    const result = await growwService.getOrders(req.headers, req.query);
    return relay(res, result);
  } catch (err) {
    next(err);
  }
}

/**
 * GET /v1/order/detail/:groww_order_id?segment=CASH
 * Get details of a specific order by Groww Order ID.
 *
 * Flutter call:
 *   GET /v1/order/detail/GMK123456?segment=CASH
 *   Header: Authorization: Bearer <ACCESS_TOKEN>
 */
async function getOrderById(req, res, next) {
  try {
    const result = await growwService.getOrderById(
      req.headers,
      req.params.groww_order_id,
      req.query
    );
    return relay(res, result);
  } catch (err) {
    next(err);
  }
}

/**
 * POST /v1/order/cancel
 * Cancel an existing open order.
 *
 * Flutter call:
 *   POST /v1/order/cancel
 *   Header: Authorization: Bearer <ACCESS_TOKEN>
 *   Body: { "groww_order_id": "GMK123456", "segment": "CASH" }
 *
 * Do NOT auto-retry — one cancel attempt only.
 */
async function cancelOrder(req, res, next) {
  try {
    const result = await growwService.cancelOrder(req.headers, req.body);
    return relay(res, result);
  } catch (err) {
    next(err);
  }
}

// ─── Portfolio ────────────────────────────────────────────────────────────────

/**
 * GET /v1/holdings
 */
async function getHoldings(req, res, next) {
  try {
    const result = await growwService.getHoldings(req.headers, req.query);
    return relay(res, result);
  } catch (err) {
    next(err);
  }
}

/**
 * GET /v1/positions
 */
async function getPositions(req, res, next) {
  try {
    const result = await growwService.getPositions(req.headers, req.query);
    return relay(res, result);
  } catch (err) {
    next(err);
  }
}

// ─── User ─────────────────────────────────────────────────────────────────────

/**
 * GET /v1/user/detail
 */
async function getUserDetails(req, res, next) {
  try {
    const result = await growwService.getUserDetails(req.headers);
    return relay(res, result);
  } catch (err) {
    next(err);
  }
}

// ─── IP Diagnostic ────────────────────────────────────────────────────────────

/**
 * GET /v1/my-ip
 * Returns backend server's outbound public IP.
 */
async function getMyIp(req, res, next) {
  try {
    const staticIp = await growwService.getPublicIp();
    return res.status(200).json({ success: true, staticIp });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  generateAccessToken,
  createOrder,
  getOrders,
  getOrderById,
  cancelOrder,
  getHoldings,
  getPositions,
  getUserDetails,
  getMyIp,
};


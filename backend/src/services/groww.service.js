'use strict';

const axios  = require('axios');
const http   = require('http');
const https  = require('https');
const crypto = require('crypto');
const { generateSync } = require('otplib');
const config = require('../config/env');

// Persistent keep-alive socket connections for low-latency forwarding
const httpAgent  = new http.Agent({ keepAlive: true, maxSockets: 50 });
const httpsAgent = new https.Agent({ keepAlive: true, maxSockets: 50 });

// TOTP options matching Groww (SHA-1, 6 digits, 30-second window)
const TOTP_OPTIONS = { algorithm: 'sha1', digits: 6, step: 30 };


/**
 * Build the safe header object to forward to Groww.
 * Only passes headers that Groww cares about — never logs Authorization.
 */
function buildGrowwHeaders(reqHeaders) {
  const headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-API-VERSION': reqHeaders['x-api-version'] || '1.0',
  };

  const auth = reqHeaders['authorization'];
  if (auth) {
    headers['Authorization'] = auth;
  }

  return headers;
}

/**
 * Core internal method — sends a request to the Groww API.
 */
async function callGroww(method, path, headers, data, params) {
  const url = `${config.growwBaseUrl}${path}`;
  const start = Date.now();

  console.log(`[GROWW] ${method} ${path}`);

  try {
    const response = await axios({
      url,
      method,
      headers: buildGrowwHeaders(headers),
      data: data && Object.keys(data).length > 0 ? data : undefined,
      params: params && Object.keys(params).length > 0 ? params : undefined,
      timeout: config.requestTimeoutMs,
      httpAgent,
      httpsAgent,
      validateStatus: () => true,
    });

    const duration = Date.now() - start;
    console.log(`[GROWW] Response: ${response.status} | Duration: ${duration}ms`);

    return { status: response.status, data: response.data };
  } catch (err) {
    const duration = Date.now() - start;
    if (err.code === 'ECONNABORTED' || err.code === 'ETIMEDOUT') {
      console.error(`[GROWW] Timeout after ${duration}ms — ${method} ${path}`);
      throw Object.assign(new Error('Groww API timed out'), { statusCode: 504 });
    }
    console.error(`[GROWW] Network error — ${method} ${path} — ${err.message}`);
    throw Object.assign(new Error(`Could not reach Groww API: ${err.message}`), { statusCode: 502 });
  }
}

// ─── Token ────────────────────────────────────────────────────────────────────

/**
 * Generate Groww Access Token.
 *
 * Flutter sends:
 *   POST /v1/token/api/access
 *   Body: { "totp_token": "<GROWW_TOTP_TOKEN>", "totp_secret": "<GROWW_TOTP_SECRET>" }
 *
 * Backend:
 *   1. Generates 6-digit TOTP from totp_secret internally.
 *   2. Calls Groww POST /v1/token/api/access with key_type=totp.
 *   3. If Groww rejects key_type=totp with "Invalid type", retries with key_type=approval (HMAC-SHA256 checksum).
 *   4. Returns Groww's raw response to Flutter.
 *
 * No token is stored anywhere.
 * totp_secret and totp_token are NEVER logged.
 */
async function generateAccessToken(reqHeaders, body) {
  const { totp_token, totp_secret } = body;

  if (!totp_token || totp_token.trim() === '') {
    throw Object.assign(new Error('totp_token is required'), { statusCode: 400 });
  }
  if (!totp_secret || totp_secret.trim() === '') {
    throw Object.assign(new Error('totp_secret is required'), { statusCode: 400 });
  }

  const token   = totp_token.trim();
  const secret  = totp_secret.trim();
  const path    = '/v1/token/api/access';
  const growwUrl = `${config.growwBaseUrl}${path}`;
  const start    = Date.now();

  // Build headers with totp_token as the Bearer token — never log it
  const headers = {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // ── Attempt 1: key_type = "totp" ────────────────────────────────────
  console.log('[GROWW TOKEN] Generating 6-digit TOTP internally...');
  let totpCode;
  try {
    totpCode = generateSync({ secret, ...TOTP_OPTIONS });
    console.log('[GROWW TOKEN] POST /v1/token/api/access (key_type=totp)');
  } catch (err) {
    throw Object.assign(
      new Error(`Failed to generate TOTP from provided secret: ${err.message}`),
      { statusCode: 400 }
    );
  }

  let response = await axios.post(
    growwUrl,
    { key_type: 'totp', totp: totpCode },
    { headers, timeout: config.requestTimeoutMs, httpAgent, httpsAgent, validateStatus: () => true }
  );

  console.log(`[GROWW TOKEN] Response: ${response.status} (key_type=totp) | Duration: ${Date.now() - start}ms`);

  // ── Attempt 2: key_type = "approval" (HMAC-SHA256) ──────────────────
  // Groww returns 400 with "Invalid type provided" when key_type=totp is not supported
  if (
    response.status === 400 &&
    JSON.stringify(response.data).toLowerCase().includes('invalid type')
  ) {
    console.log('[GROWW TOKEN] Retrying with key_type=approval (HMAC-SHA256 checksum)...');

    const timestamp = Math.floor(Date.now() / 1000).toString();
    const checksum  = crypto
      .createHmac('sha256', secret)
      .update(timestamp)
      .digest('hex');

    response = await axios.post(
      growwUrl,
      { key_type: 'approval', checksum, timestamp },
      { headers, timeout: config.requestTimeoutMs, httpAgent, httpsAgent, validateStatus: () => true }
    );

    console.log(`[GROWW TOKEN] Response: ${response.status} (key_type=approval) | Duration: ${Date.now() - start}ms`);
  }

  return { status: response.status, data: response.data };
}

// ─── Orders ───────────────────────────────────────────────────────────────────

async function createOrder(headers, body) {
  return callGroww('POST', '/v1/order/create', headers, body);
}

async function getOrders(headers, params) {
  return callGroww('GET', '/v1/orders', headers, undefined, params);
}

/**
 * Get details of a single order by its Groww Order ID.
 * GET /v1/order/detail/:groww_order_id?segment=CASH
 *
 * Flutter sends:
 *   GET /v1/order/detail/GMK123456?segment=CASH
 *   Header: Authorization: Bearer <ACCESS_TOKEN>
 */
async function getOrderById(headers, orderId, params) {
  if (!orderId) {
    throw Object.assign(new Error('groww_order_id is required'), { statusCode: 400 });
  }
  return callGroww('GET', `/v1/order/detail/${encodeURIComponent(orderId)}`, headers, undefined, params);
}

/**
 * Cancel an existing order.
 * POST /v1/order/cancel
 *
 * Flutter sends:
 *   POST /v1/order/cancel
 *   Header: Authorization: Bearer <ACCESS_TOKEN>
 *   Body: { "groww_order_id": "GMK123456", "segment": "CASH" }
 *
 * IMPORTANT: Do NOT auto-retry cancel — a duplicate cancel request is harmless
 * but duplicate order creation is not. Keep it consistent — no auto-retry.
 */
async function cancelOrder(headers, body) {
  if (!body.groww_order_id) {
    throw Object.assign(new Error('groww_order_id is required in request body'), { statusCode: 400 });
  }
  if (!body.segment) {
    throw Object.assign(new Error('segment is required in request body (e.g. CASH, FNO)'), { statusCode: 400 });
  }
  return callGroww('POST', '/v1/order/cancel', headers, body);
}

// ─── Portfolio ────────────────────────────────────────────────────────────────

async function getHoldings(headers, params) {
  return callGroww('GET', '/v1/holdings', headers, undefined, params);
}

async function getPositions(headers, params) {
  return callGroww('GET', '/v1/positions', headers, undefined, params);
}

// ─── User ─────────────────────────────────────────────────────────────────────

async function getUserDetails(headers) {
  return callGroww('GET', '/v1/user/detail', headers);
}

// ─── IP check (diagnostic only) ───────────────────────────────────────────────

async function getPublicIp() {
  const response = await axios.get('https://api.ipify.org?format=json', { timeout: 5000 });
  return response.data.ip;
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
  getPublicIp,
};

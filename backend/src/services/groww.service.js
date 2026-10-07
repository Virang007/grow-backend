'use strict';

const axios  = require('axios');
const http   = require('http');
const https  = require('https');
const crypto = require('crypto');
const config = require('../config/env');

// Persistent keep-alive socket connections for low-latency forwarding
const httpAgent  = new http.Agent({ keepAlive: true, maxSockets: 50 });
const httpsAgent = new https.Agent({ keepAlive: true, maxSockets: 50 });

/**
 * Pure Node.js zero-dependency TOTP Generator (SHA1, 6-digit, 30s step)
 * Replaces otplib to avoid Vercel Serverless ES Module incompatibility (ERR_REQUIRE_ESM).
 */
function base32Decode(base32Str) {
  const base32chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  let bits = '';
  let hex = '';
  const cleanStr = base32Str.replace(/=+$/, '').toUpperCase().trim();
  for (let i = 0; i < cleanStr.length; i++) {
    const val = base32chars.indexOf(cleanStr.charAt(i));
    if (val === -1) throw new Error(`Invalid Base32 character: ${cleanStr.charAt(i)}`);
    bits += val.toString(2).padStart(5, '0');
  }
  for (let i = 0; i + 8 <= bits.length; i += 8) {
    const chunk = bits.substr(i, 8);
    hex += parseInt(chunk, 2).toString(16).padStart(2, '0');
  }
  return Buffer.from(hex, 'hex');
}

function generateTOTP(secret, step = 30, digits = 6) {
  const key = base32Decode(secret);
  const epoch = Math.floor(Date.now() / 1000);
  const time = Buffer.alloc(8);
  time.writeBigInt64BE(BigInt(Math.floor(epoch / step)), 0);
  const hmac = crypto.createHmac('sha1', key).update(time).digest();
  const offset = hmac[hmac.length - 1] & 0xf;
  const binary = ((hmac[offset] & 0x7f) << 24) |
                 ((hmac[offset + 1] & 0xff) << 16) |
                 ((hmac[offset + 2] & 0xff) << 8) |
                 (hmac[offset + 3] & 0xff);
  const otp = binary % Math.pow(10, digits);
  return otp.toString().padStart(digits, '0');
}

/**
 * Build the safe header object to forward to Groww.
 * Only passes headers that Groww cares about — never logs Authorization.
 */
function buildGrowwHeaders(reqHeaders) {
  const headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  const auth = reqHeaders['authorization'] || reqHeaders['Authorization'];
  if (auth) headers['Authorization'] = auth;

  const version = reqHeaders['x-api-version'] || reqHeaders['X-API-VERSION'];
  if (version) headers['X-API-VERSION'] = version;

  return headers;
}

/**
 * Low-level HTTP forwarder to Groww API with full metric logging.
 */
async function callGroww(method, path, reqHeaders, data, params) {
  const url     = `${config.growwBaseUrl}${path}`;
  const headers = buildGrowwHeaders(reqHeaders);
  const start   = Date.now();

  console.log(`[GROWW REQ] ${method} ${path}`);

  try {
    const response = await axios({
      method,
      url,
      headers,
      data,
      params,
      timeout: config.requestTimeoutMs,
      httpAgent,
      httpsAgent,
      validateStatus: () => true, // Don't throw on HTTP error status codes
    });

    const duration = Date.now() - start;
    console.log(`[GROWW RES] ${method} ${path} → ${response.status} (${duration}ms)`);

    return {
      status: response.status,
      data: response.data,
      headers: {
        'content-type': response.headers['content-type'],
      },
    };
  } catch (err) {
    const duration = Date.now() - start;
    console.error(`[GROWW ERR] ${method} ${path} failed after ${duration}ms: ${err.message}`);
    throw Object.assign(new Error(`Groww API network error: ${err.message}`), {
      statusCode: 502,
    });
  }
}

// ─── Token ────────────────────────────────────────────────────────────────────

/**
 * Custom Groww Token Access Endpoint.
 *
 * Accepts { totp_token, totp_secret } from Flutter.
 * - totp_token  → Sent in Authorization header as "Bearer <totp_token>"
 * - totp_secret → Base32 TOTP Secret string used to generate 6-digit TOTP
 */
async function generateAccessToken(reqHeaders, reqBody) {
  // Support both passing (reqHeaders, reqBody) or single object ({ totp_token, totp_secret })
  const body = reqBody || reqHeaders || {};
  const totp_token = body.totp_token || body.totpToken;
  const totp_secret = body.totp_secret || body.totpSecret;

  if (!totp_token) {
    throw Object.assign(new Error('totp_token is required'), { statusCode: 400 });
  }
  if (!totp_secret) {
    throw Object.assign(new Error('totp_secret is required'), { statusCode: 400 });
  }

  const tokenStr = String(totp_token).trim();
  const secret   = String(totp_secret).trim();

  const growwUrl = `${config.growwBaseUrl}/v1/token/api/access`;
  const headers  = {
    'Authorization': tokenStr.startsWith('Bearer ') ? tokenStr : `Bearer ${tokenStr}`,
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  const start = Date.now();

  // ── Attempt 1: key_type = "totp" ────────────────────────────────────
  console.log('[GROWW TOKEN] Generating 6-digit TOTP internally...');
  let totpCode;
  try {
    totpCode = generateTOTP(secret);
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

  return {
    status: response.status,
    data: response.data,
  };
}

// ─── Orders ───────────────────────────────────────────────────────────────────

async function createOrder(headers, body) {
  return callGroww('POST', '/v1/order/create', headers, body);
}

async function getOrders(headers, params) {
  return callGroww('GET', '/v1/orders', headers, undefined, params);
}

async function getOrderById(headers, orderId, params) {
  if (!orderId) {
    throw Object.assign(new Error('groww_order_id is required'), { statusCode: 400 });
  }
  return callGroww('GET', `/v1/order/detail/${encodeURIComponent(orderId)}`, headers, undefined, params);
}

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

async function getHoldings(headers) {
  return callGroww('GET', '/v1/holdings', headers);
}

async function getPositions(headers) {
  return callGroww('GET', '/v1/positions', headers);
}

// ─── User ─────────────────────────────────────────────────────────────────────

async function getUserDetails(headers) {
  return callGroww('GET', '/v1/user/detail', headers);
}

module.exports = {
  callGroww,
  generateAccessToken,
  createOrder,
  getOrders,
  getOrderById,
  cancelOrder,
  getHoldings,
  getPositions,
  getUserDetails,
};

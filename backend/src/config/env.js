'use strict';

require('dotenv').config();

const config = {
  port: parseInt(process.env.PORT || '3000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  growwBaseUrl: (process.env.GROWW_BASE_URL || 'https://api.groww.in').replace(/\/+$/, ''),
  requestTimeoutMs: parseInt(process.env.REQUEST_TIMEOUT_MS || '12000', 10),
};

module.exports = config;

'use strict';

const express = require('express');
const helmet  = require('helmet');
const cors    = require('cors');
const { inject } = require('@vercel/analytics');

const healthRoutes = require('./routes/health.routes');
const growwRoutes  = require('./routes/groww.routes');
const errorMiddleware = require('./middleware/error.middleware');

const app = express();

// ─── Security & Parsing ───────────────────────────────────────────────────────
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: false, limit: '1mb' }));

// Root route so Vercel test doesn't 404 / 500
app.get('/', (_req, res) => {
  res.json({
    success: true,
    message: 'Groww Bridge Backend API is running live on Vercel 🚀',
    endpoints: {
      health: '/v1/health',
      tokenAccess: '/v1/token/api/access',
      createOrder: '/v1/order/create',
      orders: '/v1/orders'
    }
  });
});

// ─── Routes ───────────────────────────────────────────────────────────────────
app.use('/v1', healthRoutes);
app.use('/v1', growwRoutes);

// ─── 404 ──────────────────────────────────────────────────────────────────────
app.use((_req, res) => {
  res.status(404).json({ success: false, error: 'Not found' });
});

// ─── Error Handler ────────────────────────────────────────────────────────────
app.use(errorMiddleware);

// ─── Vercel Analytics ─────────────────────────────────────────────────────────
inject();

module.exports = app;

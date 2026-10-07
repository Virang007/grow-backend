'use strict';

const { Router } = require('express');
const ctrl = require('../controllers/groww.controller');

const router = Router();

// ─── Diagnostic ───────────────────────────────────────────────────────────────
router.get('/my-ip', ctrl.getMyIp);

// ─── Groww Token ──────────────────────────────────────────────────────────────
router.post('/token/api/access', ctrl.generateAccessToken);

// ─── Groww Orders ─────────────────────────────────────────────────────────────
router.post('/order/create', ctrl.createOrder);
router.get('/orders', ctrl.getOrders);
router.get('/order/detail/:groww_order_id', ctrl.getOrderById);
router.post('/order/cancel', ctrl.cancelOrder);

// ─── Groww Portfolio ──────────────────────────────────────────────────────────
router.get('/holdings', ctrl.getHoldings);
router.get('/positions', ctrl.getPositions);

// ─── Groww User ───────────────────────────────────────────────────────────────
router.get('/user/detail', ctrl.getUserDetails);

module.exports = router;


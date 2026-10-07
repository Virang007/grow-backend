'use strict';

const { Router } = require('express');
const router = Router();

router.get('/health', (_req, res) => {
  res.status(200).json({ success: true, message: 'Backend is running' });
});

module.exports = router;

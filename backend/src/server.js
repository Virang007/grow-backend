'use strict';

const app    = require('./app');
const config = require('./config/env');

const server = app.listen(config.port, '0.0.0.0', () => {
  console.log('==================================================');
  console.log(`🚀  Groww Bridge Backend`);
  console.log(`📡  Port       : ${config.port}`);
  console.log(`🌐  Mode       : ${config.nodeEnv}`);
  console.log(`🔗  Groww URL  : ${config.growwBaseUrl}`);
  console.log('==================================================');
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('[SERVER] SIGTERM received. Shutting down gracefully...');
  server.close(() => process.exit(0));
});

process.on('SIGINT', () => {
  console.log('[SERVER] SIGINT received. Shutting down gracefully...');
  server.close(() => process.exit(0));
});

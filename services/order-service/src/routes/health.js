const express = require('express');
const pool = require('../db');

const router = express.Router();

router.get('/live', (req, res) => {
  res.json({ status: 'ok', service: 'order-service' });
});

router.get('/ready', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ready', database: 'connected' });
  } catch {
    res.status(503).json({ status: 'not ready', database: 'disconnected' });
  }
});

module.exports = router;

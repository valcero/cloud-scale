const express = require('express');
const pool = require('../db');
const logger = require('../logger');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

router.post('/', authenticate, async (req, res) => {
  try {
    const { items, total } = req.body;
    if (!items || !total) {
      return res.status(400).json({ error: 'Items and total required' });
    }

    const result = await pool.query(
      'INSERT INTO orders (user_id, items, total) VALUES ($1, $2, $3) RETURNING *',
      [req.user.id, JSON.stringify(items), total]
    );

    logger.info('Order created', { orderId: result.rows[0].id, userId: req.user.id });
    res.status(201).json(result.rows[0]);
  } catch (err) {
    logger.error('Order creation failed', { error: err.message });
    res.status(500).json({ error: 'Failed to create order' });
  }
});

router.get('/', authenticate, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM orders WHERE user_id = $1 ORDER BY created_at DESC',
      [req.user.id]
    );
    res.json(result.rows);
  } catch (err) {
    logger.error('Failed to fetch orders', { error: err.message });
    res.status(500).json({ error: 'Failed to fetch orders' });
  }
});

router.get('/:id', authenticate, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM orders WHERE id = $1 AND user_id = $2',
      [req.params.id, req.user.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    logger.error('Failed to fetch order', { error: err.message });
    res.status(500).json({ error: 'Failed to fetch order' });
  }
});

router.patch('/:id/status', authenticate, async (req, res) => {
  try {
    const { status } = req.body;
    const validStatuses = ['pending', 'confirmed', 'processing', 'shipped', 'delivered', 'cancelled'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({ error: `Status must be one of: ${validStatuses.join(', ')}` });
    }

    const result = await pool.query(
      'UPDATE orders SET status = $1, updated_at = NOW() WHERE id = $2 AND user_id = $3 RETURNING *',
      [status, req.params.id, req.user.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }

    logger.info('Order status updated', { orderId: req.params.id, status });
    res.json(result.rows[0]);
  } catch (err) {
    logger.error('Failed to update order', { error: err.message });
    res.status(500).json({ error: 'Failed to update order' });
  }
});

module.exports = router;

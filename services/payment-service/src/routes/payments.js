const express = require('express');
const pool = require('../db');
const logger = require('../logger');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

router.post('/', authenticate, async (req, res) => {
  try {
    const { order_id, amount, currency, payment_method } = req.body;
    if (!order_id || !amount) {
      return res.status(400).json({ error: 'Order ID and amount required' });
    }

    const result = await pool.query(
      `INSERT INTO transactions (order_id, user_id, amount, currency, payment_method, status)
       VALUES ($1, $2, $3, $4, $5, 'processing') RETURNING *`,
      [order_id, req.user.id, amount, currency || 'USD', payment_method || 'card']
    );

    const transaction = result.rows[0];

    // Simulate payment processing
    setTimeout(async () => {
      try {
        await pool.query(
          'UPDATE transactions SET status = $1, updated_at = NOW() WHERE id = $2',
          ['completed', transaction.id]
        );
        logger.info('Payment completed', { transactionId: transaction.id });
      } catch (err) {
        logger.error('Payment processing failed', { error: err.message });
      }
    }, 2000);

    logger.info('Payment initiated', { transactionId: transaction.id, orderId: order_id });
    res.status(201).json(transaction);
  } catch (err) {
    logger.error('Payment creation failed', { error: err.message });
    res.status(500).json({ error: 'Payment processing failed' });
  }
});

router.get('/:id', authenticate, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM transactions WHERE id = $1 AND user_id = $2',
      [req.params.id, req.user.id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Transaction not found' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    logger.error('Failed to fetch transaction', { error: err.message });
    res.status(500).json({ error: 'Failed to fetch transaction' });
  }
});

router.get('/order/:orderId', authenticate, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT * FROM transactions WHERE order_id = $1 AND user_id = $2',
      [req.params.orderId, req.user.id]
    );
    res.json(result.rows);
  } catch (err) {
    logger.error('Failed to fetch transactions', { error: err.message });
    res.status(500).json({ error: 'Failed to fetch transactions' });
  }
});

module.exports = router;

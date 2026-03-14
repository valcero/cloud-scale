const express = require('express');
const pool = require('../db');
const { publishEvent } = require('../kinesis');
const logger = require('../logger');
const { authenticate } = require('../middleware/auth');

const router = express.Router();

router.post('/', authenticate, async (req, res) => {
  try {
    const { event_type, source, payload } = req.body;
    if (!event_type || !source || !payload) {
      return res.status(400).json({ error: 'event_type, source, and payload required' });
    }

    const result = await pool.query(
      'INSERT INTO events (event_type, source, user_id, payload) VALUES ($1, $2, $3, $4) RETURNING *',
      [event_type, source, req.user.id, JSON.stringify(payload)]
    );

    const event = result.rows[0];

    // Async publish to Kinesis for data pipeline processing
    publishEvent({
      ...event,
      timestamp: new Date().toISOString(),
    }).catch(err => logger.error('Kinesis publish failed', { error: err.message }));

    logger.info('Event ingested', { eventId: event.id, type: event_type });
    res.status(201).json(event);
  } catch (err) {
    logger.error('Event ingestion failed', { error: err.message });
    res.status(500).json({ error: 'Failed to ingest event' });
  }
});

router.post('/batch', authenticate, async (req, res) => {
  try {
    const { events } = req.body;
    if (!Array.isArray(events) || events.length === 0) {
      return res.status(400).json({ error: 'Events array required' });
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const results = [];
      for (const evt of events) {
        const result = await client.query(
          'INSERT INTO events (event_type, source, user_id, payload) VALUES ($1, $2, $3, $4) RETURNING *',
          [evt.event_type, evt.source, req.user.id, JSON.stringify(evt.payload)]
        );
        results.push(result.rows[0]);
      }
      await client.query('COMMIT');

      // Async publish batch to Kinesis
      for (const event of results) {
        publishEvent({ ...event, timestamp: new Date().toISOString() })
          .catch(err => logger.error('Kinesis batch publish failed', { error: err.message }));
      }

      logger.info('Batch events ingested', { count: results.length });
      res.status(201).json({ ingested: results.length, events: results });
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  } catch (err) {
    logger.error('Batch ingestion failed', { error: err.message });
    res.status(500).json({ error: 'Failed to ingest events' });
  }
});

router.get('/stats', authenticate, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        event_type,
        source,
        COUNT(*) as count,
        MIN(created_at) as first_event,
        MAX(created_at) as last_event
      FROM events
      WHERE created_at > NOW() - INTERVAL '24 hours'
      GROUP BY event_type, source
      ORDER BY count DESC
    `);
    res.json({ period: '24h', stats: result.rows });
  } catch (err) {
    logger.error('Failed to fetch stats', { error: err.message });
    res.status(500).json({ error: 'Failed to fetch stats' });
  }
});

module.exports = router;

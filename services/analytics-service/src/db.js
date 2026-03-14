const { Pool } = require('pg');
const logger = require('./logger');

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME || 'cloudscale',
  user: process.env.DB_USER || 'cloudscale_admin',
  password: process.env.DB_PASSWORD,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
});

pool.on('error', (err) => {
  logger.error('Unexpected database error', { error: err.message });
});

const initDb = async () => {
  const client = await pool.connect();
  try {
    await client.query(`
      CREATE TABLE IF NOT EXISTS events (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        event_type VARCHAR(100) NOT NULL,
        source VARCHAR(100) NOT NULL,
        user_id INTEGER,
        payload JSONB NOT NULL,
        created_at TIMESTAMP DEFAULT NOW()
      );
      CREATE INDEX IF NOT EXISTS idx_events_type ON events(event_type);
      CREATE INDEX IF NOT EXISTS idx_events_source ON events(source);
      CREATE INDEX IF NOT EXISTS idx_events_created_at ON events(created_at);
    `);
    logger.info('Database initialized');
  } finally {
    client.release();
  }
};

initDb().catch(err => logger.error('DB init failed', { error: err.message }));

module.exports = pool;

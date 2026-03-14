const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const rateLimit = require('express-rate-limit');
const { register, collectDefaultMetrics } = require('prom-client');
const logger = require('./logger');
const authRoutes = require('./routes/auth');
const healthRoutes = require('./routes/health');

collectDefaultMetrics();

const app = express();
const PORT = process.env.PORT || 3001;

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10kb' }));
app.use(rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
}));

app.use('/health', healthRoutes);
app.use('/api/auth', authRoutes);

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

app.use((err, req, res, _next) => {
  logger.error('Unhandled error', { error: err.message, stack: err.stack });
  res.status(500).json({ error: 'Internal server error' });
});

app.listen(PORT, () => {
  logger.info(`Auth service running on port ${PORT}`);
});

module.exports = app;

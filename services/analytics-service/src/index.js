const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const { register, collectDefaultMetrics } = require('prom-client');
const logger = require('./logger');
const eventRoutes = require('./routes/events');
const healthRoutes = require('./routes/health');

collectDefaultMetrics();

const app = express();
const PORT = process.env.PORT || 3004;

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '50kb' }));

app.use('/health', healthRoutes);
app.use('/api/events', eventRoutes);

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

app.use((err, req, res, _next) => {
  logger.error('Unhandled error', { error: err.message, stack: err.stack });
  res.status(500).json({ error: 'Internal server error' });
});

app.listen(PORT, () => {
  logger.info(`Analytics service running on port ${PORT}`);
});

module.exports = app;

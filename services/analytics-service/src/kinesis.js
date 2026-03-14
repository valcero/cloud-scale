const { KinesisClient, PutRecordCommand } = require('@aws-sdk/client-kinesis');
const logger = require('./logger');

const kinesisConfig = {
  region: process.env.AWS_REGION || 'us-east-1',
};

// Use LocalStack endpoint for local development (free AWS emulation)
if (process.env.KINESIS_ENDPOINT) {
  kinesisConfig.endpoint = process.env.KINESIS_ENDPOINT;
  kinesisConfig.credentials = {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID || 'test',
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || 'test',
  };
}

const kinesis = new KinesisClient(kinesisConfig);
const STREAM_NAME = process.env.KINESIS_STREAM_NAME || 'cloudscale-events';

const publishEvent = async (event) => {
  try {
    const command = new PutRecordCommand({
      StreamName: STREAM_NAME,
      Data: Buffer.from(JSON.stringify(event)),
      PartitionKey: event.event_type || 'default',
    });

    const response = await kinesis.send(command);
    logger.info('Event published to Kinesis', {
      sequenceNumber: response.SequenceNumber,
      shardId: response.ShardId,
    });
    return response;
  } catch (err) {
    logger.error('Failed to publish event to Kinesis', { error: err.message });
    throw err;
  }
};

module.exports = { publishEvent };

const { KinesisClient, PutRecordCommand } = require('@aws-sdk/client-kinesis');
const logger = require('./logger');

const kinesis = new KinesisClient({
  region: process.env.AWS_REGION || 'us-east-1',
});

const STREAM_NAME = process.env.KINESIS_STREAM_NAME || 'cloudscale-events-production';

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

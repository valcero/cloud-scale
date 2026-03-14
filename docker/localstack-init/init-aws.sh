#!/bin/bash
echo "Initializing LocalStack AWS resources..."

# Create Kinesis stream
awslocal kinesis create-stream \
  --stream-name cloudscale-events \
  --shard-count 1

# Create S3 data lake bucket
awslocal s3 mb s3://cloudscale-data-lake

# Create S3 athena results bucket
awslocal s3 mb s3://cloudscale-athena-results

echo "LocalStack initialization complete!"
echo "  - Kinesis stream: cloudscale-events"
echo "  - S3 bucket: cloudscale-data-lake"
echo "  - S3 bucket: cloudscale-athena-results"

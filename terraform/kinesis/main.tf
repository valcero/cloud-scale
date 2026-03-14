resource "aws_kinesis_stream" "events" {
  name             = "${var.project_name}-events-${var.environment}"
  shard_count      = 2
  retention_period = 72

  shard_level_metrics = [
    "IncomingBytes",
    "IncomingRecords",
    "OutgoingBytes",
    "OutgoingRecords",
    "ReadProvisionedThroughputExceeded",
    "WriteProvisionedThroughputExceeded",
    "IteratorAgeMilliseconds",
  ]

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }

  tags = {
    Name = "${var.project_name}-events-stream"
  }
}

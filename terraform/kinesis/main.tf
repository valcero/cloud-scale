resource "aws_kinesis_stream" "events" {
  name             = "${var.project_name}-events-${var.environment}"
  shard_count      = 1
  retention_period = 24

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }

  tags = {
    Name = "${var.project_name}-events-stream"
  }
}

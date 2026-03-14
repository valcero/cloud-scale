output "data_lake_bucket" {
  value = aws_s3_bucket.data_lake.id
}

output "data_lake_bucket_arn" {
  value = aws_s3_bucket.data_lake.arn
}

output "athena_results_bucket" {
  value = aws_s3_bucket.athena_results.id
}

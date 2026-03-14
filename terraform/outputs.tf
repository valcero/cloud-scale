output "kinesis_stream_name" {
  description = "Kinesis data stream name"
  value       = module.kinesis.stream_name
}

output "s3_data_lake_bucket" {
  description = "S3 data lake bucket name"
  value       = module.s3.data_lake_bucket
}

output "s3_athena_results_bucket" {
  description = "S3 Athena results bucket name"
  value       = module.s3.athena_results_bucket
}

# ─── Reference outputs (for production deployment) ──────
# These would be active if using the VPC/EKS/RDS modules:
#
# output "vpc_id" {
#   value = module.vpc.vpc_id
# }
# output "eks_cluster_endpoint" {
#   value = module.eks.cluster_endpoint
# }
# output "rds_endpoint" {
#   value     = module.rds.db_endpoint
#   sensitive = true
# }
# output "ecr_repository_urls" {
#   value = module.ecr.repository_urls
# }

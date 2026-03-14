output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "eks_cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = module.rds.db_endpoint
  sensitive   = true
}

output "ecr_repository_urls" {
  description = "ECR repository URLs for each service"
  value       = module.ecr.repository_urls
}

output "kinesis_stream_name" {
  description = "Kinesis data stream name"
  value       = module.kinesis.stream_name
}

output "s3_data_lake_bucket" {
  description = "S3 data lake bucket name"
  value       = module.s3.data_lake_bucket
}

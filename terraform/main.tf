# ─── S3 Buckets (runs on LocalStack - FREE) ─────────────
module "s3" {
  source = "./s3"

  project_name = var.project_name
  environment  = var.environment
}

# ─── Kinesis Stream (runs on LocalStack - FREE) ─────────
module "kinesis" {
  source = "./kinesis"

  project_name = var.project_name
  environment  = var.environment
}

# ─── NOTE: VPC, EKS, RDS, ECR ───────────────────────────
# These modules are kept for reference and portfolio
# demonstration. In this local setup they are not applied
# because we use:
#   - Docker Compose instead of EKS
#   - PostgreSQL container instead of RDS
#   - Local Docker images instead of ECR
#   - Docker networking instead of VPC
#
# To showcase IaC knowledge, the full Terraform modules
# remain in their respective folders:
#   terraform/vpc/   - VPC, subnets, NAT, IGW, NACLs
#   terraform/eks/   - EKS cluster, node groups, OIDC
#   terraform/rds/   - Aurora PostgreSQL cluster
#   terraform/ecr/   - ECR repositories with lifecycle

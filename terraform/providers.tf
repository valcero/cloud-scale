terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.30"
    }
  }

  # Local backend - no paid S3/DynamoDB needed
  backend "local" {
    path = "terraform.tfstate"
  }
}

# LocalStack provider - free local AWS emulation
# Run: docker-compose up localstack  (from docker/ folder)
# Then: terraform init && terraform apply
provider "aws" {
  region                      = var.aws_region
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3       = "http://localhost:4566"
    kinesis  = "http://localhost:4566"
    lambda   = "http://localhost:4566"
    iam      = "http://localhost:4566"
    sts      = "http://localhost:4566"
    ec2      = "http://localhost:4566"
    eks      = "http://localhost:4566"
    rds      = "http://localhost:4566"
    ecr      = "http://localhost:4566"
  }

  default_tags {
    tags = {
      Project     = "CloudScale"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

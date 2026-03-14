terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.30"
    }
  }

  backend "s3" {
    bucket         = "cloudscale-terraform-state"
    key            = "global/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "cloudscale-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "CloudScale"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

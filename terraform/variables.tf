variable "aws_region" {
  description = "AWS region (LocalStack uses us-east-1)"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "local"
  validation {
    condition     = contains(["local", "development", "staging", "production"], var.environment)
    error_message = "Environment must be local, development, staging, or production."
  }
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "cloudscale"
}

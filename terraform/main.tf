module "vpc" {
  source = "./vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
}

module "ecr" {
  source = "./ecr"

  project_name = var.project_name
  environment  = var.environment
}

module "eks" {
  source = "./eks"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  depends_on = [module.vpc]
}

module "rds" {
  source = "./rds"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  db_username        = var.db_username
  db_password        = var.db_password

  depends_on = [module.vpc]
}

module "s3" {
  source = "./s3"

  project_name = var.project_name
  environment  = var.environment
}

module "kinesis" {
  source = "./kinesis"

  project_name = var.project_name
  environment  = var.environment
}

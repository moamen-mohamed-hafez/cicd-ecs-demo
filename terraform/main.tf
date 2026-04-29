terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
backend "s3" {
  bucket       = "cicd-demo-tfstate-123456789"
  key          = "cicd-demo/terraform.tfstate"
  region       = "us-east-1"
  encrypt      = true
  use_lockfile = true
}
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "cicd-ecs-demo"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

module "networking" {
  source       = "./modules/networking"
  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
  az_count     = var.az_count
}

module "ecr" {
  source       = "./modules/ecr"
  project_name = var.project_name
  environment  = var.environment
}

module "alb" {
  source            = "./modules/alb"
  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  alb_sg_id         = module.networking.alb_sg_id
}

module "iam" {
  source       = "./modules/iam"
  project_name = var.project_name
  environment  = var.environment
  ecr_arn      = module.ecr.repository_arn
}

module "ecs" {
  source               = "./modules/ecs"
  project_name         = var.project_name
  environment          = var.environment
  vpc_id               = module.networking.vpc_id
  private_subnet_ids   = module.networking.private_subnet_ids
  ecs_sg_id            = module.networking.ecs_sg_id
  ecr_image_url        = module.ecr.repository_url
  alb_target_group_arn = module.alb.target_group_arn
  task_execution_role  = module.iam.task_execution_role_arn
  task_role_arn        = module.iam.task_role_arn
  app_port             = var.app_port
  cpu                  = var.ecs_cpu
  memory               = var.ecs_memory
  desired_count        = var.desired_count
}
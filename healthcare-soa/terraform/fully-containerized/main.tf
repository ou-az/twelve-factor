terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "Healthcare-SOA"
      Environment = var.environment
      Terraform   = "true"
      Containerized = "true"
    }
  }
}

# VPC with public and private subnets
module "vpc" {
  source = "../modules/vpc"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
  azs          = var.availability_zones
}

# ECR repositories for all services including databases
module "ecr" {
  source = "./modules/ecr"
  
  project_name = var.project_name
  # Include all services including databases in the ECR repository list
  services     = var.all_services
}

# ECS cluster and task definitions for all services
module "ecs" {
  source = "./modules/ecs"
  
  project_name     = var.project_name
  environment      = var.environment
  vpc_id           = module.vpc.vpc_id
  public_subnets   = module.vpc.public_subnets
  private_subnets  = module.vpc.private_subnets
  ecs_cluster_name = "${var.project_name}-${var.environment}-cluster"
  all_services     = var.all_services
  app_services     = var.app_services
  db_services      = var.db_services
  ecr_repositories = module.ecr.repository_urls
  container_configs = var.container_configs
  efs_creation     = var.efs_creation
  aws_region       = var.aws_region
}

# Service discovery for inter-container communication
module "service_discovery" {
  source = "./modules/service_discovery"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
}

# CloudWatch for monitoring and logging
module "monitoring" {
  source = "./modules/monitoring"
  count  = var.deploy_monitoring ? 1 : 0
  
  project_name    = var.project_name
  environment     = var.environment
  all_services    = var.all_services
  app_services    = var.app_services
  alb_arn_suffix  = module.ecs.alb_arn_suffix
  ecs_cluster_arn = module.ecs.ecs_cluster_arn
  alert_email     = var.alert_email
}

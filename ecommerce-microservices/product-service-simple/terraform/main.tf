terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    # These values would be provided via command line or environment variables
    # bucket = "your-terraform-state-bucket"
    # key    = "product-service/terraform.tfstate"
    # region = "us-east-1"
    # encrypt = true
  }
}

provider "aws" {
  region = var.aws_region
}

# Reference to data and resources from other files
locals {
  environment = var.environment
  name_prefix = "${var.project_name}-${local.environment}"
  common_tags = {
    Environment = local.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Owner       = "DevOps"
  }
}

#########################################
# VPC and Networking
#########################################
module "vpc" {
  source = "./modules/vpc"

  name_prefix        = local.name_prefix
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  private_subnets    = var.private_subnets
  public_subnets     = var.public_subnets
  tags               = local.common_tags
}

#########################################
# Security Groups
#########################################
module "security_groups" {
  source = "./modules/security"
  
  name_prefix     = local.name_prefix
  vpc_id          = module.vpc.vpc_id
  container_port  = var.container_port
  tags            = local.common_tags
}

#########################################
# ECR Repository for Docker Images
#########################################
module "ecr" {
  source = "./modules/ecr"
  
  name_prefix = local.name_prefix
  tags        = local.common_tags
}

#########################################
# Amazon MSK (Managed Streaming for Kafka)
#########################################
module "msk" {
  source = "./modules/msk"
  
  name_prefix            = local.name_prefix
  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = module.vpc.private_subnet_ids
  kafka_version          = var.kafka_version
  broker_instance_type   = var.kafka_broker_instance_type
  number_of_broker_nodes = var.kafka_broker_count
  tags                   = local.common_tags
}

#########################################
# RDS PostgreSQL
#########################################
module "rds" {
  source = "./modules/rds"
  
  name_prefix          = local.name_prefix
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.private_subnet_ids
  engine_version       = var.postgres_version
  instance_class       = var.postgres_instance_class
  allocated_storage    = var.postgres_allocated_storage
  database_name        = var.postgres_database_name
  database_username    = var.postgres_username
  database_password    = var.postgres_password
  security_group_ids   = [module.security_groups.rds_security_group_id]
  tags                 = local.common_tags
}

#########################################
# ECS Fargate Service
#########################################
module "ecs" {
  source = "./modules/ecs"
  
  name_prefix                  = local.name_prefix
  vpc_id                       = module.vpc.vpc_id
  subnet_ids                   = module.vpc.private_subnet_ids
  alb_subnet_ids               = module.vpc.public_subnet_ids
  app_image                    = "${module.ecr.repository_url}:${var.image_tag}"
  container_port               = var.container_port
  cpu                          = var.container_cpu
  memory                       = var.container_memory
  desired_count                = var.desired_count
  ecs_security_group_id        = module.security_groups.ecs_security_group_id
  alb_security_group_id        = module.security_groups.alb_security_group_id
  health_check_path            = var.health_check_path
  
  environment_variables = [
    { name = "SPRING_PROFILES_ACTIVE", value = "aws" },
    { name = "SPRING_DATASOURCE_URL", value = "jdbc:postgresql://${module.rds.endpoint}:5432/${var.postgres_database_name}" },
    { name = "SPRING_DATASOURCE_USERNAME", value = var.postgres_username },
    { name = "SPRING_DATASOURCE_PASSWORD", value = var.postgres_password },
    { name = "SPRING_KAFKA_BOOTSTRAP_SERVERS", value = module.msk.bootstrap_brokers }
  ]
  
  tags = local.common_tags
}

# Outputs
output "alb_dns_name" {
  value       = module.ecs.alb_dns_name
  description = "The DNS name of the load balancer"
}

output "ecr_repository_url" {
  value       = module.ecr.repository_url
  description = "The URL of the ECR repository"
}

output "msk_bootstrap_brokers" {
  value       = module.msk.bootstrap_brokers
  description = "The bootstrap brokers for the MSK cluster"
}

output "rds_endpoint" {
  value       = module.rds.endpoint
  description = "The endpoint of the RDS instance"
}

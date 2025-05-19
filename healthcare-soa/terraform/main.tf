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
    }
  }
}

# Import modules
module "vpc" {
  source = "./modules/vpc"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
  azs          = var.availability_zones
}

module "ecr" {
  source = "./modules/ecr"
  
  project_name = var.project_name
  services     = var.services
}

module "ecs" {
  source = "./modules/ecs"
  count  = var.deploy_ecs ? 1 : 0
  
  project_name     = var.project_name
  environment      = var.environment
  vpc_id           = module.vpc.vpc_id
  public_subnets   = module.vpc.public_subnets
  private_subnets  = module.vpc.private_subnets
  services         = var.services
  ecr_repositories = module.ecr.repository_urls
  container_configs = var.container_configs
  aws_region       = var.aws_region
}

module "monitoring" {
  source = "./modules/monitoring"
  count  = var.deploy_monitoring ? 1 : 0
  
  project_name = var.project_name
  environment  = var.environment
  services     = var.services
  endpoints    = try(module.ecs.service_endpoints, {})
  alb_arn_suffix = try(module.ecs.alb_dns_name, "")
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "twelve-factor-ecommerce"
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}

# VPC and Network Infrastructure
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "3.14.0"

  name = "dev-ecommerce-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  database_subnets = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_vpn_gateway = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  create_database_subnet_group = true

  tags = {
    Environment = "dev"
  }
}

# S3 Bucket for Logs
resource "aws_s3_bucket" "logs" {
  bucket = "dev-ecommerce-logs-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "dev-ecommerce-logs"
    Environment = "dev"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs_lifecycle" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "log-expiration"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}

# PostgreSQL Database
module "rds" {
  source = "../../modules/rds"

  environment            = "dev"
  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = module.vpc.database_subnets
  client_security_groups = [module.ecs.product_service_sg_id]
  instance_class         = "db.t3.small"
  allocated_storage      = 20
  max_allocated_storage  = 50
  username               = var.db_username
  password               = var.db_password
}

# Kafka Cluster
module "msk" {
  source = "../../modules/msk"

  environment           = "dev"
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.private_subnets
  client_security_groups = [module.ecs.product_service_sg_id]
  broker_count          = 2
  broker_instance_type  = "kafka.t3.small"
  broker_volume_size    = 50
  logs_bucket           = aws_s3_bucket.logs.id
}

# ECR Repository for Docker Images
resource "aws_ecr_repository" "product_service" {
  name                 = "dev-product-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "dev-product-service"
    Environment = "dev"
  }
}

# ECS Cluster and Product Service
module "ecs" {
  source = "../../modules/ecs"

  environment            = "dev"
  cluster_name           = "ecommerce-cluster"
  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = module.vpc.private_subnets
  public_subnet_ids      = module.vpc.public_subnets
  ecr_repository_url     = aws_ecr_repository.product_service.repository_url
  image_tag              = "latest"
  service_desired_count  = 2
  min_capacity           = 2
  max_capacity           = 4
  task_cpu               = 512
  task_memory            = 1024
  secrets_arn            = module.rds.db_credentials_arn
  kafka_bootstrap_servers = module.msk.bootstrap_brokers
  msk_arn                = module.msk.cluster_arn
  logs_bucket            = aws_s3_bucket.logs.id
  certificate_arn        = aws_acm_certificate.product_service.arn
}

# ACM Certificate for HTTPS
resource "aws_acm_certificate" "product_service" {
  domain_name       = "product-service-dev.example.com"
  validation_method = "DNS"

  tags = {
    Name        = "dev-product-service-cert"
    Environment = "dev"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Route53 DNS Record for Product Service
resource "aws_route53_record" "product_service" {
  zone_id = var.route53_zone_id
  name    = "product-service-dev.example.com"
  type    = "A"

  alias {
    name                   = module.ecs.alb_dns_name
    zone_id                = module.ecs.alb_zone_id
    evaluate_target_health = true
  }
}

# AWS CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "product_service" {
  dashboard_name = "dev-product-service-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", "dev-product-service", "ClusterName", "dev-ecommerce-cluster"]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "CPU Utilization"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "MemoryUtilization", "ServiceName", "dev-product-service", "ClusterName", "dev-ecommerce-cluster"]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Memory Utilization"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", module.ecs.alb_arn_suffix]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "Request Count"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", module.ecs.alb_arn_suffix]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Response Time"
        }
      }
    ]
  })
}

# Current AWS Account data
data "aws_caller_identity" "current" {}

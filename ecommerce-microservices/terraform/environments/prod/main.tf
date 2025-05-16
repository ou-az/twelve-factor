provider "aws" {
  region = var.aws_region
}

# VPC for the EKS cluster
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = var.private_subnet_cidrs
  public_subnets  = var.public_subnet_cidrs

  enable_nat_gateway = true
  single_nat_gateway = false
  one_nat_gateway_per_az = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tags required for EKS
  private_subnet_tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"               = "1"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared"
    "kubernetes.io/role/elb"                        = "1"
  }

  tags = var.tags
}

# ECR Repositories for all microservices
module "product_service_ecr" {
  source = "../../modules/ecr"

  repository_name       = "${var.project_name}-product-service"
  enable_lifecycle_policy = true
  max_image_count       = 20
  tags                  = var.tags
}

module "kafka_ecr" {
  source = "../../modules/ecr"

  repository_name       = "${var.project_name}-kafka"
  enable_lifecycle_policy = true
  max_image_count       = 10
  tags                  = var.tags
}

module "zookeeper_ecr" {
  source = "../../modules/ecr"

  repository_name       = "${var.project_name}-zookeeper"
  enable_lifecycle_policy = true
  max_image_count       = 10
  tags                  = var.tags
}

module "kafka_ui_ecr" {
  source = "../../modules/ecr"

  repository_name       = "${var.project_name}-kafka-ui"
  enable_lifecycle_policy = true
  max_image_count       = 10
  tags                  = var.tags
}

# EKS Cluster
module "eks" {
  source = "../../modules/eks"

  cluster_name       = var.eks_cluster_name
  kubernetes_version = var.kubernetes_version
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnets
  
  # Node group configuration
  instance_types     = var.eks_instance_types
  desired_size       = var.eks_desired_size
  min_size           = var.eks_min_size
  max_size           = var.eks_max_size
  disk_size          = var.eks_disk_size
  
  tags               = var.tags
}

# Get EKS cluster authentication information
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

# Configure Kubernetes provider
provider "kubernetes" {
  host                   = module.eks.endpoint
  cluster_ca_certificate = base64decode(module.eks.kubeconfig-certificate-authority-data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Create the ecommerce namespace
resource "kubernetes_namespace" "ecommerce" {
  metadata {
    name = "ecommerce"
    
    labels = {
      environment = var.environment
      project     = var.project_name
    }
  }

  depends_on = [module.eks]
}

# Create ConfigMap for product-service
resource "kubernetes_config_map" "product_service_config" {
  metadata {
    name      = "product-service-config"
    namespace = kubernetes_namespace.ecommerce.metadata.0.name
  }

  data = {
    SPRING_PROFILES_ACTIVE            = "prod"
    SPRING_KAFKA_BOOTSTRAP-SERVERS    = "kafka-service:9092"
    SPRING_KAFKA_ENABLED              = "true"
    SPRING_KAFKA_PRODUCER_CLIENT-ID   = "product-service-producer"
    KAFKA_PRODUCT_CREATED_TOPIC       = "product-created"
    KAFKA_PRODUCT_UPDATED_TOPIC       = "product-updated"
    KAFKA_PRODUCT_DELETED_TOPIC       = "product-deleted"
    KAFKA_INVENTORY_UPDATED_TOPIC     = "inventory-updated"
  }
}

# Create Secrets for product-service
resource "kubernetes_secret" "product_service_secrets" {
  metadata {
    name      = "product-service-secrets"
    namespace = kubernetes_namespace.ecommerce.metadata.0.name
  }

  data = {
    SPRING_DATASOURCE_URL      = "jdbc:postgresql://postgres-service:5432/product_db"
    SPRING_DATASOURCE_USERNAME = "postgres"
    SPRING_DATASOURCE_PASSWORD = var.db_password
  }

  type = "Opaque"
}

# Create StorageClass for AWS EBS
resource "kubernetes_storage_class" "ebs_storage" {
  metadata {
    name = "ebs-sc"
  }

  storage_provisioner = "ebs.csi.aws.com"
  reclaim_policy      = "Retain"
  volume_binding_mode = "WaitForFirstConsumer"
  
  parameters = {
    type = "gp3"
    fsType = "ext4"
  }
}

# Create PVC for PostgreSQL
resource "kubernetes_persistent_volume_claim" "postgres_pvc" {
  metadata {
    name      = "postgres-data"
    namespace = kubernetes_namespace.ecommerce.metadata.0.name
  }
  
  spec {
    access_modes = ["ReadWriteOnce"]
    storage_class_name = kubernetes_storage_class.ebs_storage.metadata.0.name
    
    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
}

# Output the EKS cluster details
output "eks_cluster_endpoint" {
  description = "Endpoint for EKS cluster"
  value       = module.eks.endpoint
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

# ECR Repository URLs for all services
output "product_service_ecr_repository_url" {
  description = "ECR Repository URL for product-service"
  value       = module.product_service_ecr.repository_url
}

output "kafka_ecr_repository_url" {
  description = "ECR Repository URL for Kafka"
  value       = module.kafka_ecr.repository_url
}

output "zookeeper_ecr_repository_url" {
  description = "ECR Repository URL for Zookeeper"
  value       = module.zookeeper_ecr.repository_url
}

output "kafka_ui_ecr_repository_url" {
  description = "ECR Repository URL for Kafka UI"
  value       = module.kafka_ui_ecr.repository_url
}

output "kubernetes_config_command" {
  description = "Command to configure kubectl for EKS cluster"
  value       = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}"
}

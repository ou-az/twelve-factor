variable "aws_region" {
  description = "The AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "product-service"
}

#########################################
# VPC Configuration
#########################################
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "private_subnets" {
  description = "List of private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnets" {
  description = "List of public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

#########################################
# Container Configuration
#########################################
variable "image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "container_port" {
  description = "Port the container exposes"
  type        = number
  default     = 8080
}

variable "container_cpu" {
  description = "CPU units for the container (1 vCPU = 1024 units)"
  type        = number
  default     = 512
}

variable "container_memory" {
  description = "Memory for the container in MiB"
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Desired count of container instances"
  type        = number
  default     = 2
}

variable "health_check_path" {
  description = "Health check path for the ALB target group"
  type        = string
  default     = "/actuator/health"
}

#########################################
# Kafka Configuration
#########################################
variable "kafka_version" {
  description = "Kafka version for MSK cluster"
  type        = string
  default     = "2.8.1"
}

variable "kafka_broker_instance_type" {
  description = "Instance type for Kafka brokers"
  type        = string
  default     = "kafka.t3.small"
}

variable "kafka_broker_count" {
  description = "Number of Kafka broker nodes"
  type        = number
  default     = 2
}

#########################################
# RDS Configuration
#########################################
variable "postgres_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "13.7"
}

variable "postgres_instance_class" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.small"
}

variable "postgres_allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 20
}

variable "postgres_database_name" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "product_db"
}

variable "postgres_username" {
  description = "Username for PostgreSQL"
  type        = string
  default     = "postgres"
  sensitive   = true
}

variable "postgres_password" {
  description = "Password for PostgreSQL"
  type        = string
  sensitive   = true
}

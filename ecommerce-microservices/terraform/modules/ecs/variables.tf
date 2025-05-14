variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "ecommerce-cluster"
}

variable "vpc_id" {
  description = "ID of the VPC where resources will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where the ECS tasks will be deployed"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs where the ALB will be deployed"
  type        = list(string)
}

variable "ecr_repository_url" {
  description = "URL of the ECR repository for the service image"
  type        = string
}

variable "image_tag" {
  description = "Tag of the Docker image to deploy"
  type        = string
}

variable "task_cpu" {
  description = "CPU units for the ECS task"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Memory (MiB) for the ECS task"
  type        = number
  default     = 512
}

variable "service_desired_count" {
  description = "Desired number of tasks for the service"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Minimum number of tasks to run"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum number of tasks to run"
  type        = number
  default     = 10
}

variable "kafka_bootstrap_servers" {
  description = "Comma-separated list of Kafka bootstrap servers"
  type        = string
}

variable "secrets_arn" {
  description = "ARN of the AWS Secrets Manager secret containing the database credentials"
  type        = string
}

variable "msk_arn" {
  description = "ARN of the MSK cluster"
  type        = string
}

variable "aws_region" {
  description = "The AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "logs_bucket" {
  description = "S3 bucket where ALB access logs will be stored"
  type        = string
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate for the ALB"
  type        = string
}

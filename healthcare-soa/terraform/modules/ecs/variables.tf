variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "services" {
  description = "List of services to deploy"
  type        = list(string)
}

variable "ecr_repositories" {
  description = "Map of service names to their ECR repository URLs"
  type        = map(string)
}

variable "container_configs" {
  description = "Configuration for each container service"
  type = map(object({
    cpu                = number
    memory             = number
    container_port     = number
    host_port          = number
    health_check_path  = string
    desired_count      = number
    environment_variables = list(object({
      name  = string
      value = string
    }))
    secrets = list(object({
      name      = string
      valueFrom = string
    }))
  }))
}

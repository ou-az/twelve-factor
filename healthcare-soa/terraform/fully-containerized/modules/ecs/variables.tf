variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
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

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

variable "all_services" {
  description = "List of all services to deploy including databases"
  type        = list(string)
}

variable "app_services" {
  description = "List of application services to deploy"
  type        = list(string)
}

variable "db_services" {
  description = "List of database services to deploy"
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
    host_port          = optional(number)
    health_check_path  = string
    desired_count      = number
    requires_volume    = optional(bool, false)
    volume_name        = optional(string, "")
    volume_mount_path  = optional(string, "")
    service_registry_enabled = optional(bool, true)
    use_fargate        = optional(bool, true)
    essential          = optional(bool, true)
    network_mode       = optional(string, "awsvpc")
    environment_variables = optional(list(object({
      name  = string
      value = string
    })), [])
    secrets = optional(list(object({
      name      = string
      valueFrom = string
    })), [])
  }))
}

variable "efs_creation" {
  description = "Whether to create EFS for persistent storage"
  type        = bool
  default     = true
}

variable "service_discovery_map" {
  description = "Map of services to their service discovery ARNs"
  type        = map(string)
  default     = {}
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

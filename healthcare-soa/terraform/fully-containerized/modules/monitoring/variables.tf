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

variable "all_services" {
  description = "List of all services to monitor"
  type        = list(string)
}

variable "app_services" {
  description = "List of application services"
  type        = list(string)
}

variable "db_services" {
  description = "List of database services"
  type        = list(string)
  default     = ["postgres", "mongodb", "redis"]
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the ALB"
  type        = string
  default     = ""
}

variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = ""
}

variable "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  type        = string
  default     = ""
}

variable "alert_email" {
  description = "Email to send alerts to"
  type        = string
  default     = ""
}

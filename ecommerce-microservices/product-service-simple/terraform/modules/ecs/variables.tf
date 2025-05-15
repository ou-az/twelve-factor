variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ECS tasks"
  type        = list(string)
}

variable "alb_subnet_ids" {
  description = "List of subnet IDs for the ALB"
  type        = list(string)
}

variable "app_image" {
  description = "Docker image for the application"
  type        = string
}

variable "container_port" {
  description = "Port exposed by the container"
  type        = number
  default     = 8080
}

variable "cpu" {
  description = "CPU units for the task (1 vCPU = 1024 units)"
  type        = number
  default     = 512
}

variable "memory" {
  description = "Memory for the task in MiB"
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Desired count of task instances"
  type        = number
  default     = 2
}

variable "min_count" {
  description = "Minimum count of task instances for autoscaling"
  type        = number
  default     = 1
}

variable "max_count" {
  description = "Maximum count of task instances for autoscaling"
  type        = number
  default     = 4
}

variable "health_check_path" {
  description = "Path for health check"
  type        = string
  default     = "/actuator/health"
}

variable "environment_variables" {
  description = "Environment variables for the container"
  type        = list(object({
    name  = string
    value = string
  }))
  default     = []
}

variable "ecs_security_group_id" {
  description = "ID of the security group for the ECS service"
  type        = string
}

variable "alb_security_group_id" {
  description = "ID of the security group for the ALB"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

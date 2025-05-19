variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "healthcare-soa"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "deploy_monitoring" {
  description = "Whether to deploy the monitoring module"
  type        = bool
  default     = false
}

variable "deploy_ecs" {
  description = "Whether to deploy the ECS module"
  type        = bool
  default     = false
}

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

variable "services" {
  description = "List of services to deploy"
  type        = list(string)
  default     = [
    "esb",
    "patient-service",
    "appointment-service"
  ]
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
  
  default = {
    "esb" = {
      cpu               = 512
      memory            = 1024
      container_port    = 8081
      host_port         = 8081
      health_check_path = "/api/health"
      desired_count     = 1
      environment_variables = [
        { name = "MULE_ENV", value = "dev" }
      ]
      secrets = []
    }
    
    "patient-service" = {
      cpu               = 512
      memory            = 1024
      container_port    = 8091
      host_port         = 8091
      health_check_path = "/actuator/health"
      desired_count     = 1
      environment_variables = [
        { name = "SPRING_PROFILES_ACTIVE", value = "prod" },
        { name = "LOGGING_LEVEL_ROOT", value = "INFO" },
        { name = "LOGGING_LEVEL_COM_HEALTHCARE", value = "INFO" }
      ]
      secrets = []
    }
    
    "appointment-service" = {
      cpu               = 512
      memory            = 1024
      container_port    = 8092
      host_port         = 8092
      health_check_path = "/actuator/health"
      desired_count     = 1
      environment_variables = [
        { name = "SPRING_PROFILES_ACTIVE", value = "prod" },
        { name = "LOGGING_LEVEL_ROOT", value = "INFO" },
        { name = "LOGGING_LEVEL_COM_HEALTHCARE", value = "INFO" }
      ]
      secrets = []
    }
  }
}

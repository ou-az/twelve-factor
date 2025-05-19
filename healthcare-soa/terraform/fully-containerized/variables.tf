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

variable "deploy_monitoring" {
  description = "Whether to deploy the monitoring module"
  type        = bool
  default     = true
}

variable "efs_creation" {
  description = "Whether to create EFS for persistent storage"
  type        = bool
  default     = true
}

variable "alert_email" {
  description = "Email to send alerts to"
  type        = string
  default     = ""
}

# Services categorization
variable "all_services" {
  description = "List of all services to deploy including databases"
  type        = list(string)
  default     = [
    "esb",
    "patient-service",
    "appointment-service",
    "postgres",
    "mongodb",
    "redis"
  ]
}

variable "app_services" {
  description = "List of application services to deploy"
  type        = list(string)
  default     = [
    "esb",
    "patient-service",
    "appointment-service"
  ]
}

variable "db_services" {
  description = "List of database services to deploy"
  type        = list(string)
  default     = [
    "postgres",
    "mongodb",
    "redis"
  ]
}

# Container configuration for each service
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
  
  default = {
    "esb" = {
      cpu               = 512
      memory            = 1024
      container_port    = 8081
      health_check_path = "/api/health"
      desired_count     = 1
      use_fargate       = true
      environment_variables = [
        { name = "MULE_ENV", value = "dev" }
      ]
    }
    
    "patient-service" = {
      cpu               = 512
      memory            = 1024
      container_port    = 8091
      health_check_path = "/actuator/health"
      desired_count     = 1
      use_fargate       = true
      environment_variables = [
        { name = "SPRING_PROFILES_ACTIVE", value = "docker" },
        { name = "SPRING_DATASOURCE_URL", value = "jdbc:postgresql://postgres.healthcare-soa.local:5432/healthcare_patient" },
        { name = "SPRING_DATASOURCE_USERNAME", value = "healthcare_user" },
        { name = "SPRING_DATASOURCE_PASSWORD", value = "healthcare_password" },
        { name = "MULE_ESB_URL", value = "http://esb.healthcare-soa.local:8081" },
        { name = "LOGGING_LEVEL_ROOT", value = "INFO" },
        { name = "LOGGING_LEVEL_COM_HEALTHCARE", value = "DEBUG" }
      ]
    }
    
    "appointment-service" = {
      cpu               = 512
      memory            = 1024
      container_port    = 8092
      health_check_path = "/actuator/health"
      desired_count     = 1
      use_fargate       = true
      environment_variables = [
        { name = "SPRING_PROFILES_ACTIVE", value = "docker" },
        { name = "SPRING_DATASOURCE_URL", value = "jdbc:postgresql://postgres.healthcare-soa.local:5432/healthcare_appointment" },
        { name = "SPRING_DATASOURCE_USERNAME", value = "healthcare_user" },
        { name = "SPRING_DATASOURCE_PASSWORD", value = "healthcare_password" },
        { name = "SPRING_DATA_MONGODB_URI", value = "mongodb://mongodb.healthcare-soa.local:27017/healthcare_appointment" },
        { name = "SPRING_REDIS_HOST", value = "redis.healthcare-soa.local" },
        { name = "SPRING_REDIS_PORT", value = "6379" },
        { name = "MULE_ESB_URL", value = "http://esb.healthcare-soa.local:8081" },
        { name = "LOGGING_LEVEL_ROOT", value = "INFO" },
        { name = "LOGGING_LEVEL_COM_HEALTHCARE", value = "DEBUG" }
      ]
    }
    
    "postgres" = {
      cpu               = 512
      memory            = 1024
      container_port    = 5432
      health_check_path = "/"  # Custom health check will be implemented
      desired_count     = 1
      requires_volume   = true
      volume_name       = "postgres-data"
      volume_mount_path = "/var/lib/postgresql/data"
      use_fargate       = false  # Use EC2 for better performance
      environment_variables = [
        { name = "POSTGRES_USER", value = "postgres" },
        { name = "POSTGRES_PASSWORD", value = "postgres" },
        { name = "POSTGRES_DB", value = "postgres" },
        { name = "POSTGRES_MULTIPLE_DATABASES", value = "healthcare_patient,healthcare_appointment" }
      ]
    }
    
    "mongodb" = {
      cpu               = 512
      memory            = 1024
      container_port    = 27017
      health_check_path = "/"  # Custom health check will be implemented
      desired_count     = 1
      requires_volume   = true
      volume_name       = "mongodb-data"
      volume_mount_path = "/data/db"
      use_fargate       = false  # Use EC2 for better performance
    }
    
    "redis" = {
      cpu               = 256
      memory            = 512
      container_port    = 6379
      health_check_path = "/"  # Custom health check will be implemented
      desired_count     = 1
      requires_volume   = true
      volume_name       = "redis-data"
      volume_mount_path = "/data"
      use_fargate       = true
    }
  }
}

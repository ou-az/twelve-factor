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

variable "services" {
  description = "List of services to create service discovery entries for"
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

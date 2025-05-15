variable "aws_region" {
  description = "The AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "product-service-dev"
}

variable "instance_class" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Allocated storage for RDS in GB"
  type        = number
  default     = 20
}

variable "database_name" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "product_db"
}

variable "database_username" {
  description = "Username for PostgreSQL"
  type        = string
  default     = "postgres"
}

variable "database_password" {
  description = "Password for PostgreSQL"
  type        = string
  default     = "postgres123"  # Change this in production
  sensitive   = true
}

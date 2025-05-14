variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the RDS instance will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where the RDS instance will be deployed"
  type        = list(string)
}

variable "client_security_groups" {
  description = "List of security group IDs for clients that need to connect to the database"
  type        = list(string)
}

variable "instance_class" {
  description = "Instance class for the RDS instance"
  type        = string
  default     = "db.t3.small"
}

variable "allocated_storage" {
  description = "The allocated storage in gibibytes"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "The upper limit to which Amazon RDS can automatically scale the storage"
  type        = number
  default     = 100
}

variable "username" {
  description = "Username for the master DB user"
  type        = string
  sensitive   = true
  default     = "admin"
}

variable "password" {
  description = "Password for the master DB user"
  type        = string
  sensitive   = true
}

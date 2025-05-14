variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "db_username" {
  description = "Username for the database"
  type        = string
  sensitive   = true
  default     = "admin"
}

variable "db_password" {
  description = "Password for the database"
  type        = string
  sensitive   = true
}

variable "route53_zone_id" {
  description = "ID of the Route53 hosted zone"
  type        = string
}

variable "alert_email" {
  description = "Email address for CloudWatch alarms"
  type        = string
  default     = "admin@example.com"
}

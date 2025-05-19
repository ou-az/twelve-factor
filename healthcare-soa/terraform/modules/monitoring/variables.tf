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

variable "services" {
  description = "List of services to monitor"
  type        = list(string)
}

variable "endpoints" {
  description = "Map of service names to their endpoints"
  type        = map(string)
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the ALB"
  type        = string
  default     = ""
}

variable "alert_email" {
  description = "Email to send alerts to"
  type        = string
  default     = ""
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the MSK cluster will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where the MSK brokers will be deployed"
  type        = list(string)
}

variable "kafka_version" {
  description = "Version of Kafka to use for the MSK cluster"
  type        = string
  default     = "2.8.1"
}

variable "broker_count" {
  description = "Number of broker nodes in the MSK cluster"
  type        = number
  default     = 3
}

variable "broker_instance_type" {
  description = "Instance type for the Kafka brokers"
  type        = string
  default     = "kafka.t3.small"
}

variable "broker_volume_size" {
  description = "Size in GiB of the EBS volume for the broker node"
  type        = number
  default     = 100
}

variable "client_security_groups" {
  description = "List of security group IDs for clients that need to connect to Kafka"
  type        = list(string)
}

variable "logs_bucket" {
  description = "S3 bucket where MSK logs will be stored"
  type        = string
}

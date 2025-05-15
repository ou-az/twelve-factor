variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the MSK cluster"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for the MSK cluster"
  type        = list(string)
  default     = null
}

variable "kafka_version" {
  description = "Kafka version for MSK cluster"
  type        = string
  default     = "2.8.1"
}

variable "broker_instance_type" {
  description = "Instance type for Kafka brokers"
  type        = string
  default     = "kafka.t3.small"
}

variable "number_of_broker_nodes" {
  description = "Number of Kafka broker nodes"
  type        = number
  default     = 2
}

variable "broker_volume_size" {
  description = "Size in GiB of the EBS volume for the Kafka broker"
  type        = number
  default     = 20
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

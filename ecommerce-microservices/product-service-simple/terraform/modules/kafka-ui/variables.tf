variable "name_prefix" {
  description = "Prefix used for resource naming"
  type        = string
}

variable "ecs_cluster_id" {
  description = "ID of the ECS cluster to deploy to"
  type        = string
}

variable "execution_role_arn" {
  description = "ARN of the execution role for Kafka-UI"
  type        = string
}

variable "task_role_arn" {
  description = "ARN of the task role for Kafka-UI"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "subnet_ids" {
  description = "IDs of the subnets where the Kafka-UI task will run"
  type        = list(string)
}

variable "alb_subnet_ids" {
  description = "IDs of the subnets for the ALB"
  type        = list(string)
}

variable "security_group_id" {
  description = "ID of the security group for Kafka-UI task"
  type        = string
}

variable "alb_security_group_id" {
  description = "ID of the security group for the ALB"
  type        = string
}

variable "msk_security_group_id" {
  description = "ID of the MSK security group"
  type        = string
}

variable "kafka_bootstrap_servers" {
  description = "Bootstrap servers connection string for Kafka"
  type        = string
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
  description = "Desired task count"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

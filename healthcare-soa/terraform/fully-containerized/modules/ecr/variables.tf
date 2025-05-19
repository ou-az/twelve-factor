variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "services" {
  description = "List of services to create ECR repositories for"
  type        = list(string)
}

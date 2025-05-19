output "repository_urls" {
  description = "Map of service names to their ECR repository URLs"
  value = {
    for key, repo in aws_ecr_repository.repository : key => repo.repository_url
  }
}

output "repository_arns" {
  description = "Map of service names to their ECR repository ARNs"
  value = {
    for key, repo in aws_ecr_repository.repository : key => repo.arn
  }
}

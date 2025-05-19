output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "app_service_names" {
  description = "Names of the application ECS services"
  value       = { for name, service in aws_ecs_service.app_service : name => service.name }
}

output "db_service_names" {
  description = "Names of the database ECS services"
  value       = { for name, service in aws_ecs_service.db_service : name => service.name }
}

output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "alb_arn_suffix" {
  description = "ARN suffix of the ALB"
  value       = aws_lb.main.arn_suffix
}

output "app_service_urls" {
  description = "URLs for accessing the application services"
  value = {
    for name in var.app_services : name => "http://${aws_lb.main.dns_name}/${name}"
  }
}

output "task_definitions" {
  description = "ARNs of the ECS task definitions"
  value = {
    for name, task_def in aws_ecs_task_definition.service : name => task_def.arn
  }
}

output "efs_id" {
  description = "ID of the EFS file system (if created)"
  value       = var.efs_creation ? aws_efs_file_system.ecs_storage[0].id : null
}

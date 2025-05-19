output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "service_names" {
  description = "Names of the ECS services"
  value       = { for name, service in aws_ecs_service.service : name => service.name }
}

output "service_endpoints" {
  description = "URLs for accessing the services"
  value = {
    for name in var.services : name => "${aws_lb.main.dns_name}/${name}"
  }
}

output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "postgres_endpoint" {
  description = "Endpoint of the PostgreSQL database"
  value       = aws_db_instance.postgres.endpoint
}

output "redis_endpoint" {
  description = "Endpoint of the Redis ElastiCache cluster"
  value       = aws_elasticache_cluster.redis.cache_nodes.0.address
}

output "mongodb_endpoint" {
  description = "Private IP address of the MongoDB instance"
  value       = "${aws_instance.mongodb.private_ip}:27017"
}

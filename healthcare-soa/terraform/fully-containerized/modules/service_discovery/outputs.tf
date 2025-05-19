output "namespace_id" {
  description = "ID of the service discovery namespace"
  value       = aws_service_discovery_private_dns_namespace.main.id
}

output "namespace_name" {
  description = "Name of the service discovery namespace"
  value       = aws_service_discovery_private_dns_namespace.main.name
}

output "service_discovery_map" {
  description = "Map of services to their service discovery ARNs"
  value = {
    for key, service in aws_service_discovery_service.service : key => service.arn
  }
}

output "service_discovery_ids" {
  description = "Map of services to their service discovery IDs"
  value = {
    for key, service in aws_service_discovery_service.service : key => service.id
  }
}
